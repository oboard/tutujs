const fs = require("fs")
const path = require("path")
const http = require("http")
const { spawn } = require("child_process")
const sqlite3 = require("sqlite3").verbose()

const rootDir = path.resolve(__dirname, "..")
const listPath = path.join(rootDir, "test", "test262_files.txt")
const dbPath = path.join(__dirname, "test262_results.db")

const db = new sqlite3.Database(dbPath)

if (!fs.existsSync(listPath)) {
  console.error("test262_files.txt not found, run convert_test262.py first")
  process.exit(1)
}

const allLines = fs.readFileSync(listPath, "utf8").split("\n").map(s => s.trim()).filter(Boolean)

if (allLines.length === 0) {
  console.error("No tests found in test262_files.txt")
  process.exit(1)
}

const workers = Number(process.env.WORKERS || "2")
const timeoutMs = Number(process.env.TEST_TIMEOUT_MS || "5000")
const port = Number(process.env.PORT || "3000")
const total = allLines.length

function getGroupName(pathStr) {
  const parts = pathStr.split('/')
  let startIdx = 0
  for (let i = 0; i < parts.length - 1; i++) {
    if (parts[i] === 'test262' && parts[i + 1] === 'test') {
      startIdx = i + 2
      break
    }
  }
  
  if (startIdx >= parts.length) return "misc"
  
  const p1 = parts[startIdx]
  const p2 = parts[startIdx + 1]
  if (!p1) return "misc"
  if (!p2 || p2.endsWith('.js')) return p1
  
  return `${p1}/${p2}`
}

const groupsTotal = new Map()
allLines.forEach(line => {
  const group = getGroupName(line)
  groupsTotal.set(group, (groupsTotal.get(group) || 0) + 1)
})

let completed = 0
let passed = 0
let failed = 0
let timedOut = 0

const running = new Map()
let lines = []
let nextIndex = 0

db.serialize(() => {
  db.run(`CREATE TABLE IF NOT EXISTS results (
    path TEXT PRIMARY KEY,
    status TEXT,
    error TEXT,
    duration_ms INTEGER,
    timestamp INTEGER
  )`)

  lines = allLines
  nextIndex = 0
  for (let i = 0; i < workers && i < lines.length; i++) {
    runNext(i)
  }
  
  // Check for missing tests on startup
  runMissingTests()
})

function logResult(relPath, status, error, duration) {
  const timestamp = Date.now()
  // Use INSERT OR REPLACE to handle duplicate paths
  db.run(
    "INSERT OR REPLACE INTO results (path, status, error, duration_ms, timestamp) VALUES (?, ?, ?, ?, ?)",
    [relPath, status, error, duration, timestamp],
    (err) => {
      if (err) console.error("DB Error:", err.message)
    }
  )
}

function startTest(workerId, relPath) {
  const absPath = path.join(rootDir, relPath)
  const startTime = Date.now()
  const key = workerId + ":" + relPath
  running.set(key, { test: relPath, workerId, startTime })

  const child = spawn("_build/native/release/build/main/main.exe", ["test262", absPath], {
    cwd: rootDir,
    stdio: ["ignore", "pipe", "pipe"],
  })

  let output = ""
  let settled = false

  const timer = setTimeout(() => {
    if (settled) {
      return
    }
    settled = true
    timedOut++
    failed++
    completed++
    running.delete(key)
    child.kill("SIGKILL")
    // console.log("[worker " + workerId + "] " + relPath + " TIMEOUT")
    logResult(relPath, "TIMEOUT", "Timeout", timeoutMs)
    runNext(workerId)
  }, timeoutMs)

  child.stdout.on("data", chunk => {
    const text = chunk.toString()
    output += text
    // process.stdout.write("[worker " + workerId + "] " + text)
  })

  child.stderr.on("data", chunk => {
    const text = chunk.toString()
    output += text
    // process.stderr.write("[worker " + workerId + "][stderr] " + text)
  })

  child.on("close", code => {
    if (settled) {
      return
    }
    settled = true
    clearTimeout(timer)
    running.delete(key)
    completed++
    const hasPass = /(^|\n)PASS\s/m.test(output)
    const hasFail = /(^|\n)FAIL\s/m.test(output)
    const duration = Date.now() - startTime
    if (hasPass && !hasFail) {
      passed++
      // console.log("[worker " + workerId + "] " + relPath + " PASS")
      logResult(relPath, "PASS", "", duration)
    } else {
      failed++
      // Try to extract error message
      // Format: FAIL <path> <message>
      const failLine = output.split('\n').find(l => l.startsWith('FAIL '))
      let errorMsg = "Unknown error (check logs)"
      if (failLine) {
        // FAIL path message...
        const parts = failLine.split(' ')
        if (parts.length >= 3) {
          errorMsg = parts.slice(2).join(' ')
        }
      }
      
      // console.log("[worker " + workerId + "] " + relPath + " FAIL " + errorMsg)
      logResult(relPath, "FAIL", errorMsg, duration)
    }
    runNext(workerId)
  })
}

function runNext(workerId) {
  if (nextIndex >= lines.length) {
    return
  }
  const relPath = lines[nextIndex++]
  db.get(
    "SELECT status FROM results WHERE path = ?",
    [relPath],
    (err, row) => {
      if (err) {
        console.error("DB get error:", err.message)
        startTest(workerId, relPath)
        return
      }
      if (row) {
        completed++
        if (row.status === "PASS") passed++
        else if (row.status === "FAIL") failed++
        else if (row.status === "TIMEOUT") {
          failed++
          timedOut++
        }
        runNext(workerId)
      } else {
        startTest(workerId, relPath)
      }
    }
  )
}

function getMissingTests(callback) {
  // Get all tests from the file
  const allTests = new Set(allLines)
  
  // Get all tests that have been run from the database
  db.all("SELECT DISTINCT path FROM results", [], (err, rows) => {
    if (err) {
      console.error("Error getting existing tests:", err.message)
      callback([])
      return
    }
    
    const existingTests = new Set(rows.map(row => row.path))
    const missingTests = []
    
    // Find tests that exist in file but not in database
    for (const test of allTests) {
      if (!existingTests.has(test)) {
        missingTests.push(test)
      }
    }
    
    callback(missingTests)
  })
}

function runMissingTests() {
  getMissingTests((missingTests) => {
    if (missingTests.length === 0) {
      console.log("No missing tests found.")
      return
    }
    
    console.log(`Found ${missingTests.length} missing tests. Starting to run them...`)
    
    // Add missing tests to the beginning of the queue
    lines = [...missingTests, ...lines]
    
    // Start additional workers if needed
    const availableWorkers = workers - running.size
    for (let i = 0; i < availableWorkers && i < missingTests.length; i++) {
      runNext(i)
    }
  })
}

// Check for missing tests every 60 seconds
setInterval(runMissingTests, 60000)

const indexPath = path.join(__dirname, "test262_dashboard.html")

const server = http.createServer((req, res) => {
  const url = new URL(req.url || "/", "http://localhost")
  if (url.pathname === "/" || url.pathname === "/index.html") {
    fs.readFile(indexPath, (err, data) => {
      if (err) {
        res.statusCode = 500
        res.setHeader("Content-Type", "text/plain; charset=utf-8")
        res.end("failed to load dashboard")
        return
      }
      res.setHeader("Content-Type", "text/html; charset=utf-8")
      res.end(data)
    })
    return
  }
  if (url.pathname === "/status") {
    const now = Date.now()
    const runningList = Array.from(running.values()).map(r => ({
      test: r.test,
      workerId: r.workerId,
      elapsedMs: now - r.startTime,
    }))
    
    // Get real stats from database instead of memory counters
    db.all(
      `SELECT path, status FROM results`,
      [],
      (err, rows) => {
        if (err) {
          console.error("DB stats error:", err.message)
          res.statusCode = 500
          res.end(JSON.stringify({ error: "Database error" }))
          return
        }
        
        let dbPassed = 0
        let dbFailed = 0
        let dbTimedOut = 0
        
        const groupsStats = new Map()
        
        // Initialize with totals
        for (const [name, totalCount] of groupsTotal.entries()) {
           groupsStats.set(name, {
             name,
             total: totalCount,
             passed: 0,
             failed: 0,
             timedOut: 0
           })
        }
        
        if (rows) {
          for (const row of rows) {
             if (row.status === 'PASS') dbPassed++
             else if (row.status === 'FAIL') dbFailed++
             else if (row.status === 'TIMEOUT') dbTimedOut++
             
             const groupName = getGroupName(row.path)
             const stat = groupsStats.get(groupName)
             if (stat) {
               if (row.status === 'PASS') stat.passed++
               else if (row.status === 'FAIL') stat.failed++
               else if (row.status === 'TIMEOUT') stat.timedOut++
             }
          }
        }
        
        const completed = dbPassed + dbFailed + dbTimedOut
        const remaining = Math.max(0, total - completed - runningList.length)
        
        // Convert map to array and sort
        const groupsList = Array.from(groupsStats.values()).map(g => {
           const gCompleted = g.passed + g.failed + g.timedOut
           const gRemaining = Math.max(0, g.total - gCompleted)
           return {
             ...g,
             completed: gCompleted,
             remaining: gRemaining,
             percent: g.total > 0 ? Math.round((g.passed / g.total) * 100) : 0
           }
        }).sort((a, b) => {
           // Sort by failure count descending, then name
           if (b.failed !== a.failed) return b.failed - a.failed
           return a.name.localeCompare(b.name)
        })

        const payload = {
          total: total,
          completed: completed,
          passed: dbPassed,
          failed: dbFailed,
          timedOut: dbTimedOut,
          running: runningList,
          remaining: remaining,
          workers: workers,
          timeoutMs: timeoutMs,
          groups: groupsList
        }
        res.setHeader("Content-Type", "application/json; charset=utf-8")
        res.end(JSON.stringify(payload))
      }
    )
    return
  }
  res.statusCode = 404
  res.setHeader("Content-Type", "text/plain; charset=utf-8")
  res.end("not found")
})

server.listen(port, () => {
  console.log("Test262 runner listening on http://localhost:" + port + "/")
  console.log("Total tests: " + total + ", workers: " + workers + ", timeout: " + timeoutMs + "ms")
})

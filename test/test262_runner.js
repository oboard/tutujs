const fs = require("fs")
const path = require("path")
const http = require("http")
const { spawn } = require("child_process")
const sqlite3 = require("sqlite3").verbose()

const rootDir = path.resolve(__dirname, "..")
const listPath = path.join(rootDir, "test", "test262_files.txt")
const dbPath = path.join(__dirname, "test262_results.db")

const db = new sqlite3.Database(dbPath)

db.serialize(() => {
  db.run(`CREATE TABLE IF NOT EXISTS results (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    path TEXT,
    status TEXT,
    error TEXT,
    duration_ms INTEGER,
    timestamp INTEGER
  )`)
})

if (!fs.existsSync(listPath)) {
  console.error("test262_files.txt not found, run convert_test262.py first")
  process.exit(1)
}

const lines = fs.readFileSync(listPath, "utf8").split("\n").map(s => s.trim()).filter(Boolean)

if (lines.length === 0) {
  console.error("No tests found in test262_files.txt")
  process.exit(1)
}

const workers = Number(process.env.WORKERS || "10")
const timeoutMs = Number(process.env.TEST_TIMEOUT_MS || "5000")
const port = Number(process.env.PORT || "3000")

const total = lines.length
let nextIndex = 0
let completed = 0
let passed = 0
let failed = 0
let timedOut = 0

const running = new Map()

function logResult(relPath, status, error, duration) {
  db.run(
    "INSERT INTO results (path, status, error, duration_ms, timestamp) VALUES (?, ?, ?, ?, ?)",
    [relPath, status, error, duration, Date.now()],
    (err) => {
      if (err) console.error("DB Error:", err.message)
    }
  )
}

function runNext(workerId) {
  if (nextIndex >= lines.length) {
    return
  }
  const relPath = lines[nextIndex++]
  const absPath = path.join(rootDir, relPath)
  const startTime = Date.now()
  const key = workerId + ":" + relPath
  running.set(key, { test: relPath, workerId, startTime })

  const child = spawn("moon", ["run", "main", "--", "test262", absPath], {
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
    console.log("[worker " + workerId + "] " + relPath + " TIMEOUT")
    logResult(relPath, "TIMEOUT", "Timeout", timeoutMs)
    runNext(workerId)
  }, timeoutMs)

  child.stdout.on("data", chunk => {
    const text = chunk.toString()
    output += text
    process.stdout.write("[worker " + workerId + "] " + text)
  })

  child.stderr.on("data", chunk => {
    const text = chunk.toString()
    output += text
    process.stderr.write("[worker " + workerId + "][stderr] " + text)
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
      console.log("[worker " + workerId + "] " + relPath + " PASS")
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
      
      console.log("[worker " + workerId + "] " + relPath + " FAIL " + errorMsg)
      logResult(relPath, "FAIL", errorMsg, duration)
    }
    runNext(workerId)
  })
}

for (let i = 0; i < workers && i < lines.length; i++) {
  runNext(i)
}

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
    const remaining = total - completed - runningList.length
    const payload = {
      total,
      completed,
      passed,
      failed,
      timedOut,
      running: runningList,
      remaining: remaining < 0 ? 0 : remaining,
      workers,
      timeoutMs,
    }
    res.setHeader("Content-Type", "application/json; charset=utf-8")
    res.end(JSON.stringify(payload))
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


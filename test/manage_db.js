const sqlite3 = require('sqlite3').verbose();
const path = require('path');
const { spawn } = require('child_process');
const fs = require('fs');

const dbPath = path.join(__dirname, 'test262_results.db');
const rootDir = path.resolve(__dirname, '..');
const testExe = '_build/native/release/build/main/main.exe';

// Check if executable exists
if (!fs.existsSync(path.join(rootDir, testExe))) {
    console.error(`Test executable not found: ${testExe}`);
    console.error('Please build the project first');
    process.exit(1);
}

const db = new sqlite3.Database(dbPath, (err) => {
    if (err) {
        console.error('Error opening database:', err.message);
        process.exit(1);
    }
});

function runTest(testPath, callback) {
    const absPath = path.join(rootDir, testPath);
    const startTime = Date.now();  // FIX: Define startTime at the beginning
    
    // console.log(`\n[TEST] Running: ${testPath}`);
    
    const child = spawn(testExe, ["test262", absPath], {
        cwd: rootDir,
        stdio: ["ignore", "pipe", "pipe"],
    });

    let output = "";
    let settled = false;

    const timer = setTimeout(() => {
        if (settled) return;
        settled = true;
        child.kill("SIGKILL");
        console.log(`[TIMEOUT] ${testPath} - Test took too long`);
        callback("TIMEOUT", "Timeout", 5000);
    }, 5000);

    child.stdout.on("data", chunk => {
        const text = chunk.toString();
        output += text;
    });

    child.stderr.on("data", chunk => {
        const text = chunk.toString();
        output += text;
    });

    child.on("close", code => {
        if (settled) return;
        settled = true;
        clearTimeout(timer);
        
        const hasPass = /(^|\n)PASS\s/m.test(output);
        const hasFail = /(^|\n)FAIL\s/m.test(output);
        
        if (hasPass && !hasFail) {
            console.log(`[PASS] ${testPath}`);
            callback("PASS", "", Date.now() - startTime);
        } else {
            // Try to extract error message
            const failLine = output.split('\n').find(l => l.startsWith('FAIL '));
            let errorMsg = "Unknown error (check logs)";
            if (failLine) {
                const parts = failLine.split(' ');
                if (parts.length >= 3) {
                    errorMsg = parts.slice(2).join(' ');
                }
            }
            console.log(`[FAIL] ${testPath} - ${errorMsg}`);
            callback("FAIL", errorMsg, Date.now() - startTime);
        }
    });
}

db.serialize(() => {
    // 1. Select top 10 failed rows
    db.all("SELECT * FROM results WHERE status = 'FAIL' LIMIT 10", [], (err, rows) => {
        if (err) {
            if (err.message.includes("no such table")) {
                console.error("Table 'results' does not exist. The database might be empty or uninitialized.");
                return;
            }
            console.error('Error selecting failed rows:', err.message);
            return;
        }

        if (rows.length === 0) {
            console.log("No failed rows found to delete.");
            return;
        }

        console.log(`Found ${rows.length} failed rows. Re-running tests to verify...`);
        
        // 2. Re-run each failed test and show results
        let completed = 0;
        const results = [];
        
        rows.forEach((row, index) => {
            // const startTime = Date.now();
            
            runTest(row.path, (status, error, duration) => {
                results.push({
                    path: row.path,
                    oldStatus: row.status,
                    newStatus: status,
                    error: error,
                    duration: duration
                });
                
                console.log(`\n[${status}] ${row.path}`);
                // console.log(`  Old: ${row.status} | New: ${status}`);
                if (error) console.log(`  Error: ${error}`);
                console.log(`  Duration: ${duration}ms`);
                
                completed++;
                
                if (completed === rows.length) {
                    // 3. Show summary
                    // const stillFailing = results.filter(r => r.newStatus === 'FAIL').length;
                    // const nowPassing = results.filter(r => r.newStatus === 'PASS').length;
                    // const timedOut = results.filter(r => r.newStatus === 'TIMEOUT').length;
                    
                    // console.log(`\n[SUMMARY] Re-run Results:`);
                    // console.log(`  Still failing: ${stillFailing}`);
                    // console.log(`  Now passing: ${nowPassing}`);
                    // console.log(`  Timed out: ${timedOut}`);
                    
                    // 4. Delete only the tests that are still failing
                    const stillFailedPaths = results
                        .filter(r => r.newStatus === 'FAIL')
                        .map(r => r.path);
                    
                    if (stillFailedPaths.length > 0) {
                        console.log(`\n[DELETE] Removing ${stillFailedPaths.length} tests that are still failing...`);
                        
                        const placeholders = stillFailedPaths.map(() => '?').join(',');
                        const sql = `DELETE FROM results WHERE path IN (${placeholders})`;
                        
                        db.run(sql, stillFailedPaths, function(err) {
                            if (err) {
                                console.error('Error deleting rows:', err.message);
                            } else {
                                console.log(`Successfully deleted ${this.changes} failed rows.`);
                            }
                            db.close((err) => {
                                if (err) {
                                    console.error('Error closing database:', err.message);
                                }
                            });
                        });
                    } else {
                        console.log(`\n[COMPLETE] No tests to delete - all tests are now passing or timed out!`);
                        db.close();
                    }
                }
            });
        });
    });
});


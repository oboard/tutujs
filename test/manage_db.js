const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.join(__dirname, 'test262_results.db');

// Check if DB file exists before creating a new empty one, 
// but sqlite3.Database creates it by default. 
// We can check with fs.existsSync if we want to be strict, 
// but for this task, we can just let sqlite3 open it.
// If it's empty/new, the table won't exist.

const db = new sqlite3.Database(dbPath, (err) => {
    if (err) {
        console.error('Error opening database:', err.message);
        process.exit(1);
    }
    // console.log('Connected to the SQLite database.');
});

db.serialize(() => {
    // 1. Select top 10 rows
    db.all("SELECT * FROM results LIMIT 10", [], (err, rows) => {
        if (err) {
            if (err.message.includes("no such table")) {
                console.error("Table 'results' does not exist. The database might be empty or uninitialized.");
                return;
            }
            console.error('Error selecting rows:', err.message);
            return;
        }

        if (rows.length === 0) {
            console.log("No rows found to delete.");
            return;
        }

        console.log(`Found ${rows.length} rows. Printing top 10:`);
        rows.forEach((row) => {
            console.log(JSON.stringify(row));
        });

        // 2. Delete these rows
        const ids = rows.map(row => row.id);
        const placeholders = ids.map(() => '?').join(',');
        const sql = `DELETE FROM results WHERE id IN (${placeholders})`;

        db.run(sql, ids, function(err) {
            if (err) {
                console.error('Error deleting rows:', err.message);
            } else {
                console.log(`Successfully deleted ${this.changes} rows.`);
            }
            db.close((err) => {
                if (err) {
                    console.error('Error closing database:', err.message);
                }
            });
        });
    });
});


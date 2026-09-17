use rusqlite::{params, Connection, Result as SqlResult};
use std::path::PathBuf;
use std::time::{SystemTime, UNIX_EPOCH};

pub struct HistoryManager {
    conn: Connection,
}

#[derive(Debug)]
pub struct HistoryRecord {
    pub timestamp: i64,
    pub total_bytes: u64,
    pub used_bytes: u64,
}

impl HistoryManager {
    pub fn new(db_path: PathBuf) -> SqlResult<Self> {
        let conn = Connection::open(db_path)?;
        
        conn.execute(
            "CREATE TABLE IF NOT EXISTS memory_history (
                id INTEGER PRIMARY KEY,
                timestamp INTEGER NOT NULL,
                total_bytes INTEGER NOT NULL,
                used_bytes INTEGER NOT NULL
            )",
            [],
        )?;
        
        Ok(HistoryManager { conn })
    }

    pub fn record_snapshot(&self, total_bytes: u64, used_bytes: u64) -> SqlResult<()> {
        let now = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs() as i64;

        self.conn.execute(
            "INSERT INTO memory_history (timestamp, total_bytes, used_bytes) VALUES (?1, ?2, ?3)",
            params![now, total_bytes as i64, used_bytes as i64],
        )?;

        // Cleanup older than 7 days (7 * 24 * 60 * 60 = 604800)
        let cutoff = now - 604800;
        self.conn.execute(
            "DELETE FROM memory_history WHERE timestamp < ?1",
            params![cutoff],
        )?;

        Ok(())
    }

    pub fn get_history(&self) -> SqlResult<Vec<HistoryRecord>> {
        let mut stmt = self.conn.prepare("SELECT timestamp, total_bytes, used_bytes FROM memory_history ORDER BY timestamp ASC")?;
        let rows = stmt.query_map([], |row| {
            Ok(HistoryRecord {
                timestamp: row.get(0)?,
                total_bytes: row.get::<_, i64>(1)? as u64,
                used_bytes: row.get::<_, i64>(2)? as u64,
            })
        })?;

        let mut history = Vec::new();
        for row in rows {
            history.push(row?);
        }
        Ok(history)
    }
}

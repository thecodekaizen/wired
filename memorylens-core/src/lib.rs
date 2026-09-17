pub mod memory;
pub mod process;
pub mod history;
pub mod storage;

use std::sync::Mutex;
use lazy_static::lazy_static;
use std::path::PathBuf;

use uniffi;

uniffi::setup_scaffolding!();

#[derive(uniffi::Record)]
pub struct FfiHistoryRecord {
    pub timestamp: i64,
    pub total_bytes: u64,
    pub used_bytes: u64,
}

lazy_static! {
    static ref HISTORY: Mutex<Option<history::HistoryManager>> = Mutex::new(None);
}

#[uniffi::export]
pub fn initialize_history(db_path: String) -> Result<(), MemoryError> {
    let mut db_guard = HISTORY.lock().unwrap();
    if db_guard.is_none() {
        match history::HistoryManager::new(PathBuf::from(db_path)) {
            Ok(manager) => {
                *db_guard = Some(manager);
                Ok(())
            },
            Err(e) => Err(MemoryError::ApiError(format!("DB init error: {}", e))),
        }
    } else {
        Ok(())
    }
}

#[uniffi::export]
pub fn record_history_snapshot(total_bytes: u64, used_bytes: u64) -> Result<(), MemoryError> {
    if let Some(manager) = HISTORY.lock().unwrap().as_ref() {
        manager.record_snapshot(total_bytes, used_bytes).map_err(|e| MemoryError::ApiError(format!("DB error: {}", e)))
    } else {
        Err(MemoryError::ApiError("History not initialized".to_string()))
    }
}

#[uniffi::export]
pub fn get_history() -> Result<Vec<FfiHistoryRecord>, MemoryError> {
    if let Some(manager) = HISTORY.lock().unwrap().as_ref() {
        let records = manager.get_history().map_err(|e| MemoryError::ApiError(format!("DB error: {}", e)))?;
        Ok(records.into_iter().map(|r| FfiHistoryRecord {
            timestamp: r.timestamp,
            total_bytes: r.total_bytes,
            used_bytes: r.used_bytes,
        }).collect())
    } else {
        Err(MemoryError::ApiError("History not initialized".to_string()))
    }
}


#[derive(uniffi::Record)]
pub struct FfiSystemMemory {
    pub total_bytes: u64,
    pub wired_bytes: u64,
    pub active_bytes: u64,
    pub inactive_bytes: u64,
    pub compressed_bytes: u64,
    pub free_bytes: u64,
}

#[derive(uniffi::Record)]
pub struct FfiProcessMemory {
    pub pid: i32,
    pub ppid: i32,
    pub resident_size: u64,
    pub virtual_size: u64,
    pub name: String,
}

#[derive(Debug, thiserror::Error, uniffi::Error)]
pub enum MemoryError {
    #[error("System API error: {0}")]
    ApiError(String),
}

#[uniffi::export]
pub fn sample_system() -> Result<FfiSystemMemory, MemoryError> {
    memory::sample_system().map_err(|e| MemoryError::ApiError(e)).map(|m| FfiSystemMemory {
        total_bytes: m.total_bytes,
        wired_bytes: m.wired_bytes,
        active_bytes: m.active_bytes,
        inactive_bytes: m.inactive_bytes,
        compressed_bytes: m.compressed_bytes,
        free_bytes: m.free_bytes,
    })
}

#[uniffi::export]
pub fn list_processes() -> Vec<FfiProcessMemory> {
    process::list_processes().into_iter().map(|p| FfiProcessMemory {
        pid: p.pid,
        ppid: p.ppid,
        resident_size: p.resident_size,
        virtual_size: p.virtual_size,
        name: p.name,
    }).collect()
}

#[derive(uniffi::Record, Debug, Clone)]
pub struct FfiStorageTarget {
    pub id: String,
    pub name: String,
    pub category: String,
    pub description: String,
    pub path: String,
    pub size_bytes: u64,
    pub default_checked: bool,
}

#[uniffi::export]
pub fn scan_storage() -> Vec<FfiStorageTarget> {
    storage::scan_storage()
}

#[uniffi::export]
pub fn clean_storage_targets(paths: Vec<String>) -> Result<u64, MemoryError> {
    storage::clean_storage_targets(paths).map_err(|e| MemoryError::ApiError(e))
}

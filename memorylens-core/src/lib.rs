pub mod memory;
pub mod process;

use std::sync::Arc;
use uniffi;

uniffi::setup_scaffolding!();

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

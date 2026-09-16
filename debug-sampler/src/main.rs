use memorylens_core::memory::sample_system;
use memorylens_core::process::list_processes;
use std::thread;
use std::time::Duration;

fn format_bytes(bytes: u64) -> String {
    let mb = bytes as f64 / (1024.0 * 1024.0);
    if mb > 1024.0 {
        format!("{:.2} GB", mb / 1024.0)
    } else {
        format!("{:.2} MB", mb)
    }
}

fn main() {
    println!("--- MemoryLens Debug Sampler ---");
    println!("Sampling system memory...");
    
    match sample_system() {
        Ok(mem) => {
            println!("Physical Memory: {}", format_bytes(mem.total_bytes));
            println!("Memory Used: {}", format_bytes(mem.wired_bytes + mem.active_bytes + mem.compressed_bytes));
            println!("  Wired Memory: {}", format_bytes(mem.wired_bytes));
            println!("  Active Memory: {}", format_bytes(mem.active_bytes));
            println!("  Compressed: {}", format_bytes(mem.compressed_bytes));
            println!("Cached Files (Inactive): {}", format_bytes(mem.inactive_bytes));
            println!("Free Memory: {}", format_bytes(mem.free_bytes));
        }
        Err(e) => eprintln!("Error sampling system memory: {}", e),
    }

    println!("\nSampling processes (top 10 by resident size)...");
    let mut procs = list_processes();
    procs.sort_by(|a, b| b.resident_size.cmp(&a.resident_size));
    
    println!("{:<8} {:<8} {:<30} {:<15} {:<15}", "PID", "PPID", "Name", "Memory (RES)", "Virtual Size");
    println!("{}", "-".repeat(80));
    
    for proc in procs.iter().take(10) {
        println!("{:<8} {:<8} {:<30} {:<15} {:<15}",
            proc.pid,
            proc.ppid,
            if proc.name.len() > 28 { format!("{}..", &proc.name[0..26]) } else { proc.name.clone() },
            format_bytes(proc.resident_size),
            format_bytes(proc.virtual_size)
        );
    }
    
    println!("\nKeep this running to monitor system (Ctrl+C to exit)");
    loop {
        thread::sleep(Duration::from_secs(5));
        if let Ok(mem) = sample_system() {
            println!("Free: {} | Wired: {} | Active: {} | Compressed: {}", 
                format_bytes(mem.free_bytes),
                format_bytes(mem.wired_bytes),
                format_bytes(mem.active_bytes),
                format_bytes(mem.compressed_bytes)
            );
        }
    }
}

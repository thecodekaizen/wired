use std::mem;

#[derive(Debug, Clone, Copy, Default)]
pub struct SystemMemory {
    pub total_bytes: u64,
    pub wired_bytes: u64,
    pub active_bytes: u64,
    pub inactive_bytes: u64,
    pub compressed_bytes: u64,
    pub free_bytes: u64,
    pub page_size: u64,
}

pub fn sample_system() -> Result<SystemMemory, String> {
    unsafe {
        #[allow(deprecated)]
        let host_port = libc::mach_host_self();
        let mut count: libc::mach_msg_type_number_t = libc::HOST_VM_INFO64_COUNT;
        let mut stats: libc::vm_statistics64 = mem::zeroed();

        let res = libc::host_statistics64(
            host_port,
            libc::HOST_VM_INFO64,
            &mut stats as *mut _ as libc::host_info64_t,
            &mut count,
        );

        if res != libc::KERN_SUCCESS {
            return Err(format!("host_statistics64 failed with code: {}", res));
        }

        let page_size_u64 = libc::sysconf(libc::_SC_PAGESIZE) as u64;
        
        let mut mib = [libc::CTL_HW, libc::HW_MEMSIZE];
        let mut total_bytes: u64 = 0;
        let mut size = mem::size_of::<u64>();
        if libc::sysctl(
            mib.as_mut_ptr(),
            mib.len() as libc::c_uint,
            &mut total_bytes as *mut _ as *mut libc::c_void,
            &mut size,
            std::ptr::null_mut(),
            0,
        ) != 0 {
            return Err("Failed to get physical memory size".to_string());
        }

        Ok(SystemMemory {
            total_bytes,
            wired_bytes: stats.wire_count as u64 * page_size_u64,
            active_bytes: stats.active_count as u64 * page_size_u64,
            inactive_bytes: stats.inactive_count as u64 * page_size_u64,
            compressed_bytes: stats.compressor_page_count as u64 * page_size_u64,
            free_bytes: stats.free_count as u64 * page_size_u64,
            page_size: page_size_u64,
        })
    }
}

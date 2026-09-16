use libproc::libproc::proc_pid::{pidinfo, ProcType};
use libproc::processes::pids_by_type;
use libproc::libproc::task_info::TaskInfo;
use libproc::libproc::bsd_info::BSDInfo;

#[derive(Debug, Clone)]
pub struct ProcessMemory {
    pub pid: i32,
    pub ppid: i32,
    pub resident_size: u64,
    pub virtual_size: u64,
    pub name: String,
}

pub fn list_processes() -> Vec<ProcessMemory> {
    let mut results = Vec::new();

    if let Ok(pids) = pids_by_type(ProcType::ProcAllPIDS.into()) {
        for pid in pids {
            let pid = pid as i32;
            
            // Get task info (memory)
            let task_info_res = pidinfo::<TaskInfo>(pid, 0);
            
            // Get name and ppid from BSDInfo (equivalent to proc_pidinfo with PROC_PIDTBSDINFO)
            let bsd_info_res = pidinfo::<BSDInfo>(pid, 0);
            
            if let (Ok(task_info), Ok(bsd_info)) = (task_info_res, bsd_info_res) {
                // Name extraction from BSDInfo
                let name = unsafe {
                    let c_str = std::ffi::CStr::from_ptr(bsd_info.pbi_name.as_ptr() as *const i8);
                    c_str.to_string_lossy().into_owned()
                };

                results.push(ProcessMemory {
                    pid,
                    ppid: bsd_info.pbi_ppid as i32,
                    resident_size: task_info.pti_resident_size,
                    virtual_size: task_info.pti_virtual_size,
                    name,
                });
            }
        }
    }
    
    results
}

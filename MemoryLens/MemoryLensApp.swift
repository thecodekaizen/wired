import SwiftUI
import MemoryLensCorePackage

@main
struct MemoryLensApp: App {
    @StateObject private var memoryMonitor = MemoryMonitor()
    
    var body: some Scene {
        MenuBarExtra {
            ContentView(monitor: memoryMonitor)
        } label: {
            // macOS standard menu bar icons are typically template images.
            // We can show pressure as text, e.g., "75%" or just an icon.
            Label("MemoryLens", systemImage: "memorychip")
                // A subtle indicator could be added if we render a custom view,
                // but standard Label is safest for MenuBarExtra.
        }
        .menuBarExtraStyle(.window)
    }
}

class MemoryMonitor: ObservableObject {
    @Published var systemMemory: FfiSystemMemory?
    @Published var processes: [FfiProcessMemory] = []
    @Published var history: [FfiHistoryRecord] = []
    
    private var timer: Timer?
    
    init() {
        DaemonManager.shared.registerDaemon()
        setupHistory()
        startMonitoring()
    }
    
    private func setupHistory() {
        let fileManager = FileManager.default
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("MemoryLens")
        
        do {
            try fileManager.createDirectory(at: appDir, withIntermediateDirectories: true, attributes: nil)
            let dbPath = appDir.appendingPathComponent("history.db").path
            try initializeHistory(dbPath: dbPath)
            print("History DB initialized at: \(dbPath)")
            fetchHistory()
        } catch {
            print("Failed to setup history: \(error)")
        }
    }
    
    func startMonitoring() {
        // Initial fetch
        fetchData()
        
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.fetchData()
        }
    }
    
    private func fetchData() {
        do {
            let memory = try sampleSystem()
            let procs = try listProcesses()
            
            // Record history (calculate used_bytes)
            let usedBytes = memory.wiredBytes + memory.activeBytes + memory.inactiveBytes + memory.compressedBytes
            try? recordHistorySnapshot(totalBytes: memory.totalBytes, usedBytes: usedBytes)
            
            // Sort processes by resident memory (descending)
            let sortedProcs = procs.sorted { $0.residentSize > $1.residentSize }
            
            DispatchQueue.main.async {
                self.systemMemory = memory
                self.processes = sortedProcs
                // Only update history periodically to avoid redrawing chart every 2 seconds
                // But for a simple app, we can just fetch it occasionally or when switching tabs
            }
        } catch {
            print("Failed to fetch memory data: \(error)")
        }
    }
    
    func fetchHistory() {
        do {
            let records = try getHistory()
            DispatchQueue.main.async {
                self.history = records
            }
        } catch {
            print("Failed to fetch history: \(error)")
        }
    }
    
    func killProcess(pid: Int32, force: Bool) {
        if force {
            DaemonManager.shared.forceQuit(pid: pid) { success in
                if success {
                    self.fetchData()
                } else {
                    print("Force quit failed")
                }
            }
        } else {
            // Standard SIGTERM
            kill(pid, SIGTERM)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.fetchData()
            }
        }
    }
    
    func purgeMemory() {
        DaemonManager.shared.purgeMemory { success in
            if success {
                self.fetchData()
            } else {
                print("Purge memory failed")
            }
        }
    }
}

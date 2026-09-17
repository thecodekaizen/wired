import SwiftUI
import MemoryLensCorePackage
import Charts

struct ContentView: View {
    @ObservedObject var monitor: MemoryMonitor
    @State private var selectedProcess: FfiProcessMemory?
    @State private var showingKillConfirm = false
    
    // Hardcoded deny list for critical system processes
    private let denyList: Set<String> = [
        "kernel_task", "launchd", "WindowServer", "sysmond", "syslogd", 
        "opendirectoryd", "logd", "configd", "Fseventsd", "mds"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("MemoryLens")
                    .font(.headline)
                Spacer()
                Button(action: { monitor.purgeMemory() }) {
                    Image(systemName: "trash")
                    Text("Purge")
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(4)
                
                Button(action: { NSApplication.shared.terminate(nil) }) {
                    Image(systemName: "power")
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            TabView {
                // Dashboard Tab
                VStack(spacing: 0) {
                    // Memory Overview
                    if let mem = monitor.systemMemory {
                        MemoryOverviewView(memory: mem)
                            .padding()
                    } else {
                        Text("Loading Memory Data...")
                            .frame(height: 100)
                            .padding()
                    }
                    
                    Divider()
                    
                    // Process Table
                    Table(monitor.processes) {
                        TableColumn("PID") { proc in
                            Text("\(proc.pid)")
                                .foregroundColor(.secondary)
                        }
                        .width(50)
                        
                        TableColumn("Process") { proc in
                            Text(proc.name)
                                .fontWeight(denyList.contains(proc.name) ? .regular : .semibold)
                        }
                        
                        TableColumn("Memory") { proc in
                            Text(formatBytes(proc.residentSize))
                                .monospacedDigit()
                        }
                        .width(80)
                        
                        TableColumn("Action") { proc in
                            if !denyList.contains(proc.name) {
                                Button("Kill") {
                                    selectedProcess = proc
                                    showingKillConfirm = true
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            } else {
                                Text("System")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .width(60)
                    }
                }
                .tabItem {
                    Label("Dashboard", systemImage: "gauge.with.dots.needle.bottom.100percent")
                }
                
                // History Tab
                HistoryView(history: monitor.history)
                    .tabItem {
                        Label("History", systemImage: "chart.xyaxis.line")
                    }
                    .onAppear {
                        monitor.fetchHistory()
                    }
            }
        }
        .frame(width: 400, height: 500)
        .confirmationDialog(
            "Kill Process?",
            isPresented: $showingKillConfirm,
            presenting: selectedProcess
        ) { proc in
            Button("Kill (SIGTERM)", role: .destructive) {
                monitor.killProcess(pid: proc.pid, force: false)
            }
            Button("Force Kill (SIGKILL)", role: .destructive) {
                monitor.killProcess(pid: proc.pid, force: true)
            }
            Button("Cancel", role: .cancel) {}
        } message: { proc in
            Text("Are you sure you want to kill '\(proc.name)' (\(proc.pid))? This may cause data loss.")
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct MemoryOverviewView: View {
    let memory: FfiSystemMemory
    
    struct MemorySegment: Identifiable {
        let id = UUID()
        let name: String
        let bytes: UInt64
        let color: Color
    }
    
    var segments: [MemorySegment] {
        [
            MemorySegment(name: "Wired", bytes: memory.wiredBytes, color: .red),
            MemorySegment(name: "Active", bytes: memory.activeBytes, color: .orange),
            MemorySegment(name: "Inactive", bytes: memory.inactiveBytes, color: .blue),
            MemorySegment(name: "Compressed", bytes: memory.compressedBytes, color: .purple),
            MemorySegment(name: "Free", bytes: memory.freeBytes, color: .green)
        ]
    }
    
    var totalUsed: UInt64 {
        memory.wiredBytes + memory.activeBytes + memory.inactiveBytes + memory.compressedBytes
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Physical Memory:")
                Spacer()
                Text(formatBytes(memory.totalBytes))
                    .fontWeight(.bold)
            }
            
            Chart(segments) { segment in
                BarMark(
                    x: .value("Bytes", Double(segment.bytes))
                )
                .foregroundStyle(segment.color)
            }
            .chartXAxis(.hidden)
            .frame(height: 24)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            
            HStack {
                Text("Used: \(formatBytes(totalUsed))")
                    .foregroundColor(.secondary)
                Spacer()
                Text("Free: \(formatBytes(memory.freeBytes))")
                    .foregroundColor(.secondary)
            }
            .font(.caption)
            
            // Legend
            HStack(spacing: 8) {
                ForEach(segments) { segment in
                    HStack(spacing: 4) {
                        Circle().fill(segment.color).frame(width: 8, height: 8)
                        Text(segment.name).font(.caption2)
                    }
                }
            }
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// Ensure FfiProcessMemory conforms to Identifiable
extension FfiProcessMemory: Identifiable {
    public var id: Int32 { self.pid }
}

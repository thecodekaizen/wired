import SwiftUI
import MemoryLensCorePackage

struct ContentView: View {
    @State private var systemMemory: FfiSystemMemory?
    @State private var processes: [FfiProcessMemory] = []
    @State private var errorMessage: String?
    
    let timer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("MemoryLens")
                .font(.headline)
            
            if let error = errorMessage {
                Text("Error: \(error)").foregroundColor(.red)
            } else if let mem = systemMemory {
                VStack(alignment: .leading) {
                    Text("Total: \(formatBytes(mem.totalBytes))")
                    Text("Wired: \(formatBytes(mem.wiredBytes))")
                    Text("Active: \(formatBytes(mem.activeBytes))")
                    Text("Inactive: \(formatBytes(mem.inactiveBytes))")
                    Text("Compressed: \(formatBytes(mem.compressedBytes))")
                    Text("Free: \(formatBytes(mem.freeBytes))")
                }
                .font(.subheadline)
            } else {
                Text("Loading...")
            }
            
            Divider()
            
            Text("Top Processes")
                .font(.headline)
            
            List(processes.prefix(10), id: \.pid) { proc in
                HStack {
                    Text(proc.name).frame(maxWidth: .infinity, alignment: .leading)
                    Text(formatBytes(proc.residentSize)).frame(alignment: .trailing)
                }
            }
            .frame(height: 200)
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .padding(.top)
        }
        .padding()
        .frame(width: 300, height: 450)
        .onReceive(timer) { _ in
            updateData()
        }
        .onAppear {
            updateData()
        }
    }
    
    func updateData() {
        do {
            systemMemory = try sampleSystem()
            var allProcs = listProcesses()
            allProcs.sort { $0.residentSize > $1.residentSize }
            processes = allProcs
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .memory
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

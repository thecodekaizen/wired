import SwiftUI
import MemoryLensCorePackage

struct StorageCleanerView: View {
    @ObservedObject var monitor: MemoryMonitor
    @State private var selectedTargets: Set<String> = []
    @State private var isCleaning = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Storage Cleaner")
                    .font(.headline)
                Spacer()
                
                let selectedSize = monitor.storageTargets
                    .filter { selectedTargets.contains($0.id) }
                    .reduce(0) { $0 + $1.sizeBytes }
                
                if isCleaning {
                    ProgressView()
                        .controlSize(.small)
                        .padding(.trailing, 8)
                }
                
                Button(action: cleanSelected) {
                    Text("Clean \(formatBytes(selectedSize))")
                        .fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedTargets.isEmpty || isCleaning)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Storage Target List
            List {
                if monitor.storageTargets.isEmpty {
                    HStack {
                        Spacer()
                        ProgressView("Scanning disk...")
                        Spacer()
                    }
                    .padding()
                } else {
                    let grouped = Dictionary(grouping: monitor.storageTargets, by: { $0.category })
                    
                    ForEach(grouped.keys.sorted(), id: \.self) { category in
                        Section(header: Text(category).font(.subheadline).foregroundColor(.secondary)) {
                            ForEach(grouped[category] ?? [], id: \.id) { target in
                                Toggle(isOn: Binding(
                                    get: { selectedTargets.contains(target.id) },
                                    set: { isOn in
                                        if isOn {
                                            selectedTargets.insert(target.id)
                                        } else {
                                            selectedTargets.remove(target.id)
                                        }
                                    }
                                )) {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(target.name).fontWeight(.medium)
                                            Text(target.description).font(.caption).foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Text(formatBytes(target.sizeBytes))
                                            .monospacedDigit()
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
            }
            .listStyle(.inset)
        }
        .onAppear {
            if monitor.storageTargets.isEmpty {
                monitor.refreshStorage()
            }
            // Sync default checked
            for target in monitor.storageTargets where target.defaultChecked {
                selectedTargets.insert(target.id)
            }
        }
        .onChange(of: monitor.storageTargets.count) { _ in
            for target in monitor.storageTargets where target.defaultChecked {
                selectedTargets.insert(target.id)
            }
        }
    }
    
    private func cleanSelected() {
        guard !selectedTargets.isEmpty else { return }
        
        let pathsToClean = monitor.storageTargets
            .filter { selectedTargets.contains($0.id) }
            .map { $0.path }
        
        isCleaning = true
        monitor.performStorageCleanup(paths: pathsToClean) {
            isCleaning = false
            selectedTargets.removeAll()
            monitor.refreshStorage() // Rescan after cleaning
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

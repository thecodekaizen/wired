import SwiftUI
import MemoryLensCorePackage

@main
struct MemoryLensApp: App {
    var body: some Scene {
        MenuBarExtra("MemoryLens", systemImage: "memorychip") {
            ContentView()
        }
        .menuBarExtraStyle(.window)
    }
}

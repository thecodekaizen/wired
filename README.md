# Wired (MemoryLens)

Wired (also known internally as MemoryLens) is a high-performance macOS utility designed to help developers monitor system resources, manage active processes, and reclaim wasted disk space from leftover caches. 

## Architecture
Wired is built with a dual-layer architecture:
- **Core (Rust)**: High-performance, memory-safe backend (`memorylens-core`) for parsing system memory statistics, inspecting processes, tracking history in SQLite, and recursively calculating disk footprints for cached items. Exposed to Swift via UniFFI.
- **UI (SwiftUI)**: Native macOS menu bar application (`MemoryLens`) that presents real-time data, charts, and actionable controls in a modern interface.
- **Daemon (XPC)**: Privileged helper tool (`memorylens-helperd`) capable of executing secure root-level operations (like purging inactive RAM and force-quitting system processes) via SMAppService.

## Features

### Dashboard
- **Real-time Memory Monitoring**: View memory pressure, wired, active, inactive, compressed, and free memory breakdown in a color-coded chart.
- **Process Management**: View running processes sorted by memory footprint and send SIGTERM or SIGKILL (Force Quit) signals directly from the UI.
- **Memory Purge**: Triggers `sudo purge` seamlessly using a secure XPC daemon to instantly free up inactive system RAM.

### History
- **Historical Analysis**: Tracks your Mac's memory usage over time and stores it locally in SQLite. Displays a native Swift Chart showing memory consumption trends.

### Storage Cleaner
- **Disk Cache Cleanup**: Identifies large caches from applications, Docker, Xcode (DerivedData, Device Support), Homebrew, npm, and pip.
- **Sparse File Support**: Accurately calculates true disk utilization (accounting for sparse files like Docker virtual disks) and safely clears them with user-level privileges to reclaim gigabytes of space.

## Development

### Prerequisites
- Xcode 15+ and macOS 13.0+
- Rust toolchain (`rustup`)
- `cargo-xcode` or Xcodegen for generating Xcode projects

### Building
To compile the Rust core, generate the Swift bindings, and build the `MemoryLens.xcodeproj`:
```bash
./build.sh
```
Open `MemoryLens.xcodeproj` in Xcode to build and run the target.

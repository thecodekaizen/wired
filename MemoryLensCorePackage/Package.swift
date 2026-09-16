// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "MemoryLensCorePackage",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "MemoryLensCorePackage",
            targets: ["MemoryLensCorePackage"]),
    ],
    targets: [
        .target(
            name: "MemoryLensCorePackage",
            dependencies: ["MemoryLensCoreFFI"],
            path: "Sources/MemoryLensCorePackage"
        ),
        .binaryTarget(
            name: "MemoryLensCoreFFI",
            path: "../MemoryLensCore.xcframework"
        )
    ]
)

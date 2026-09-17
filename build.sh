#!/bin/bash
set -e

echo "Building Rust core..."
cd memorylens-core
cargo build --release --target aarch64-apple-darwin
cargo build --release --target x86_64-apple-darwin
cd ..

echo "Creating universal binary..."
mkdir -p target/universal/release
lipo -create -output target/universal/release/libmemorylens_core.a \
    target/aarch64-apple-darwin/release/libmemorylens_core.a \
    target/x86_64-apple-darwin/release/libmemorylens_core.a

echo "Generating Swift bindings..."
mkdir -p bindings
cd memorylens-core
cargo build --release
cargo run --bin uniffi-bindgen -- generate --language swift --library ../target/release/libmemorylens_core.dylib --out-dir ../bindings
cd ..

# Rename the modulemap so Xcode can find it automatically in the XCFramework Headers
if [ -f "bindings/memorylens_coreFFI.modulemap" ]; then
    mv bindings/memorylens_coreFFI.modulemap bindings/module.modulemap
fi


if command -v xcodebuild &> /dev/null; then
    if xcode-select -p &> /dev/null; then
        echo "Creating XCFramework..."
        rm -rf MemoryLensCore.xcframework
        xcodebuild -create-xcframework \
            -library target/universal/release/libmemorylens_core.a \
            -headers bindings \
            -output MemoryLensCore.xcframework
    else
        echo "Xcode is not selected. Skipping XCFramework generation."
    fi
else
    echo "xcodebuild not found. Skipping XCFramework generation."
fi

echo "Copying Swift module..."
mkdir -p MemoryLensCorePackage/Sources/MemoryLensCorePackage
cp bindings/memorylens_core.swift MemoryLensCorePackage/Sources/MemoryLensCorePackage/

echo "Generating Xcode Project..."
xcodegen generate

echo "Build complete. Open MemoryLens.xcodeproj to run the app."

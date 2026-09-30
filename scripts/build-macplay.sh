#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
swiftc -parse-as-library -O -target arm64-apple-macosx14.0 -framework SwiftUI -framework AppKit -framework CoreWLAN -framework CoreLocation -framework IOKit -framework IOBluetooth -framework CoreAudio -framework MediaPlayer native/App/MacPlay.swift native/App/NowPlayingState.swift native/App/NowPlayingFeed.swift -o build/MacPlay
clang -fobjc-arc -framework Foundation -framework AppKit -framework IOBluetooth -sectcreate __TEXT __info_plist native/macplay-bluetooth/Info.plist native/macplay-bluetooth/main.m -o native/macplay-bluetooth/macplay-bluetooth
node scripts/build-native.mjs --arch=arm64
cargo build --release --manifest-path native/livi-helperd/Cargo.toml -p livi-helperd
node node_modules/typescript/bin/tsc -p native/Engine/tsconfig.json
bash scripts/package-native.sh

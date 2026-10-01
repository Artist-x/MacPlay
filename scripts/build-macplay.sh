#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build

HOST_ARCH="$(uname -m)"
TARGET_ARCH="${MACPLAY_ARCH:-}"

# Parse optional arguments like --arch=x64 or --arch=arm64
for arg in "$@"; do
  case "$arg" in
    --arch=*)
      TARGET_ARCH="${arg#*=}"
      ;;
  esac
done

if [[ -z "$TARGET_ARCH" ]]; then
  if [[ "$HOST_ARCH" == "x86_64" ]]; then
    TARGET_ARCH="x64"
  else
    TARGET_ARCH="arm64"
  fi
fi

echo "==> Building MacPlay for target architecture: $TARGET_ARCH (host: $HOST_ARCH)"

SWIFT_FLAGS=(-parse-as-library -O -framework SwiftUI -framework AppKit -framework CoreWLAN -framework CoreLocation -framework IOKit -framework IOBluetooth -framework CoreAudio -framework MediaPlayer)
CLANG_FLAGS=(-fobjc-arc -framework Foundation -framework AppKit -framework IOBluetooth -sectcreate __TEXT __info_plist native/macplay-bluetooth/Info.plist)
CARGO_FLAGS=(--release --manifest-path native/livi-helperd/Cargo.toml -p livi-helperd)

case "$TARGET_ARCH" in
  x64|x86_64)
    NORM_ARCH="x86_64"
    NODE_ARCH_ARG="--arch=x64"
    SWIFT_FLAGS+=(-target x86_64-apple-macosx14.0)
    CLANG_FLAGS+=(-arch x86_64)
    if [[ "$HOST_ARCH" != "x86_64" ]]; then
      rustup target add x86_64-apple-darwin 2>/dev/null || true
      CARGO_FLAGS+=(--target x86_64-apple-darwin)
    fi
    ;;
  arm64|aarch64)
    NORM_ARCH="arm64"
    NODE_ARCH_ARG="--arch=arm64"
    SWIFT_FLAGS+=(-target arm64-apple-macosx14.0)
    CLANG_FLAGS+=(-arch arm64)
    if [[ "$HOST_ARCH" != "arm64" ]]; then
      rustup target add aarch64-apple-darwin 2>/dev/null || true
      CARGO_FLAGS+=(--target aarch64-apple-darwin)
    fi
    ;;
  universal)
    NORM_ARCH="universal"
    NODE_ARCH_ARG="--arch=x64"
    SWIFT_FLAGS+=(-target arm64-apple-macosx14.0 -target x86_64-apple-macosx14.0)
    CLANG_FLAGS+=(-arch arm64 -arch x86_64)
    ;;
  *)
    echo "Unknown architecture: $TARGET_ARCH. Defaulting to host ($HOST_ARCH)"
    NORM_ARCH="$HOST_ARCH"
    NODE_ARCH_ARG="--arch=$HOST_ARCH"
    ;;
esac

export MACPLAY_ARCH="$NORM_ARCH"

echo "==> Compiling Swift UI..."
swiftc "${SWIFT_FLAGS[@]}" native/App/MacPlay.swift native/App/NowPlayingState.swift native/App/NowPlayingFeed.swift -o build/MacPlay

echo "==> Compiling Bluetooth bridge..."
clang "${CLANG_FLAGS[@]}" native/macplay-bluetooth/main.m -o native/macplay-bluetooth/macplay-bluetooth

echo "==> Building native addons..."
node scripts/build-native.mjs "$NODE_ARCH_ARG"

echo "==> Building helper daemon..."
cargo build "${CARGO_FLAGS[@]}"

echo "==> Compiling TypeScript engine..."
node node_modules/typescript/bin/tsc -p native/Engine/tsconfig.json

echo "==> Packaging native app..."
bash scripts/package-native.sh "$@"


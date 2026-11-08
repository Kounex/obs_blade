#!/bin/bash
# Builds the core as a static library for the shells (plugin, standalone):
#   macOS: universal (arm64 + x86_64) -> target/dist/macos/libobb.a
#   Linux: target/dist/linux/libobb.a
# Windows builds in CI (cargo build --release -> obb.lib).
set -euo pipefail
cd "$(dirname "$0")"
case "$(uname -s)" in
  Darwin)
    rustup target add aarch64-apple-darwin x86_64-apple-darwin >/dev/null
    export MACOSX_DEPLOYMENT_TARGET=12.0
    for target in aarch64-apple-darwin x86_64-apple-darwin; do
      cargo build --release --lib --target "$target"
    done
    mkdir -p target/dist/macos
    lipo -create -output target/dist/macos/libobb.a \
      target/aarch64-apple-darwin/release/libobb.a \
      target/x86_64-apple-darwin/release/libobb.a
    echo "target/dist/macos/libobb.a"
    ;;
  Linux)
    cargo build --release --lib
    mkdir -p target/dist/linux
    cp target/release/libobb.a target/dist/linux/libobb.a
    echo "target/dist/linux/libobb.a"
    ;;
  *)
    echo "use cargo build --release on this platform" >&2
    exit 1
    ;;
esac

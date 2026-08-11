#!/usr/bin/env sh
set -e

# Poietic Playground - macOS App Bundle Builder Script

BUILD_CONFIG="release"
OUTPUT_DIR=".build/macos"
APP_NAME="Poietic Playground.app"

usage() {
    cat <<EOF
Poietic Playground macOS App Bundle Builder

Usage:
  ./scripts/build-macos-app.sh [OPTIONS]

Options:
  --debug         Build in debug mode instead of release mode
  --output DIR    Specify output directory for .app bundle (default: .build/macos)
  -h, --help      Display this help message
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --debug)
            BUILD_CONFIG="debug"
            shift
            ;;
        --output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Error: Unknown option '$1'"
            usage
            exit 1
            ;;
    esac
done

echo "=========================================="
echo "Building macOS App Bundle ($BUILD_CONFIG)"
echo "=========================================="

if ! command -v swift >/dev/null 2>&1; then
    echo "Error: 'swift' compiler not found."
    exit 1
fi

echo "--> Compiling executable..."
swift build -c "$BUILD_CONFIG"

SWIFT_BIN_PATH=$(swift build -c "$BUILD_CONFIG" --show-bin-path)
BUILD_EXEC="$SWIFT_BIN_PATH/PoieticPlayground"

if [ ! -f "$BUILD_EXEC" ]; then
    echo "Error: Executable not found at $BUILD_EXEC"
    exit 1
fi

TARGET_APP_PATH="$OUTPUT_DIR/$APP_NAME"
CONTENTS_DIR="$TARGET_APP_PATH/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "--> Preparing bundle directory at $TARGET_APP_PATH..."
rm -rf "$TARGET_APP_PATH"
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

echo "--> Copying executable..."
cp -f "$BUILD_EXEC" "$MACOS_DIR/PoieticPlayground"
chmod +x "$MACOS_DIR/PoieticPlayground"

echo "--> Copying resources..."
cp -r Sources/PoieticPlayground/Resources/* "$RESOURCES_DIR/"

echo "--> Copying Info.plist..."
if [ -f "Info.plist" ]; then
    cp -f Info.plist "$CONTENTS_DIR/Info.plist"
else
    echo "Warning: Info.plist not found, skipping."
fi

# Code sign if codesign tool is present (macOS ad-hoc signing)
if command -v codesign >/dev/null 2>&1; then
    echo "--> Ad-hoc signing app bundle..."
    codesign -s - --force --deep "$TARGET_APP_PATH" >/dev/null 2>&1 || true
fi

echo ""
echo "=========================================="
echo "macOS Application Bundle created successfully!"
echo "Bundle location: $TARGET_APP_PATH"
echo "=========================================="

#!/usr/bin/env sh
set -e

# Poietic Playground - AppImage Packaging Script

APP_DIR="AppDir"
OUTPUT_APPIMAGE="PoieticPlayground-x86_64.AppImage"

echo "=========================================="
echo "Building AppImage for Poietic Playground"
echo "=========================================="

if ! command -v swift >/dev/null 2>&1; then
    echo "Error: 'swift' compiler not found."
    exit 1
fi

echo "--> Building release binary..."
swift build -c release

SWIFT_BIN_PATH=$(swift build -c release --show-bin-path)
BUILD_EXEC="$SWIFT_BIN_PATH/PoieticPlayground"

if [ ! -f "$BUILD_EXEC" ]; then
    echo "Error: Executable not found at $BUILD_EXEC"
    exit 1
fi

echo "--> Preparing AppDir layout..."
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/usr/bin"
mkdir -p "$APP_DIR/usr/share/poietic-playground"

echo "--> Copying binary and resources..."
cp -f "$BUILD_EXEC" "$APP_DIR/usr/bin/PoieticPlayground"
chmod +x "$APP_DIR/usr/bin/PoieticPlayground"

cp -r Sources/PoieticPlayground/Resources/* "$APP_DIR/usr/share/poietic-playground/"

echo "--> Creating desktop file and icons..."
cp -f poietic-playground.desktop "$APP_DIR/poietic-playground.desktop"
cp -f poietic-playground.desktop "$APP_DIR/default.desktop"

ICON_SRC="Sources/PoieticPlayground/Resources/icons/black/run.png"
if [ -f "$ICON_SRC" ]; then
    cp -f "$ICON_SRC" "$APP_DIR/poietic-playground.png"
    cp -f "$ICON_SRC" "$APP_DIR/.DirIcon"
fi

echo "--> Generating AppRun script..."
cat <<'EOF' > "$APP_DIR/AppRun"
#!/bin/sh
HERE="$(dirname "$(readlink -f "${0}")")"
export POIETIC_RESOURCES_PATH="${HERE}/usr/share/poietic-playground"
export PATH="${HERE}/usr/bin:${PATH}"
exec "${HERE}/usr/bin/PoieticPlayground" "$@"
EOF
chmod +x "$APP_DIR/AppRun"

echo ""
if command -v appimagetool >/dev/null 2>&1; then
    echo "--> Running appimagetool..."
    appimagetool "$APP_DIR" "$OUTPUT_APPIMAGE"
    echo "AppImage created successfully: $OUTPUT_APPIMAGE"
else
    echo "AppDir directory prepared successfully at: $APP_DIR"
    echo "To produce the final AppImage, run:"
    echo "  appimagetool $APP_DIR $OUTPUT_APPIMAGE"
fi

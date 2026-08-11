#!/usr/bin/env sh
set -e

# Poietic Playground - Linux Installation Script

SHOW_HELP=0
UNINSTALL=0
PREFIX=""
USER_INSTALL=0

usage() {
    cat <<EOF
Poietic Playground Installation Script

Usage:
  ./install.sh [OPTIONS]

Options:
  --prefix DIR    Set installation prefix directory (default: /usr/local or ~/.local)
  --user          Install for current user only (~/.local)
  --system        Install system-wide (/usr/local)
  --uninstall     Uninstall Poietic Playground from prefix directory
  -h, --help      Display this help message

Environment Variables:
  PREFIX          Alternative way to specify installation prefix
EOF
}

while [ "$#" -gt 0 ]; do
    case "$1" in
        --prefix)
            PREFIX="$2"
            shift 2
            ;;
        --user)
            USER_INSTALL=1
            shift
            ;;
        --system)
            USER_INSTALL=0
            PREFIX="/usr/local"
            shift
            ;;
        --uninstall)
            UNINSTALL=1
            shift
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

# Determine default prefix if not explicitly specified
if [ -z "$PREFIX" ]; then
    if [ "$USER_INSTALL" -eq 1 ]; then
        PREFIX="$HOME/.local"
    elif [ "$(id -u 2>/dev/null || echo 1)" -eq 0 ]; then
        PREFIX="/usr/local"
    else
        PREFIX="$HOME/.local"
    fi
fi

BIN_DIR="$PREFIX/bin"
SHARE_DIR="$PREFIX/share/poietic-playground"
APP_DIR="$PREFIX/share/applications"
ICON_DIR="$PREFIX/share/icons/hicolor/512x512/apps"

if [ "$UNINSTALL" -eq 1 ]; then
    echo "Uninstalling Poietic Playground from $PREFIX..."
    rm -f "$BIN_DIR/PoieticPlayground"
    rm -rf "$SHARE_DIR"
    rm -f "$APP_DIR/poietic-playground.desktop"
    rm -f "$ICON_DIR/poietic-playground.png"
    echo "Uninstallation complete."
    exit 0
fi

echo "=========================================="
echo "Installing Poietic Playground"
echo "Prefix: $PREFIX"
echo "=========================================="

# Check for Swift compiler
if ! command -v swift >/dev/null 2>&1; then
    echo "Error: 'swift' compiler not found. Please install Swift (https://swift.org/getting-started/)."
    exit 1
fi

echo "--> Building release binary..."
swift build -c release

SWIFT_BIN_PATH=$(swift build -c release --show-bin-path)
BUILD_EXEC="$SWIFT_BIN_PATH/PoieticPlayground"

if [ ! -f "$BUILD_EXEC" ]; then
    echo "Error: Built executable not found at $BUILD_EXEC"
    exit 1
fi

echo "--> Creating target directories..."
mkdir -p "$BIN_DIR"
mkdir -p "$SHARE_DIR"
mkdir -p "$APP_DIR"
mkdir -p "$ICON_DIR"

echo "--> Copying binary to $BIN_DIR..."
cp -f "$BUILD_EXEC" "$BIN_DIR/PoieticPlayground"
chmod +x "$BIN_DIR/PoieticPlayground"

echo "--> Copying resources to $SHARE_DIR..."
cp -r Sources/PoieticPlayground/Resources/* "$SHARE_DIR/"

echo "--> Installing desktop launcher..."
if [ -f "poietic-playground.desktop" ]; then
    cp -f "poietic-playground.desktop" "$APP_DIR/"
fi

# Copy icon if available
ICON_SRC="Sources/PoieticPlayground/Resources/icons/black/run.png"
if [ -f "$ICON_SRC" ]; then
    cp -f "$ICON_SRC" "$ICON_DIR/poietic-playground.png"
fi

# Update system caches if tools are available
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database "$APP_DIR" >/dev/null 2>&1 || true
fi
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache "$PREFIX/share/icons/hicolor" >/dev/null 2>&1 || true
fi

echo ""
echo "=========================================="
echo "Installation complete!"
echo "Binary:    $BIN_DIR/PoieticPlayground"
echo "Resources: $SHARE_DIR"
echo "Desktop:   $APP_DIR/poietic-playground.desktop"
echo "=========================================="
echo "Ensure '$BIN_DIR' is in your PATH to launch PoieticPlayground from anywhere."

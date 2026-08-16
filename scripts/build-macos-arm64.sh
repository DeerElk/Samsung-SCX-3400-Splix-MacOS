#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SPLIX_DIR="$REPO_DIR/source/splix-2.0.2"
JBIG_DIR="$REPO_DIR/source/jbigkit-2.1/libjbig"
DRIVER_DIR="$REPO_DIR/driver"

echo "==> Checking platform..."

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "Error: macOS is required."
    exit 1
fi

if [[ "$(uname -m)" != "arm64" ]]; then
    echo "Error: this build targets Apple Silicon (arm64)."
    echo "Current architecture: $(uname -m)"
    exit 1
fi

if ! command -v xcrun >/dev/null 2>&1; then
    echo "Error: Xcode Command Line Tools are required."
    echo "Install them with:"
    echo "  xcode-select --install"
    exit 1
fi

if [[ ! -d "$SPLIX_DIR" ]]; then
    echo "Error: SpliX source tree not found:"
    echo "  $SPLIX_DIR"
    exit 1
fi

if [[ ! -d "$JBIG_DIR" ]]; then
    echo "Error: JBIG-KIT source tree not found:"
    echo "  $JBIG_DIR"
    exit 1
fi

SDK="$(xcrun --show-sdk-path)"
CLANG="$(xcrun --find clang)"
CLANGXX="$(xcrun --find clang++)"

echo "==> macOS SDK: $SDK"
echo "==> C compiler: $CLANG"
echo "==> C++ compiler: $CLANGXX"
echo "==> Architecture: arm64"

#
# --------------------------------------------------------------------------
# Build JBIG-KIT
# --------------------------------------------------------------------------
#

echo
echo "==> Building JBIG-KIT 2.1..."

make -C "$JBIG_DIR" clean

rm -f \
    "$JBIG_DIR/libjbig.a" \
    "$JBIG_DIR/libjbig85.a"

make -C "$JBIG_DIR" \
    CC="$CLANG" \
    CFLAGS="-O2 -arch arm64 -isysroot $SDK"

if [[ ! -f "$JBIG_DIR/libjbig85.a" ]]; then
    echo "Error: libjbig85.a was not built."
    exit 1
fi

echo "==> JBIG-KIT built successfully:"
echo "    $JBIG_DIR/libjbig85.a"

#
# --------------------------------------------------------------------------
# Build SpliX
# --------------------------------------------------------------------------
#

echo
echo "==> Building SpliX 2.0.2..."

cd "$SPLIX_DIR"

make clean || true

make \
    CC="$CLANG" \
    CXX="$CLANGXX" \
    JBIG_DIR="$JBIG_DIR" \
    LDFLAGS="-arch arm64 -isysroot $SDK"

if [[ ! -f "$SPLIX_DIR/optimized/rastertoqpdl" ]]; then
    echo "Error: rastertoqpdl was not built."
    exit 1
fi

#
# --------------------------------------------------------------------------
# Copy resulting driver
# --------------------------------------------------------------------------
#

echo
echo "==> Copying driver..."

mkdir -p "$DRIVER_DIR"

cp \
    "$SPLIX_DIR/optimized/rastertoqpdl" \
    "$DRIVER_DIR/rastertoqpdl"

chmod 755 "$DRIVER_DIR/rastertoqpdl"

echo
echo "==> Stripping debug information from driver..."
strip -S "$REPO_DIR/driver/rastertoqpdl"

echo "==> Removing build artifacts..."
rm -rf "$SPLIX_DIR/optimized"

find "$JBIG_DIR" \
  -type f \
  \( -name '*.o' -o -name '*.a' -o -name 'tstcodec' -o -name 'tstcodec85' \) \
  -delete

#
# --------------------------------------------------------------------------
# Verify
# --------------------------------------------------------------------------
#

echo
echo "==> Verifying driver..."

file "$DRIVER_DIR/rastertoqpdl"

echo
echo "==> Linked libraries:"
otool -L "$DRIVER_DIR/rastertoqpdl"

echo
echo "==> JBIG symbols:"
if nm "$DRIVER_DIR/rastertoqpdl" | grep -E 'jbg85_(enc|dec)' | head -20; then
    echo
    echo "JBIG-KIT symbols are embedded in rastertoqpdl."
else
    echo
    echo "WARNING: JBIG symbols were not found."
    exit 1
fi

echo
echo "==> Build completed successfully."
echo
echo "Driver:"
echo "  $DRIVER_DIR/rastertoqpdl"
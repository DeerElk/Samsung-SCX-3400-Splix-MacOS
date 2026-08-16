#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DRIVER="$REPO_DIR/driver/rastertoqpdl"
PPD="$REPO_DIR/driver/scx3400.ppd"

FILTER_DIR="/usr/libexec/cups/filter"
PPD_DIR="/Library/Printers/PPDs/Contents/Resources"

PRINTER_NAME="Samsung_SCX_3400_Series"

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "Error: this installer is for macOS only."
    exit 1
fi

if [[ "$(uname -m)" != "arm64" ]]; then
    echo "Error: this driver is built for Apple Silicon (arm64)."
    echo "Current architecture: $(uname -m)"
    exit 1
fi

if [[ ! -f "$DRIVER" ]]; then
    echo "Error: driver not found:"
    echo "  $DRIVER"
    exit 1
fi

if [[ ! -f "$PPD" ]]; then
    echo "Error: PPD not found:"
    echo "  $PPD"
    exit 1
fi

echo "==> Installing SpliX filter..."
sudo install -m 755 "$DRIVER" \
    "$FILTER_DIR/rastertoqpdl"

echo "==> Installing SCX-3400 PPD..."
sudo mkdir -p "$PPD_DIR"

sudo install -m 644 "$PPD" \
    "$PPD_DIR/Samsung_SCX-3400.ppd"

echo
echo "Driver files installed successfully."
echo

# Find an already existing SCX-3400 queue.
EXISTING_QUEUE="$(
    lpstat -v 2>/dev/null |
    awk '
        /SCX-3400/ {
            line=$0
            sub(/^device for /, "", line)
            sub(/:.*/, "", line)
            print line
            exit
        }
    '
)"

if [[ -n "${EXISTING_QUEUE:-}" ]]; then
    echo "==> Existing SCX-3400 queue found: $EXISTING_QUEUE"
    echo "Updating its PPD..."
    
    sudo lpadmin \
        -p "$EXISTING_QUEUE" \
        -E \
        -P "$PPD"

    echo
    echo "Existing queue was updated."
    exit 0
fi

# Find a real USB SCX-3400 URI reported by this Mac.
DEVICE_URI="$(
    lpinfo -v 2>/dev/null |
    awk '
        /usb:\/\// && /SCX-3400/ {
            print $2
            exit
        }
    '
)"

if [[ -z "${DEVICE_URI:-}" ]]; then
    echo "No Samsung SCX-3400 USB printer was detected."
    echo
    echo "The driver and PPD are installed."
    echo
    echo "Connect the printer and run:"
    echo
    echo "  lpinfo -v | grep -i SCX-3400"
    echo
    echo "Then create the queue with the URI reported by macOS."
    exit 0
fi

# Never add the interface parameter.
DEVICE_URI="${DEVICE_URI%%&interface=*}"

echo "==> Detected USB device:"
echo "    $DEVICE_URI"
echo

echo "==> Creating CUPS queue: $PRINTER_NAME"

sudo lpadmin \
    -p "$PRINTER_NAME" \
    -E \
    -v "$DEVICE_URI" \
    -P "$PPD"

echo
echo "Installation completed successfully."
echo
echo "Printer:"
echo "  $PRINTER_NAME"
echo
echo "Device URI:"
echo "  $DEVICE_URI"
echo
echo "Set as default with:"
echo
echo "  lpoptions -d $PRINTER_NAME"

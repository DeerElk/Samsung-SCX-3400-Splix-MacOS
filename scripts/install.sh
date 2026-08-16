#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

DRIVER="$REPO_DIR/driver/rastertoqpdl"
PPD="$REPO_DIR/driver/scx3400.ppd"

FILTER_DIR="/usr/libexec/cups/filter"
PPD_DIR="/Library/Printers/PPDs/Contents/Resources"

PRINTER_NAME="Samsung_SCX_3400_Series"

DRY_RUN=0
NO_QUEUE=0

usage() {
    cat <<EOF
Usage:
  $(basename "$0") [OPTIONS]

Options:
  --dry-run    Show what would be done without changing the system
  --no-queue   Install driver and PPD, but do not create or modify a CUPS queue
  -h, --help   Show this help

Examples:
  $(basename "$0")
  $(basename "$0") --dry-run
  $(basename "$0") --no-queue
  $(basename "$0") --dry-run --no-queue
EOF
}

for arg in "$@"; do
    case "$arg" in
        --dry-run)
            DRY_RUN=1
            ;;
        --no-queue)
            NO_QUEUE=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Error: unknown option: $arg"
            echo
            usage
            exit 1
            ;;
    esac
done

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

if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "==> DRY RUN"
    echo "No changes will be made to the system."
    echo
fi

echo "==> Driver:"
echo "    $DRIVER"
echo
echo "==> PPD:"
echo "    $PPD"
echo

# ------------------------------------------------------------
# Install driver and PPD
# ------------------------------------------------------------

if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "==> Would install SpliX filter:"
    echo "    $FILTER_DIR/rastertoqpdl"
    echo

    echo "==> Would install SCX-3400 PPD:"
    echo "    $PPD_DIR/Samsung_SCX-3400.ppd"
    echo
else
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
fi

# ------------------------------------------------------------
# --no-queue
# ------------------------------------------------------------

if [[ "$NO_QUEUE" -eq 1 ]]; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "==> --no-queue"
        echo "Would not create or modify any CUPS queue."
    else
        echo "==> --no-queue"
        echo "CUPS queue was not created or modified."
    fi

    echo
    echo "Installation completed."
    echo
    exit 0
fi

# ------------------------------------------------------------
# Find an already existing SCX-3400 queue.
# ------------------------------------------------------------

EXISTING_QUEUE="$(
    LC_ALL=C lpstat -v 2>/dev/null |
    awk -F': ' '
        /SCX-3400/ {
            queue=$1
            sub(/^device for /, "", queue)
            print queue
            exit
        }
    ' || true
)"

if [[ -n "${EXISTING_QUEUE:-}" ]]; then
    echo "==> Existing SCX-3400 queue found: $EXISTING_QUEUE"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "Would update its PPD:"
        echo "  sudo lpadmin -p \"$EXISTING_QUEUE\" -E -P \"$PPD\""
        echo
        echo "Dry run completed."
        exit 0
    fi

    echo "Updating its PPD..."

    sudo lpadmin \
        -p "$EXISTING_QUEUE" \
        -E \
        -P "$PPD"

    echo
    echo "Existing queue was updated."
    exit 0
fi

# ------------------------------------------------------------
# Find a real USB SCX-3400 URI reported by macOS.
# ------------------------------------------------------------

DEVICE_URI="$(
    LC_ALL=C lpinfo -v 2>/dev/null |
    awk '
        /usb:\/\// && /SCX-3400/ {
            print $2
            exit
        }
    ' || true
)"

if [[ -z "${DEVICE_URI:-}" ]]; then
    echo "No Samsung SCX-3400 USB printer was detected."
    echo

    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "Dry run completed."
        echo
        echo "If the printer is connected, you can check its URI with:"
        echo
        echo "  lpinfo -v | grep -i SCX-3400"
        echo
    else
        echo "The driver and PPD are installed."
        echo
        echo "Connect the printer and run:"
        echo
        echo "  lpinfo -v | grep -i SCX-3400"
        echo
        echo "Then create the queue with the URI reported by macOS."
    fi

    exit 0
fi

# Never add the interface parameter.
DEVICE_URI="${DEVICE_URI%%&interface=*}"

echo "==> Detected USB device:"
echo "    $DEVICE_URI"
echo

if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "==> Would create CUPS queue:"
    echo "    $PRINTER_NAME"
    echo
    echo "Command:"
    echo
    echo "  sudo lpadmin \\"
    echo "      -p \"$PRINTER_NAME\" \\"
    echo "      -E \\"
    echo "      -v \"$DEVICE_URI\" \\"
    echo "      -P \"$PPD\""
    echo
    echo "Dry run completed."
    exit 0
fi

# ------------------------------------------------------------
# Create CUPS queue.
# ------------------------------------------------------------

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
#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

PRINTER_NAME="Samsung_SCX_3400_Series"

echo "==> Removing SpliX filter..."
sudo rm -f /usr/libexec/cups/filter/rastertoqpdl

echo "==> Removing SCX-3400 PPD..."
sudo rm -f \
  "/Library/Printers/PPDs/Contents/Resources/Samsung_SCX-3400.ppd"

echo "==> Removing repository-created CUPS queue if present..."
sudo lpadmin -x "$PRINTER_NAME" 2>/dev/null || true

echo
echo "Uninstallation completed."
echo
echo "Note: automatically-created queues with different names were not removed."

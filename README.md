# Samsung SCX-3400 SpliX Driver for macOS

Working SpliX driver for **Samsung SCX-3400 Series** printers on macOS with Apple Silicon.

The repository contains:

- a tested arm64 `rastertoqpdl` CUPS filter;
- a working SCX-3400 PPD;
- SpliX 2.0.2 source code;
- JBIG-KIT 2.1 source code;
- macOS build and installation scripts.

## Tested

- macOS 26.6
- Apple Silicon / arm64
- Samsung SCX-3400 Series
- USB
- CUPS
- SpliX 2.0.2
- JBIG-KIT 2.1
- QPDL v3
- 600 DPI

## Quick installation

Clone the repository:

```bash
git clone https://github.com/DeerElk/Samsung-SCX-3400-Splix-MacOS.git
cd Samsung-SCX-3400-Splix-MacOS
```

Connect the printer and run:
```bash
./scripts/install.sh
```

The installer automatically detects the Samsung SCX-3400 USB device reported by the current Mac.

## If the printer is not connected

The installer still installs the driver and PPD.
Connect the printer afterwards and inspect the detected USB URI:

```bash
lpinfo -v | grep -i SCX-3400
```

Then create the queue manually if necessary:

```bash
sudo lpadmin \
  -p Samsung_SCX_3400_Series \
  -E \
  -v 'PASTE_THE_URI_REPORTED_BY_MACOS_HERE' \
  -P ./driver/scx3400.ppd
```

## Test printing

```bash
lpoptions -d Samsung_SCX_3400_Series
```

Then:

```bash
lp -d Samsung_SCX_3400_Series ~/Desktop/test.jpg
```
or:

```bash
lp -d Samsung_SCX_3400_Series ~/Desktop/test.pdf
```

## Building from source

On Apple Silicon macOS:

```bash
./scripts/build-macos-arm64.sh
```

The build uses the included SpliX and JBIG-KIT source trees.

## Installed files

The installer installs:

```
/usr/libexec/cups/filter/rastertoqpdl
/Library/Printers/PPDs/Contents/Resources/Samsung_SCX-3400.ppd
```

## Uninstall

```bash
./scripts/uninstall.sh
```

## Troubleshooting

Check the driver:

```bash
file /usr/libexec/cups/filter/rastertoqpdl
```

Expected:

```
Mach-O 64-bit executable arm64
```

Check the printer:

```bash
lpstat -v
lpstat -p
```

Check CUPS logs:

```bash
sudo tail -100 /var/log/cups/error_log
```

## License

SpliX is distributed under the GNU General Public License, version 2.
See `LICENSE`, `NOTICE.md`, and the original component source trees for complete licensing and attribution information.

## Disclaimer

This is an unofficial community driver.
It is not affiliated with Samsung, Apple, HP, or OpenPrinting.
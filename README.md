# Samsung SCX-3405W SpliX Driver for macOS

Unofficial SpliX-based CUPS driver for **Samsung SCX-3405W** on modern macOS with Apple Silicon.

The driver was successfully tested with a **Samsung SCX-3405W** connected via USB.

> 🇷🇺 RU version: [README.ru.md](README.ru.md)

## Features

The repository contains:

- a tested arm64 `rastertoqpdl` CUPS filter;
- a working SCX-3400 PPD;
- SpliX 2.0.2 source code;
- JBIG-KIT 2.1 source code;
- macOS Apple Silicon build scripts;
- an installation script with automatic USB printer detection;
- a safe uninstall script;
- `--dry-run` and `--no-queue` installation modes.

## Tested

- **Printer:** Samsung SCX-3405W
- **macOS:** 26.6
- **Architecture:** Apple Silicon / arm64
- **Connection:** USB
- **Print system:** CUPS
- **Driver:** SpliX 2.0.2
- **Compression:** JBIG-KIT 2.1
- **Printer language:** QPDL v3
- **Resolution:** 600 DPI

The printer is reported by macOS/CUPS as:

```text
Samsung SCX-3400 Series
```

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

The installer automatically detects the Samsung SCX-3400 USB device reported by macOS and creates a CUPS queue using the included PPD.

### Dry run

To see what the installer would do without modifying the system:

```bash
./scripts/install.sh --dry-run
```

### Install only the driver

To install the driver and PPD without creating or modifying a CUPS queue:

```bash
./scripts/install.sh --no-queue
```

You can also combine the options:

```bash
./scripts/install.sh --dry-run --no-queue
```

## If the printer is not connected

The installer still installs the driver and PPD.

Connect the printer afterwards and check whether macOS detects it:

```bash
lpinfo -v | grep -i SCX-3400
```

A working USB connection should look similar to:

```text
direct usb://Samsung/SCX-3400%20Series?serial=XXXXXXXX
```

You can then create the queue manually:

```bash
sudo lpadmin   -p Samsung_SCX_3400_Series   -E   -v 'PASTE_THE_URI_REPORTED_BY_MACOS_HERE'   -P ./driver/scx3400.ppd
```

## Test printing

Set the printer as the default:

```bash
lpoptions -d Samsung_SCX_3400_Series
```

Print a test document:

```bash
lp -d Samsung_SCX_3400_Series ~/Desktop/test.pdf
```

or:

```bash
lp -d Samsung_SCX_3400_Series ~/Desktop/test.jpg
```

Check the queue:

```bash
lpstat -p
lpstat -v
```

## Building from source

On Apple Silicon macOS:

```bash
./scripts/build-macos-arm64.sh
```

The build uses the included SpliX 2.0.2 and JBIG-KIT 2.1 source trees.

The resulting driver is:

```text
driver/rastertoqpdl
```

The build script also verifies that the resulting executable is an Apple Silicon arm64 Mach-O binary and that the JBIG symbols are embedded into the driver.

## Installed files

The installer installs:

```text
/usr/libexec/cups/filter/rastertoqpdl
/Library/Printers/PPDs/Contents/Resources/Samsung_SCX-3400.ppd
```

The CUPS queue itself is created separately by `lpadmin`.

## Uninstall

To remove the installed driver and PPD:

```bash
./scripts/uninstall.sh
```

If you also want to remove the CUPS printer queue, remove it separately:

```bash
sudo lpadmin -x Samsung_SCX_3400_Series
```

Replace the queue name if you created it under a different name.

## Troubleshooting

### Check the driver architecture

```bash
file /usr/libexec/cups/filter/rastertoqpdl
```

Expected:

```text
Mach-O 64-bit executable arm64
```

### Check the installed PPD

```bash
ls -l /Library/Printers/PPDs/Contents/Resources/Samsung_SCX-3400.ppd
```

### Check the printer

```bash
lpstat -v
lpstat -p
```

### Check USB device detection

```bash
lpinfo -v | grep -i SCX-3400
```

### Check CUPS logs

```bash
sudo tail -100 /var/log/cups/error_log
```

## Supported printers

### Confirmed

- **Samsung SCX-3405W** — tested and working on Apple Silicon macOS via USB.

The printer identifies itself to macOS/CUPS as **Samsung SCX-3400 Series**.

Other printers may be compatible with SpliX 2.0.2, but they have not been tested as part of this project.

## Credits and licensing

This project is based on existing open-source software, including:

- **SpliX 2.0.2**
- **JBIG-KIT 2.1**

The original components remain subject to their respective licenses and copyright notices.

See:

- `LICENSE`
- `NOTICE.md`
- `source/splix-2.0.2/`
- `source/jbigkit-2.1/`

for licensing, attribution, and original source information.

## Disclaimer

This is an unofficial community driver.

It is not affiliated with Samsung, Apple, HP, OpenPrinting, or their respective subsidiaries and partners.

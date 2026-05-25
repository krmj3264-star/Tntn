# Tntn Binary System - Complete Guide

## 📦 Complete Bin Directory Structure

```
bin/
├── build.sh                 # Linux/Mac build system (MAIN)
├── build.bat               # Windows build system (MAIN)
├── BUILD_FIRMWARE.sh       # Simple Linux/Mac builder
├── BUILD_FIRMWARE.bat      # Simple Windows builder
├── QUICK_BUILD.md          # Quick start guide
├── README.md              # This file
└── flash_instructions.txt  # Flashing guide
```

---

## 🚀 Quick Start

### Linux/Mac:
```bash
chmod +x bin/build.sh
./bin/build.sh              # Build
./bin/build.sh clean        # Clean build files
./bin/build.sh flash        # Show flash commands
```

### Windows:
```batch
bin\build.bat              # Build
bin\build.bat clean        # Clean build files
bin\build.bat flash        # Show flash commands
```

---

## 📋 Available Commands

### Build Firmware
Compiles the complete firmware for ESP32-S3

**Linux/Mac:**
```bash
./bin/build.sh build
```

**Windows:**
```batch
bin\build.bat build
```

**Output:**
- `build_output/firmware_v1.0.0.bin` - Ready to flash
- `build_output/firmware_v1.0.0.elf` - Debug symbols

---

### Clean Build Files
Removes all build artifacts

**Linux/Mac:**
```bash
./bin/build.sh clean
```

**Windows:**
```batch
bin\build.bat clean
```

---

### Flash Firmware
Display flashing instructions for your platform

**Linux/Mac:**
```bash
./bin/build.sh flash
```

**Windows:**
```batch
bin\build.bat flash
```

---

## 🔧 System Requirements

- **Python 3.x** - Programming language
- **PlatformIO CLI** - Embedded development platform
  ```bash
  pip install platformio
  ```
- **esptool.py** - ESP32 flashing tool
  ```bash
  pip install esptool
  ```
- **USB Cable** - For ESP32-S3 device connection

---

## 📝 Installation Steps

### 1. Install Python Dependencies
```bash
pip install platformio esptool
```

### 2. Build Firmware
```bash
# Linux/Mac
chmod +x bin/build.sh
./bin/build.sh

# Windows
bin\build.bat
```

### 3. Flash to Device

**Linux/Mac:**
```bash
esptool.py --chip esp32s3 --port /dev/ttyUSB0 --baud 921600 \
  write_flash -z 0x0 build_output/firmware_v1.0.0.bin
```

**Windows:**
```batch
esptool.py --chip esp32s3 --port COM3 --baud 921600 ^
  write_flash -z 0x0 build_output\firmware_v1.0.0.bin
```

> **Replace `/dev/ttyUSB0` or `COM3` with your actual serial port**

---

## 🔍 Finding Your Serial Port

### Linux
```bash
ls /dev/tty*
# Look for /dev/ttyUSB0, /dev/ttyUSB1, /dev/ttyACM0, etc.
```

### Windows
```batch
mode
# or use Device Manager to find COMx ports
```

### macOS
```bash
ls /dev/tty.*
# Look for /dev/tty.usbserial-*, /dev/tty.usbmodem*, etc.
```

---

## 📊 Build System Features

✅ **Automatic Dependency Checking**
- Verifies Python and PlatformIO installation
- Auto-installs missing dependencies

✅ **Build Information**
- Displays board target
- Shows firmware version
- Reports binary size

✅ **Output Organization**
- Generates timestamped binaries
- Keeps build artifacts organized
- Easy access to all versions

✅ **Platform Support**
- Linux/Mac (bash script)
- Windows (batch script)
- Cross-platform compatible

---

## 🐛 Troubleshooting

### "PlatformIO not found"
```bash
pip install platformio
```

### "Port already in use"
- Close serial monitor or IDE
- Unplug and replug USB cable
- Try different USB port

### "Build failed"
```bash
# Clean and rebuild
./bin/build.sh clean
./bin/build.sh build
```

### "Python not found"
- Install Python 3.x from https://www.python.org
- Add Python to system PATH

---

## 📂 Output Files

After successful build:

```
build_output/
├── firmware_v1.0.0.bin    # Main firmware binary
└── firmware_v1.0.0.elf    # Debug symbols (optional)
```

---

## 🔄 Version Management

Binaries are automatically versioned:
- v1.0.0 (current)
- v1.0.1 (future updates)
- etc.

Old versions are preserved in `build_output/`

---

## 📚 Related Files

- **BUILD.md** - Basic build configuration
- **QUICK_BUILD.md** - Quick start guide
- **RELEASE_NOTES.md** - Release information
- **README.md** - Project overview

---

## 💡 Pro Tips

1. **Keep multiple versions:**
   - Each build creates a timestamped binary
   - Easy to revert to previous versions

2. **Batch flashing:**
   - Use multiple USB ports to flash multiple boards
   - Each port gets its own esptool command

3. **Debug builds:**
   - Use `.elf` file with debugger for advanced debugging
   - BinSize helps optimize firmware

---

## 🤝 Support

For issues or questions:
1. Check BUILD.md for basic instructions
2. Review QUICK_BUILD.md for common issues
3. Open GitHub issue: https://github.com/krmj3264-star/Tntn/issues

---

## 📄 License

See LICENSE file in repository root

---

**Last Updated:** May 25, 2026
**Version:** 1.0.0
**Status:** Stable

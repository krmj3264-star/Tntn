## Tntn Firmware Release v1.0.0

**Release Date:** May 25, 2026

### 📋 Overview
Initial stable release of Tntn firmware for ESP32-S3 LilyGO T-HMI board.

### ✨ Features
- ✅ ESP32-S3 LilyGO T-HMI support
- ✅ TFT_eSPI display driver
- ✅ WiFi connectivity
- ✅ WebServer capability
- ✅ TOTP authentication support
- ✅ DNS Server
- ✅ Non-volatile storage (Preferences)

### 📦 What's Included
- **firmware.bin** - Main firmware binary (ready to flash)
- **firmware.elf** - Debug symbols
- **partitions.bin** - Flash partition table

### 🚀 Installation

#### Prerequisites
- Python 3.x
- PlatformIO CLI: `pip install platformio`
- esptool.py: `pip install esptool`
- USB Cable for ESP32-S3

#### Flash to Device

**Windows:**
```bash
esptool.py --chip esp32s3 --port COM3 --baud 921600 write_flash -z 0x0 firmware.bin
```

**Linux:**
```bash
esptool.py --chip esp32s3 --port /dev/ttyUSB0 --baud 921600 write_flash -z 0x0 firmware.bin
```

**macOS:**
```bash
esptool.py --chip esp32s3 --port /dev/ttyACM0 --baud 921600 write_flash -z 0x0 firmware.bin
```

> **Note:** Replace COM3 with your actual serial port

### 🔧 Build from Source

```bash
# Clone repository
git clone https://github.com/krmj3264-star/Tntn.git
cd Tntn

# Windows
bin\BUILD_FIRMWARE.bat

# Linux/Mac
chmod +x bin/BUILD_FIRMWARE.sh
./bin/BUILD_FIRMWARE.sh
```

### 📝 Release Notes

#### Version 1.0.0
- Initial stable release
- Full ESP32-S3 support
- All core libraries integrated
- Documentation complete
- Build scripts for all platforms

### 🐛 Known Issues
None reported

### 📚 Documentation
- See [BUILD.md](../BUILD.md) for detailed build instructions
- See [README.md](../README.md) for project overview
- See [bin/QUICK_BUILD.md](../bin/QUICK_BUILD.md) for quick start

### 💪 System Requirements
- **Board:** ESP32-S3 DevKit-C-1 (or LilyGO T-HMI variant)
- **RAM:** 8MB PSRAM
- **Flash:** 8MB+
- **USB:** For programming

### 📞 Support
For issues or questions, please open an issue on GitHub:
https://github.com/krmj3264-star/Tntn/issues

### 📄 License
See LICENSE file for details

---

**Release Checksum:**
- firmware.bin: See Assets

**Download:** Available in the Assets section below

Happy coding! 🎉

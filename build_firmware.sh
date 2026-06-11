#!/bin/bash

# Tntn Firmware Build Script - Complete Build System
# Builds firmware binary for ESP32-S3 LilyGO T-HMI
# Usage: ./build_firmware.sh [build|clean|flash]

set -e

PROJECT_NAME="Tntn"
DEVICE="lilygo-t-hmi"
CHIP="esp32s3"
BAUD="921600"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check dependencies
check_dependencies() {
    print_info "Checking dependencies..."
    
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 not found. Install Python 3.x"
        exit 1
    fi
    
    if ! command -v pio &> /dev/null; then
        print_warning "PlatformIO CLI not found. Installing..."
        pip install platformio
    fi
    
    if ! pip list | grep -q esptool; then
        print_warning "esptool not found. Installing..."
        pip install esptool
    fi
    
    print_success "All dependencies available"
}

# Build firmware
build_firmware() {
    print_header "Building $PROJECT_NAME Firmware"
    
    check_dependencies
    
    print_info "Building for board: $DEVICE"
    print_info "Target chip: $CHIP"
    
    mkdir -p build_output
    
    # Run PlatformIO build
    print_info "Running PlatformIO build..."
    pio run --environment "$DEVICE"
    
    # Copy output files
    if [ -f ".pio/build/$DEVICE/firmware.bin" ]; then
        cp ".pio/build/$DEVICE/firmware.bin" build_output/firmware.bin
        print_success "Firmware binary copied to build_output/firmware.bin"
    else
        print_error "Firmware binary not found!"
        exit 1
    fi
    
    if [ -f ".pio/build/$DEVICE/firmware.elf" ]; then
        cp ".pio/build/$DEVICE/firmware.elf" build_output/firmware.elf
        print_info "Debug symbols copied to build_output/firmware.elf"
    fi
    
    # Get file info
    SIZE=$(stat -c%s build_output/firmware.bin 2>/dev/null || stat -f%z build_output/firmware.bin)
    TIMESTAMP=$(date -u +'%Y-%m-%d %H:%M:%S UTC')
    
    print_success "Build completed successfully!"
    print_info "Binary size: $(numfmt --to=iec $SIZE 2>/dev/null || echo $SIZE bytes)"
    print_info "Build time: $TIMESTAMP"
    
    # Create build info file
    cat > build_output/BUILD_INFO.txt << EOF
$PROJECT_NAME Firmware Build Information
========================================

Build Time: $TIMESTAMP
Binary Size: $SIZE bytes
Binary Location: build_output/firmware.bin

Platform: $CHIP
Device: $DEVICE
Framework: Arduino

Flash Command:
esptool.py --chip $CHIP --port COM3 --baud $BAUD write_flash -z 0x0 firmware.bin

For Linux/Mac, replace COM3 with /dev/ttyUSB0 or /dev/tty.usbserial-*

Documentation: See README.md for detailed instructions
EOF
    
    print_success "Build info saved to build_output/BUILD_INFO.txt"
}

# Clean build files
clean_build() {
    print_header "Cleaning Build Files"
    
    if [ -d ".pio" ]; then
        rm -rf .pio
        print_success "Removed .pio directory"
    fi
    
    if [ -d "build_output" ]; then
        rm -rf build_output
        print_success "Removed build_output directory"
    fi
    
    print_success "Clean completed"
}

# Show flash instructions
show_flash_instructions() {
    print_header "Flash Instructions"
    
    if [ ! -f "build_output/firmware.bin" ]; then
        print_error "Firmware binary not found. Run './build_firmware.sh build' first"
        exit 1
    fi
    
    SIZE=$(stat -c%s build_output/firmware.bin 2>/dev/null || stat -f%z build_output/firmware.bin)
    
    cat << EOF
${GREEN}ESP32-S3 Firmware Flash Guide${NC}

Binary File: build_output/firmware.bin
Binary Size: $SIZE bytes

${YELLOW}Prerequisites:${NC}
1. Install esptool: pip install esptool
2. Connect ESP32-S3 via USB cable
3. Find your serial port:
   - Windows: Check Device Manager (COMx)
   - Linux: ls /dev/ttyUSB* or /dev/ttyACM*
   - macOS: ls /dev/tty.usbserial-* or /dev/tty.usbmodem*

${YELLOW}Flash Command:${NC}

esptool.py --chip $CHIP --port <PORT> --baud $BAUD write_flash -z 0x0 build_output/firmware.bin

${YELLOW}Examples:${NC}

Windows:
esptool.py --chip $CHIP --port COM3 --baud $BAUD write_flash -z 0x0 build_output/firmware.bin

Linux:
esptool.py --chip $CHIP --port /dev/ttyUSB0 --baud $BAUD write_flash -z 0x0 build_output/firmware.bin

macOS:
esptool.py --chip $CHIP --port /dev/tty.usbserial-0 --baud $BAUD write_flash -z 0x0 build_output/firmware.bin

${YELLOW}Optional - Erase Flash Before Flash:${NC}
esptool.py --chip $CHIP --port <PORT> erase_flash

${YELLOW}Monitor Serial Output:${NC}
After flashing, monitor the device:
esptool.py --chip $CHIP --port <PORT> --baud 115200 read_flash_status

EOF
}

# Main
case "${1:-build}" in
    build)
        build_firmware
        ;;
    clean)
        clean_build
        ;;
    flash)
        show_flash_instructions
        ;;
    *)
        echo "Usage: $0 [build|clean|flash]"
        echo ""
        echo "Commands:"
        echo "  build  - Build firmware binary (default)"
        echo "  clean  - Clean build artifacts"
        echo "  flash  - Show flashing instructions"
        exit 1
        ;;
esac

print_success "Done!"

#!/bin/bash
# Tntn Complete Build System
# Complete firmware build and management script

set -e

VERSION="1.0.0"
PROJECT_NAME="Tntn"
BOARD="lilygo-t-hmi"
BUILD_DIR=".pio/build/${BOARD}"
FIRMWARE_BIN="${BUILD_DIR}/firmware.bin"
FIRMWARE_ELF="${BUILD_DIR}/firmware.elf"
OUTPUT_DIR="build_output"

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
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ️  $1${NC}"
}

check_dependencies() {
    print_header "Checking Dependencies"
    
    if ! command -v pio &> /dev/null; then
        print_info "PlatformIO CLI not found. Installing..."
        pip install platformio
    else
        print_success "PlatformIO is installed"
    fi
    
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is required but not installed"
        exit 1
    fi
    print_success "Python 3 is installed"
}

build_firmware() {
    print_header "Building Firmware"
    print_info "Target: ${BOARD}"
    print_info "Version: ${VERSION}"
    
    pio run --environment ${BOARD} --verbose
    
    if [ -f "$FIRMWARE_BIN" ]; then
        print_success "Firmware built successfully"
        print_info "Binary: ${FIRMWARE_BIN}"
    else
        print_error "Build failed - firmware.bin not found"
        exit 1
    fi
}

copy_binaries() {
    print_header "Copying Binaries"
    
    mkdir -p ${OUTPUT_DIR}
    
    if [ -f "$FIRMWARE_BIN" ]; then
        cp "$FIRMWARE_BIN" "${OUTPUT_DIR}/firmware_v${VERSION}.bin"
        print_success "Copied: firmware_v${VERSION}.bin"
    fi
    
    if [ -f "$FIRMWARE_ELF" ]; then
        cp "$FIRMWARE_ELF" "${OUTPUT_DIR}/firmware_v${VERSION}.elf"
        print_success "Copied: firmware_v${VERSION}.elf"
    fi
}

show_flash_instructions() {
    print_header "Flashing Instructions"
    
    echo -e "${GREEN}Linux/Mac:${NC}"
    echo "esptool.py --chip esp32s3 --port /dev/ttyUSB0 --baud 921600 write_flash -z 0x0 ${OUTPUT_DIR}/firmware_v${VERSION}.bin"
    echo ""
    echo -e "${GREEN}Windows (PowerShell):${NC}"
    echo "esptool.py --chip esp32s3 --port COM3 --baud 921600 write_flash -z 0x0 ${OUTPUT_DIR}/firmware_v${VERSION}.bin"
    echo ""
    echo -e "${YELLOW}Note: Replace /dev/ttyUSB0 or COM3 with your actual serial port${NC}"
}

show_statistics() {
    print_header "Build Statistics"
    
    if [ -f "$FIRMWARE_BIN" ]; then
        SIZE=$(stat -f%z "$FIRMWARE_BIN" 2>/dev/null || stat -c%s "$FIRMWARE_BIN" 2>/dev/null)
        SIZE_KB=$((SIZE / 1024))
        print_info "Firmware Size: ${SIZE_KB} KB (${SIZE} bytes)"
    fi
}

main() {
    print_header "${PROJECT_NAME} Build System v${VERSION}"
    
    check_dependencies
    build_firmware
    copy_binaries
    show_statistics
    show_flash_instructions
    
    echo ""
    print_success "Build Complete!"
    print_info "Output files in: ${OUTPUT_DIR}/"
}

# Handle arguments
case "${1:-build}" in
    build)
        main
        ;;
    clean)
        print_header "Cleaning Build Files"
        rm -rf .pio build_output
        print_success "Cleaned"
        ;;
    flash)
        print_error "Flash command requires manual port configuration"
        show_flash_instructions
        ;;
    *)
        echo "Usage: $0 {build|clean|flash}"
        echo ""
        echo "Commands:"
        echo "  build  - Build firmware (default)"
        echo "  clean  - Remove build files"
        echo "  flash  - Show flash instructions"
        exit 1
        ;;
esac

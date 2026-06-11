#!/bin/bash

# Dr. Passwords - Complete Build & Flash System
# For LilyGO T-HMI ESP32-S3
# Builds real firmware binary and prepares for flashing

set -e

# Configuration
PROJECT="Dr. Passwords"
DEVICE="lilygo-t-hmi"
CHIP="esp32s3"
BOARD="esp32s3-devkitc-1"
UPLOAD_SPEED="921600"
BAUD_RATE="115200"

# Paths
BUILD_DIR=".pio/build/$DEVICE"
FIRMWARE_SRC="$BUILD_DIR/firmware.bin"
FIRMWARE_DEST="firmware/firmware.bin"
FIRMWARE_ELF="$BUILD_DIR/firmware.elf"
BUILD_OUTPUT="build_output"
BACKUP_DIR="firmware/backups"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ============================================================================
# FUNCTIONS
# ============================================================================

print_header() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║  $1"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}✅  $1${NC}"
}

print_error() {
    echo -e "${RED}❌  $1${NC}"
    exit 1
}

print_warning() {
    echo -e "${YELLOW}⚠️   $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️   $1${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check dependencies
check_dependencies() {
    print_info "🔍 Checking dependencies..."
    
    if ! command_exists python3; then
        print_error "Python 3 not found. Install Python 3.8+"
    fi
    
    if ! command_exists pio; then
        print_warning "PlatformIO CLI not found. Installing..."
        pip install platformio
    fi
    
    if ! pip list | grep -q esptool; then
        print_warning "esptool not found. Installing..."
        pip install esptool
    fi
    
    print_success "All dependencies available"
}

# Create backup of previous firmware
backup_firmware() {
    if [ -f "$FIRMWARE_DEST" ]; then
        print_info "📦 Creating backup..."
        mkdir -p "$BACKUP_DIR"
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        BACKUP_FILE="$BACKUP_DIR/firmware_backup_$TIMESTAMP.bin"
        cp "$FIRMWARE_DEST" "$BACKUP_FILE"
        print_success "Backup saved: $BACKUP_FILE"
    fi
}

# Build firmware
build_firmware() {
    print_header "Building Firmware for $PROJECT"
    
    check_dependencies
    
    print_info "📋 Build Configuration:"
    print_info "   Device: $DEVICE"
    print_info "   Chip: $CHIP (Board: $BOARD)"
    print_info "   Project: $PROJECT"
    echo ""
    
    print_info "🔨 Running PlatformIO build..."
    pio run --environment "$DEVICE" --silent || print_error "Build failed!"
    
    if [ ! -f "$FIRMWARE_SRC" ]; then
        print_error "Firmware binary not found at $FIRMWARE_SRC"
    fi
    
    print_success "Build completed successfully!"
    echo ""
}

# Deploy firmware
deploy_firmware() {
    print_header "Deploying Firmware"
    
    # Create backup
    backup_firmware
    
    # Create output directory
    mkdir -p "$BUILD_OUTPUT"
    mkdir -p "firmware"
    
    # Copy firmware
    print_info "📦 Copying firmware binary..."
    cp "$FIRMWARE_SRC" "$FIRMWARE_DEST"
    cp "$FIRMWARE_SRC" "$BUILD_OUTPUT/firmware_latest.bin"
    
    # Copy ELF if exists
    if [ -f "$FIRMWARE_ELF" ]; then
        cp "$FIRMWARE_ELF" "$BUILD_OUTPUT/firmware_latest.elf"
    fi
    
    print_success "Firmware deployed to $FIRMWARE_DEST"
    echo ""
}

# Generate build info
generate_build_info() {
    print_info "📝 Generating build information..."
    
    BINARY_SIZE=$(stat -f%z "$FIRMWARE_DEST" 2>/dev/null || stat -c%s "$FIRMWARE_DEST")
    BUILD_TIME=$(date -u +'%Y-%m-%d %H:%M:%S UTC')
    GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    
    cat > "firmware/BUILD_INFO.txt" << EOF
═══════════════════════════════════════════════════════════════════
$PROJECT - Firmware Build Information
═══════════════════════════════════════════════════════════════════

📦 BINARY INFORMATION
────────────────────────────────────────────────────────────────────
Binary File:     firmware/firmware.bin
Binary Size:     $BINARY_SIZE bytes
Build Time:      $BUILD_TIME
Build Number:    $(date +%s)

🔧 BUILD CONFIGURATION
────────────────────────────────────────────────────────────────────
Device:          LilyGO T-HMI
Chip:            ESP32-S3 ($BOARD)
Platform:        espressif32
Framework:       Arduino
Upload Speed:    $UPLOAD_SPEED baud

💾 SOURCE INFORMATION
────────────────────────────────────────────────────────────────────
Git Commit:      $GIT_COMMIT
Git Branch:      $GIT_BRANCH

⚡ FLASH INSTRUCTIONS
────────────────────────────────────────────────────────────────────
Install esptool (if needed):
  pip install esptool

Find your serial port:
  Windows:   Device Manager (COM3, COM4, etc.)
  Linux:     ls /dev/ttyUSB* or /dev/ttyACM*
  macOS:     ls /dev/tty.usbserial-*

Flash command (replace COM3 with your port):
  esptool.py --chip $CHIP --port COM3 --baud $UPLOAD_SPEED \\
    write_flash -z 0x0 firmware/firmware.bin

Optional - Erase flash before flashing:
  esptool.py --chip $CHIP --port COM3 erase_flash

Monitor serial output (optional):
  esptool.py --chip $CHIP --port COM3 --baud $BAUD_RATE read_flash_status

🔐 SECURITY NOTES
────────────────────────────────────────────────────────────────────
✓ This firmware contains NO hard-coded passwords
✓ WiFi credentials stored locally only (not in binary)
✓ TOTP codes encrypted in device memory
✓ Data persists only in device's internal flash

📚 DOCUMENTATION
────────────────────────────────────────────────────────────────────
README.md                - Project overview
SECURITY_AND_BUILD.md    - Security guidelines
build_firmware.sh        - Build script (Linux/Mac)
build_firmware.bat       - Build script (Windows)

═══════════════════════════════════════════════════════════════════
Build complete! Ready to flash to your LilyGO T-HMI ESP32-S3
═══════════════════════════════════════════════════════════════════
EOF

    print_success "Build info generated"
    echo ""
}

# Display flash instructions
show_flash_instructions() {
    if [ ! -f "$FIRMWARE_DEST" ]; then
        print_error "Firmware binary not found. Run build first!"
    fi
    
    BINARY_SIZE=$(stat -f%z "$FIRMWARE_DEST" 2>/dev/null || stat -c%s "$FIRMWARE_DEST")
    
    cat << EOF

${CYAN}═══════════════════════════════════════════════════════════════════${NC}
${CYAN}  Flash Instructions - LilyGO T-HMI ESP32-S3${NC}
${CYAN}═══════════════════════════════════════════════════════════════════${NC}

${GREEN}📦 Firmware Information:${NC}
  File:     $FIRMWARE_DEST
  Size:     $BINARY_SIZE bytes

${GREEN}🔌 Prerequisites:${NC}
  1. Install esptool:  pip install esptool
  2. Connect USB cable to LilyGO T-HMI
  3. Find your serial port

${GREEN}🔍 Find Serial Port:${NC}

  ${YELLOW}Windows:${NC}
    • Device Manager → Ports (COM3, COM4, etc.)
    • Or: wmic logicaldisk get name

  ${YELLOW}Linux:${NC}
    ls /dev/ttyUSB*     # USB Serial
    ls /dev/ttyACM*     # CH340 USB

  ${YELLOW}macOS:${NC}
    ls /dev/tty.usbserial-*    # USB Serial
    ls /dev/tty.usbmodem*      # USB Modem

${GREEN}⚡ Flash Commands:${NC}

  ${YELLOW}Flash firmware (replace COM3 with your port):${NC}
    esptool.py --chip $CHIP --port COM3 --baud $UPLOAD_SPEED \\
      write_flash -z 0x0 firmware/firmware.bin

  ${YELLOW}Examples:${NC}
    ${CYAN}Windows:${NC}
      esptool.py --chip $CHIP --port COM3 --baud $UPLOAD_SPEED write_flash -z 0x0 firmware/firmware.bin

    ${CYAN}Linux:${NC}
      esptool.py --chip $CHIP --port /dev/ttyUSB0 --baud $UPLOAD_SPEED write_flash -z 0x0 firmware/firmware.bin

    ${CYAN}macOS:${NC}
      esptool.py --chip $CHIP --port /dev/tty.usbserial-0 --baud $UPLOAD_SPEED write_flash -z 0x0 firmware/firmware.bin

${GREEN}🗑️  Optional - Erase Flash:${NC}
  esptool.py --chip $CHIP --port COM3 erase_flash

${GREEN}📊 Monitor Output:${NC}
  esptool.py --chip $CHIP --port COM3 --baud $BAUD_RATE read_flash_status

${GREEN}✅ After Flashing:${NC}
  1. Device will restart automatically
  2. LilyGO T-HMI will display Dr. Passwords menu
  3. Use buttons to navigate
  4. Long press to send credentials via USB HID

${CYAN}═══════════════════════════════════════════════════════════════════${NC}

EOF
}

# Clean build files
clean_build() {
    print_header "Cleaning Build Files"
    
    if [ -d ".pio" ]; then
        print_info "Removing .pio directory..."
        rm -rf .pio
    fi
    
    if [ -d "$BUILD_OUTPUT" ]; then
        print_info "Removing $BUILD_OUTPUT directory..."
        rm -rf "$BUILD_OUTPUT"
    fi
    
    print_success "Clean completed"
}

# Display summary
show_summary() {
    print_header "Build Summary"
    
    if [ -f "$FIRMWARE_DEST" ]; then
        BINARY_SIZE=$(stat -f%z "$FIRMWARE_DEST" 2>/dev/null || stat -c%s "$FIRMWARE_DEST")
        print_success "Firmware binary ready!"
        print_info "Binary location: $FIRMWARE_DEST"
        print_info "Binary size: $BINARY_SIZE bytes"
        print_info "Next step: Run './build_firmware.sh flash' for flashing instructions"
    fi
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

case "${1:-build}" in
    build)
        build_firmware
        deploy_firmware
        generate_build_info
        show_summary
        ;;
    clean)
        clean_build
        ;;
    flash)
        show_flash_instructions
        ;;
    all)
        clean_build
        build_firmware
        deploy_firmware
        generate_build_info
        show_summary
        ;;
    *)
        echo "Dr. Passwords - Build System"
        echo "For LilyGO T-HMI ESP32-S3"
        echo ""
        echo "Usage: $0 [build|clean|flash|all]"
        echo ""
        echo "Commands:"
        echo "  build   - Build firmware binary (default)"
        echo "  clean   - Clean build artifacts"
        echo "  flash   - Show flashing instructions"
        echo "  all     - Clean, build, and deploy"
        echo ""
        echo "Example:"
        echo "  $0 build              # Build firmware"
        echo "  $0 all                # Full rebuild"
        echo "  $0 flash              # See how to flash"
        exit 0
        ;;
esac

print_success "Done! ✨"

#!/bin/bash

# Tntn Firmware Build Script
# This script builds the firmware binary for ESP32-S3 board

set -e  # Exit on error

echo "================================"
echo "Tntn Firmware Build Script"
echo "================================"
echo ""

# Check if PlatformIO is installed
if ! command -v pio &> /dev/null; then
    echo "❌ PlatformIO CLI not found. Installing..."
    pip install platformio
fi

echo "📦 Building firmware for lilygo-t-hmi..."
pio run --environment lilygo-t-hmi

echo ""
echo "✅ Build complete!"
echo ""
echo "📁 Binary location: .pio/build/lilygo-t-hmi/firmware.bin"
echo ""
echo "📝 Flash commands:"
echo "   esptool.py --chip esp32s3 --port COM3 --baud 921600 write_flash -z 0x0 .pio/build/lilygo-t-hmi/firmware.bin"
echo ""
echo "💡 For other platforms, replace COM3 with your serial port:"
echo "   Linux/Mac: /dev/ttyUSB0 or /dev/ttyACM0"
echo "   Windows: COM3, COM4, etc."
echo ""

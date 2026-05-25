@echo off
REM Tntn Firmware Build Script for Windows
REM This script builds the firmware binary for ESP32-S3 board

echo ================================
echo Tntn Firmware Build Script
echo ================================
echo.

REM Check if PlatformIO is installed
where pio >nul 2>nul
if %errorlevel% neq 0 (
    echo [*] PlatformIO CLI not found. Installing...
    pip install platformio
)

echo [*] Building firmware for lilygo-t-hmi...
call pio run --environment lilygo-t-hmi

if %errorlevel% equ 0 (
    echo.
    echo [OK] Build complete!
    echo.
    echo [INFO] Binary location: .pio\build\lilygo-t-hmi\firmware.bin
    echo.
    echo [INFO] Flash command:
    echo        esptool.py --chip esp32s3 --port COM3 --baud 921600 write_flash -z 0x0 .pio\build\lilygo-t-hmi\firmware.bin
    echo.
    echo [INFO] Replace COM3 with your serial port number
) else (
    echo [ERROR] Build failed!
    exit /b 1
)

pause

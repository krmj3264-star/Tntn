@echo off
REM Tntn Firmware Build Script for Windows
REM Builds firmware binary for ESP32-S3 LilyGO T-HMI
REM Usage: build_firmware.bat [build|clean|flash]

setlocal enabledelayedexpansion

set PROJECT_NAME=Tntn
set DEVICE=lilygo-t-hmi
set CHIP=esp32s3
set BAUD=921600

REM Main
if "%1"=="" (
    call :build_firmware
) else if "%1"=="build" (
    call :build_firmware
) else if "%1"=="clean" (
    call :clean_build
) else if "%1"=="flash" (
    call :show_flash_instructions
) else (
    echo Usage: %0 [build^|clean^|flash]
    echo.
    echo Commands:
    echo   build  - Build firmware binary ^(default^)
    echo   clean  - Clean build artifacts
    echo   flash  - Show flashing instructions
    exit /b 1
)
goto :eof

:check_dependencies
echo [*] Checking dependencies...

where python >nul 2>nul
if !errorlevel! neq 0 (
    echo [ERROR] Python not found. Install Python 3.x
    exit /b 1
)

where pio >nul 2>nul
if !errorlevel! neq 0 (
    echo [*] PlatformIO CLI not found. Installing...
    pip install platformio
)

pip list | find "esptool" >nul
if !errorlevel! neq 0 (
    echo [*] esptool not found. Installing...
    pip install esptool
)

echo [OK] All dependencies available
exit /b 0

:build_firmware
echo.
echo ================================
echo Building %PROJECT_NAME% Firmware
echo ================================
echo.

call :check_dependencies
if !errorlevel! neq 0 exit /b 1

echo [*] Building for board: %DEVICE%
echo [*] Target chip: %CHIP%
echo.

if not exist "build_output" mkdir build_output

echo [*] Running PlatformIO build...
call pio run --environment %DEVICE%
if !errorlevel! neq 0 (
    echo [ERROR] Build failed!
    exit /b 1
)

if exist ".pio\build\%DEVICE%\firmware.bin" (
    copy ".pio\build\%DEVICE%\firmware.bin" "build_output\firmware.bin"
    echo [OK] Firmware binary copied to build_output\firmware.bin
) else (
    echo [ERROR] Firmware binary not found!
    exit /b 1
)

if exist ".pio\build\%DEVICE%\firmware.elf" (
    copy ".pio\build\%DEVICE%\firmware.elf" "build_output\firmware.elf"
    echo [*] Debug symbols copied to build_output\firmware.elf
)

for %%A in (build_output\firmware.bin) do set SIZE=%%~zA
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c-%%a-%%b)
for /f "tokens=1-2 delims=/:" %%a in ('time /t') do (set mytime=%%a:%%b)

echo [OK] Build completed successfully!
echo [*] Binary size: %SIZE% bytes
echo [*] Build time: %mydate% %mytime%
echo.

(
    echo %PROJECT_NAME% Firmware Build Information
    echo ========================================
    echo.
    echo Build Time: %mydate% %mytime%
    echo Binary Size: %SIZE% bytes
    echo Binary Location: build_output\firmware.bin
    echo.
    echo Platform: %CHIP%
    echo Device: %DEVICE%
    echo Framework: Arduino
    echo.
    echo Flash Command:
    echo esptool.py --chip %CHIP% --port COM3 --baud %BAUD% write_flash -z 0x0 firmware.bin
    echo.
    echo Replace COM3 with your actual serial port
    echo.
    echo Documentation: See README.md for detailed instructions
) > build_output\BUILD_INFO.txt

echo [OK] Build info saved to build_output\BUILD_INFO.txt
exit /b 0

:clean_build
echo.
echo ================================
echo Cleaning Build Files
echo ================================
echo.

if exist ".pio" (
    rmdir /s /q .pio
    echo [OK] Removed .pio directory
)

if exist "build_output" (
    rmdir /s /q build_output
    echo [OK] Removed build_output directory
)

echo [OK] Clean completed
exit /b 0

:show_flash_instructions
echo.
echo ================================
echo Flash Instructions
echo ================================
echo.

if not exist "build_output\firmware.bin" (
    echo [ERROR] Firmware binary not found. Run 'build_firmware.bat build' first
    exit /b 1
)

for %%A in (build_output\firmware.bin) do set SIZE=%%~zA

echo ESP32-S3 Firmware Flash Guide
echo.
echo Binary File: build_output\firmware.bin
echo Binary Size: %SIZE% bytes
echo.
echo Prerequisites:
echo 1. Install esptool: pip install esptool
echo 2. Connect ESP32-S3 via USB cable
echo 3. Find your serial port in Device Manager ^(COMx^)
echo.
echo Flash Command:
echo.
echo esptool.py --chip %CHIP% --port COM3 --baud %BAUD% write_flash -z 0x0 build_output\firmware.bin
echo.
echo Replace COM3 with your actual serial port
echo.
echo Optional - Erase Flash Before Flashing:
echo esptool.py --chip %CHIP% --port COM3 erase_flash
echo.
echo Monitor Serial Output:
echo esptool.py --chip %CHIP% --port COM3 --baud 115200 read_flash_status
echo.

exit /b 0

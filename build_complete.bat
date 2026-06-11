@echo off
REM Dr. Passwords - Complete Build & Flash System for Windows
REM For LilyGO T-HMI ESP32-S3
REM Builds real firmware binary and prepares for flashing

setlocal enabledelayedexpansion

REM Configuration
set PROJECT=Dr. Passwords
set DEVICE=lilygo-t-hmi
set CHIP=esp32s3
set BOARD=esp32s3-devkitc-1
set UPLOAD_SPEED=921600
set BAUD_RATE=115200

REM Paths
set BUILD_DIR=.pio\build\%DEVICE%
set FIRMWARE_SRC=%BUILD_DIR%\firmware.bin
set FIRMWARE_DEST=firmware\firmware.bin
set FIRMWARE_ELF=%BUILD_DIR%\firmware.elf
set BUILD_OUTPUT=build_output
set BACKUP_DIR=firmware\backups

REM Colors using findstr (Windows console)
REM Note: Colors are simulated with text

REM Main command routing
if "%1"=="" (
    call :build_firmware
) else if "%1"=="build" (
    call :build_firmware
) else if "%1"=="clean" (
    call :clean_build
) else if "%1"=="flash" (
    call :show_flash_instructions
) else if "%1"=="all" (
    call :clean_build
    call :build_firmware
) else (
    call :show_help
)
goto :eof

REM ============================================================================
REM FUNCTIONS
REM ============================================================================

:print_header
    echo.
    echo ================================================================
    echo %~1
    echo ================================================================
    echo.
    exit /b 0

:print_success
    echo [OK] %~1
    exit /b 0

:print_error
    echo [ERROR] %~1
    exit /b 1

:print_warning
    echo [WARNING] %~1
    exit /b 0

:print_info
    echo [INFO] %~1
    exit /b 0

:check_dependencies
    echo [INFO] Checking dependencies...
    
    where python >nul 2>nul
    if !errorlevel! neq 0 (
        echo [ERROR] Python 3 not found. Install Python 3.8+
        exit /b 1
    )
    
    where pio >nul 2>nul
    if !errorlevel! neq 0 (
        echo [WARNING] PlatformIO CLI not found. Installing...
        pip install platformio
    )
    
    pip list | find "esptool" >nul 2>nul
    if !errorlevel! neq 0 (
        echo [WARNING] esptool not found. Installing...
        pip install esptool
    )
    
    echo [OK] All dependencies available
    exit /b 0

:backup_firmware
    if exist "%FIRMWARE_DEST%" (
        echo [INFO] Creating backup...
        if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
        
        for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set MYDATE=%%c%%a%%b)
        for /f "tokens=1-2 delims=/:" %%a in ('time /t') do (set MYTIME=%%a%%b)
        
        set BACKUP_FILE=%BACKUP_DIR%\firmware_backup_!MYDATE!_!MYTIME!.bin
        copy "%FIRMWARE_DEST%" "!BACKUP_FILE!"
        echo [OK] Backup saved: !BACKUP_FILE!
    )
    exit /b 0

:build_firmware
    call :print_header "Building Firmware for %PROJECT%"
    
    call :check_dependencies
    if !errorlevel! neq 0 exit /b 1
    
    echo [INFO] Build Configuration:
    echo        Device: %DEVICE%
    echo        Chip: %CHIP% (Board: %BOARD%)
    echo        Project: %PROJECT%
    echo.
    
    echo [INFO] Running PlatformIO build...
    call pio run --environment %DEVICE% --silent
    if !errorlevel! neq 0 (
        echo [ERROR] Build failed!
        exit /b 1
    )
    
    if not exist "%FIRMWARE_SRC%" (
        echo [ERROR] Firmware binary not found at %FIRMWARE_SRC%
        exit /b 1
    )
    
    echo [OK] Build completed successfully!
    echo.
    
    call :deploy_firmware
    if !errorlevel! neq 0 exit /b 1
    
    call :generate_build_info
    if !errorlevel! neq 0 exit /b 1
    
    call :show_summary
    exit /b 0

:deploy_firmware
    call :print_header "Deploying Firmware"
    
    call :backup_firmware
    
    if not exist "%BUILD_OUTPUT%" mkdir "%BUILD_OUTPUT%"
    if not exist "firmware" mkdir "firmware"
    
    echo [INFO] Copying firmware binary...
    copy "%FIRMWARE_SRC%" "%FIRMWARE_DEST%"
    copy "%FIRMWARE_SRC%" "%BUILD_OUTPUT%\firmware_latest.bin"
    
    if exist "%FIRMWARE_ELF%" (
        copy "%FIRMWARE_ELF%" "%BUILD_OUTPUT%\firmware_latest.elf"
    )
    
    echo [OK] Firmware deployed to %FIRMWARE_DEST%
    echo.
    exit /b 0

:generate_build_info
    echo [INFO] Generating build information...
    
    for %%A in (%FIRMWARE_DEST%) do set BINARY_SIZE=%%~zA
    
    for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set MYDATE=%%c-%%a-%%b)
    for /f "tokens=1-2 delims=/:" %%a in ('time /t') do (set MYTIME=%%a:%%b)
    
    (
        echo ===================================================================
        echo %PROJECT% - Firmware Build Information
        echo ===================================================================
        echo.
        echo BINARY INFORMATION
        echo -------------------------------------------------------------------
        echo Binary File:     firmware\firmware.bin
        echo Binary Size:     %BINARY_SIZE% bytes
        echo Build Time:      %MYDATE% %MYTIME%
        echo.
        echo BUILD CONFIGURATION
        echo -------------------------------------------------------------------
        echo Device:          LilyGO T-HMI
        echo Chip:            ESP32-S3 (%BOARD%)
        echo Platform:        espressif32
        echo Framework:       Arduino
        echo Upload Speed:    %UPLOAD_SPEED% baud
        echo.
        echo FLASH INSTRUCTIONS
        echo -------------------------------------------------------------------
        echo Install esptool (if needed):
        echo   pip install esptool
        echo.
        echo Find your serial port:
        echo   Windows: Device Manager ^(COM3, COM4, etc.^)
        echo   Linux:   ls /dev/ttyUSB* or /dev/ttyACM*
        echo   macOS:   ls /dev/tty.usbserial-*
        echo.
        echo Flash command (replace COM3 with your port):
        echo   esptool.py --chip %CHIP% --port COM3 --baud %UPLOAD_SPEED% ^
        echo     write_flash -z 0x0 firmware\firmware.bin
        echo.
        echo Optional - Erase flash before flashing:
        echo   esptool.py --chip %CHIP% --port COM3 erase_flash
        echo.
        echo SECURITY NOTES
        echo -------------------------------------------------------------------
        echo ✓ This firmware contains NO hard-coded passwords
        echo ✓ WiFi credentials stored locally only ^(not in binary^)
        echo ✓ TOTP codes encrypted in device memory
        echo ✓ Data persists only in device's internal flash
        echo.
        echo DOCUMENTATION
        echo -------------------------------------------------------------------
        echo README.md                - Project overview
        echo SECURITY_AND_BUILD.md    - Security guidelines
        echo build_firmware.sh        - Build script ^(Linux/Mac^)
        echo build_firmware.bat       - Build script ^(Windows^)
        echo.
        echo ===================================================================
        echo Build complete! Ready to flash to your LilyGO T-HMI ESP32-S3
        echo ===================================================================
    ) > firmware\BUILD_INFO.txt
    
    echo [OK] Build info generated
    echo.
    exit /b 0

:show_flash_instructions
    if not exist "%FIRMWARE_DEST%" (
        echo [ERROR] Firmware binary not found. Run 'build_complete.bat build' first
        exit /b 1
    )
    
    for %%A in (%FIRMWARE_DEST%) do set BINARY_SIZE=%%~zA
    
    echo.
    echo ===================================================================
    echo   Flash Instructions - LilyGO T-HMI ESP32-S3
    echo ===================================================================
    echo.
    echo Firmware Information:
    echo   File:     %FIRMWARE_DEST%
    echo   Size:     %BINARY_SIZE% bytes
    echo.
    echo Prerequisites:
    echo   1. Install esptool:  pip install esptool
    echo   2. Connect USB cable to LilyGO T-HMI
    echo   3. Find your serial port
    echo.
    echo Find Serial Port:
    echo   Windows:  Device Manager ^(COM3, COM4, etc.^)
    echo   Linux:    ls /dev/ttyUSB* or /dev/ttyACM*
    echo   macOS:    ls /dev/tty.usbserial-*
    echo.
    echo Flash Commands (replace COM3 with your port):
    echo.
    echo Windows:
    echo   esptool.py --chip %CHIP% --port COM3 --baud %UPLOAD_SPEED% ^
    echo     write_flash -z 0x0 firmware\firmware.bin
    echo.
    echo Linux:
    echo   esptool.py --chip %CHIP% --port /dev/ttyUSB0 --baud %UPLOAD_SPEED% ^
    echo     write_flash -z 0x0 firmware/firmware.bin
    echo.
    echo macOS:
    echo   esptool.py --chip %CHIP% --port /dev/tty.usbserial-0 --baud %UPLOAD_SPEED% ^
    echo     write_flash -z 0x0 firmware/firmware.bin
    echo.
    echo Optional - Erase Flash:
    echo   esptool.py --chip %CHIP% --port COM3 erase_flash
    echo.
    echo After Flashing:
    echo   1. Device will restart automatically
    echo   2. LilyGO T-HMI will display Dr. Passwords menu
    echo   3. Use buttons to navigate
    echo   4. Long press to send credentials via USB HID
    echo.
    echo ===================================================================
    echo.
    exit /b 0

:clean_build
    call :print_header "Cleaning Build Files"
    
    if exist ".pio" (
        echo [INFO] Removing .pio directory...
        rmdir /s /q .pio 2>nul
    )
    
    if exist "%BUILD_OUTPUT%" (
        echo [INFO] Removing %BUILD_OUTPUT% directory...
        rmdir /s /q "%BUILD_OUTPUT%" 2>nul
    )
    
    echo [OK] Clean completed
    exit /b 0

:show_summary
    call :print_header "Build Summary"
    
    if exist "%FIRMWARE_DEST%" (
        for %%A in (%FIRMWARE_DEST%) do set BINARY_SIZE=%%~zA
        echo [OK] Firmware binary ready!
        echo [INFO] Binary location: %FIRMWARE_DEST%
        echo [INFO] Binary size: %BINARY_SIZE% bytes
        echo [INFO] Next step: Run 'build_complete.bat flash' for flashing instructions
    )
    exit /b 0

:show_help
    echo Dr. Passwords - Build System
    echo For LilyGO T-HMI ESP32-S3
    echo.
    echo Usage: %0 [build^|clean^|flash^|all]
    echo.
    echo Commands:
    echo   build   - Build firmware binary (default)
    echo   clean   - Clean build artifacts
    echo   flash   - Show flashing instructions
    echo   all     - Clean, build, and deploy
    echo.
    echo Examples:
    echo   %0 build              # Build firmware
    echo   %0 all                # Full rebuild
    echo   %0 flash              # See how to flash
    echo.
    exit /b 0

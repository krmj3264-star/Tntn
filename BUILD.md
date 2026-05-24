[build]
# PlatformIO Build Configuration for Binary Generation

# Build firmware
pio run --environment lilygo-t-hmi

# Output location:
# .pio/build/lilygo-t-hmi/firmware.bin

# Flash command:
# esptool.py --chip esp32s3 --port COM3 --baud 921600 write_flash -z 0x0 firmware.bin

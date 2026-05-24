#ifndef CONFIG_H
#define CONFIG_H

// WiFi Credentials
#define WIFI_SSID "***************"
#define WIFI_PASSWORD "**********"

// TOTP
#define GMAIL_TOTP_BASE32 "aaaa bbbb cccc dddd eeee ffff gggg hhhh"

// Buttons
#define BTN_OK_UP   0
#define BTN_DOWN    14

// Time
#define NTP_SERVER_1 "pool.ntp.org"
#define NTP_SERVER_2 "time.google.com"
#define GMT_OFFSET_SEC (3 * 3600)
#define DAYLIGHT_OFFSET_SEC 0

// Timing
#define DEBOUNCE_MS 180
#define HOLD_TIME_MS 700
#define USB_STARTUP_DELAY_MS 800
#define DNS_PORT 53

// Display
#define DISPLAY_WIDTH 480
#define DISPLAY_HEIGHT 320
#define DISPLAY_ROTATION 1

// Storage
#define MAX_PASSWORD_ITEMS 12
#define PREFERENCES_NAMESPACE "vault"

#endif // CONFIG_H
#include <Arduino.h>
#include <TFT_eSPI.h>
#include <WiFi.h>
#include <WebServer.h>
#include <DNSServer.h>
#include <Preferences.h>
#include <time.h>
#include <TOTP.h>
#include "USB.h"
#include "USBHIDKeyboard.h"
#include "config.h"

TFT_eSPI tft = TFT_eSPI();
USBHIDKeyboard Keyboard;
WebServer server(80);
DNSServer dnsServer;
Preferences prefs;

uint8_t gmailTotpSecret[64];
size_t gmailTotpSecretLen = 0;
TOTP* gmailTotp = nullptr;

enum ItemType { ITEM_SUBMENU, ITEM_TEXT, ITEM_TOTP, ITEM_INFO };

struct MenuItem {
  const char* name;
  ItemType type;
  const char* textValue;
  TOTP* totp;
};

enum MenuScreen {
  SCREEN_MAIN, SCREEN_PASSWORDS, SCREEN_PASSWORD_ACTIONS,
  SCREEN_TOTP, SCREEN_TOTP_VIEW, SCREEN_SETTINGS
};

MenuScreen currentScreen = SCREEN_MAIN;
int selectedIndex = 0;
int menuScrollOffset = 0;
bool timeSynced = false;
int activeTotpIndex = 0;
unsigned long lastTotpRedraw = 0;
bool settingsPortalActive = false;
String settingsApPassword;
int activePasswordIndex = 0;

bool lastDownState = HIGH;
bool btnPressed = false;
bool holdTriggered = false;
unsigned long btnPressStart = 0;
unsigned long lastDownPress = 0;
bool downHoldHandled = false;

MenuItem mainMenuItems[] = {
  {"Passwords", ITEM_SUBMENU, nullptr, nullptr},
  {"TOTP", ITEM_SUBMENU, nullptr, nullptr},
  {"Settings", ITEM_SUBMENU, nullptr, nullptr}
};

MenuItem passwordMenuItems[MAX_PASSWORD_ITEMS];
int passwordMenuCount = 4;

char passwordNameValues[MAX_PASSWORD_ITEMS][32] = {
  "Gmail", "GitHub", "AWS", "Bank"
};

char passwordTextValues[MAX_PASSWORD_ITEMS][128] = {
  "MyGmailPassword123",
  "MyGitHubPassword456",
  "MyAwsPassword789",
  "MyBankPassword000"
};

char passwordUsernameValues[MAX_PASSWORD_ITEMS][128] = {
  "user.alpha01", "bluefalcon77", "cloud.user23", "banking_hero",
  "gamma.node", "pixel.rider", "tiger_login", "neo.account",
  "orbit.user", "delta.signin", "fastlane.id", "quantum.user"
};

MenuItem passwordActionMenuItems[] = {
  {"Username", ITEM_INFO, nullptr, nullptr},
  {"Password", ITEM_INFO, nullptr, nullptr},
  {"UserTabPass", ITEM_INFO, nullptr, nullptr}
};

MenuItem totpMenuItems[] = {
  {"Google TOTP", ITEM_TOTP, nullptr, nullptr}
};

MenuItem settingsMenuItems[] = {};

MenuItem* getCurrentMenuItems() {
  switch (currentScreen) {
    case SCREEN_PASSWORDS: return passwordMenuItems;
    case SCREEN_PASSWORD_ACTIONS: return passwordActionMenuItems;
    case SCREEN_TOTP: return totpMenuItems;
    case SCREEN_SETTINGS: return settingsMenuItems;
    default: return mainMenuItems;
  }
}

int getCurrentMenuCount() {
  switch (currentScreen) {
    case SCREEN_PASSWORDS: return passwordMenuCount;
    case SCREEN_PASSWORD_ACTIONS: return 3;
    case SCREEN_TOTP: return 1;
    case SCREEN_SETTINGS: return 0;
    default: return 3;
  }
}

const char* getScreenTitle() {
  switch (currentScreen) {
    case SCREEN_PASSWORDS: return "Passwords";
    case SCREEN_PASSWORD_ACTIONS: return "Send As";
    case SCREEN_TOTP: return "TOTP";
    case SCREEN_TOTP_VIEW: return "TOTP";
    case SCREEN_SETTINGS: return "Settings";
    default: return "Dr. Passwords";
  }
}

int base32Value(char c) {
  if (c >= 'A' && c <= 'Z') return c - 'A';
  if (c >= 'a' && c <= 'z') return c - 'a';
  if (c >= '2' && c <= '7') return c - '2' + 26;
  return -1;
}

size_t decodeBase32(const char* input, uint8_t* output, size_t maxOutputLen) {
  int buffer = 0, bitsLeft = 0;
  size_t outLen = 0;
  while (*input) {
    char c = *input++;
    if (c == ' ' || c == '=' || c == '-') continue;
    int val = base32Value(c);
    if (val < 0) continue;
    buffer = (buffer << 5) | val;
    bitsLeft += 5;
    if (bitsLeft >= 8) {
      bitsLeft -= 8;
      if (outLen >= maxOutputLen) return 0;
      output[outLen++] = (buffer >> bitsLeft) & 0xFF;
    }
  }
  return outLen;
}

bool initTotp() {
  gmailTotpSecretLen = decodeBase32(GMAIL_TOTP_BASE32, gmailTotpSecret, sizeof(gmailTotpSecret));
  if (gmailTotpSecretLen == 0) return false;
  gmailTotp = new TOTP(gmailTotpSecret, gmailTotpSecretLen);
  return true;
}

void drawMenu() {
  tft.fillScreen(TFT_BLACK);
  tft.setTextColor(0xFCC0, TFT_BLACK);
  tft.setTextSize(3);
  tft.setCursor(12, 10);
  tft.println(getScreenTitle());
  tft.setTextSize(2);

  MenuItem* items = getCurrentMenuItems();
  int itemCount = getCurrentMenuCount();
  const int startY = 55, lineHeight = 28, visibleItems = 4;

  if (selectedIndex < menuScrollOffset) menuScrollOffset = selectedIndex;
  if (selectedIndex >= menuScrollOffset + visibleItems)
    menuScrollOffset = selectedIndex - visibleItems + 1;
  if (menuScrollOffset < 0) menuScrollOffset = 0;
  if (itemCount <= visibleItems) menuScrollOffset = 0;

  int endIndex = menuScrollOffset + visibleItems;
  if (endIndex > itemCount) endIndex = itemCount;

  int y = startY;
  for (int i = menuScrollOffset; i < endIndex; i++) {
    if (i == selectedIndex) {
      tft.fillRect(8, y - 2, 300, 22, TFT_LIGHTGREY);
      tft.setTextColor(TFT_GREEN, TFT_LIGHTGREY);
      tft.setCursor(12, y);
      tft.print("> ");
      tft.println(items[i].name);
    } else {
      tft.setTextColor(TFT_WHITE, TFT_BLACK);
      tft.setCursor(12, y);
      tft.print("  ");
      tft.println(items[i].name);
    }
    y += lineHeight;
  }
}

void showSendingScreen(const char* text) {
  tft.fillScreen(TFT_BLACK);
  tft.setTextColor(TFT_CYAN, TFT_BLACK);
  tft.setTextSize(2);
  tft.setCursor(20, 45);
  tft.println("Sending...");
  tft.setTextColor(TFT_WHITE, TFT_BLACK);
  tft.setTextSize(1);
  tft.setCursor(20, 85);
  tft.println(text);
}

bool syncTimeOverWiFi() {
  WiFi.mode(WIFI_STA);
  while (true) {
    WiFi.disconnect(true);
    delay(200);
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
    unsigned long start = millis();
    while (WiFi.status() != WL_CONNECTED && millis() - start < 20000)
      delay(250);
    if (WiFi.status() == WL_CONNECTED) {
      configTime(GMT_OFFSET_SEC, DAYLIGHT_OFFSET_SEC, NTP_SERVER_1, NTP_SERVER_2);
      struct tm timeinfo;
      start = millis();
      while (millis() - start < 20000) {
        if (getLocalTime(&timeinfo)) {
          WiFi.disconnect(true);
          WiFi.mode(WIFI_OFF);
          return true;
        }
        delay(250);
      }
    }
    WiFi.disconnect(true);
    delay(500);
  }
}

bool getCurrentUnixTime(time_t &unixTime) {
  time(&unixTime);
  return unixTime > 1700000000;
}

void showStatusScreen(const char* title, const char* line2) {
  tft.fillScreen(TFT_BLACK);
  tft.setTextColor(0xFCC0, TFT_BLACK);
  tft.setTextSize(2);
  int titleWidth = strlen(title) * 12;
  int titleX = (tft.width() - titleWidth) / 2;
  tft.setCursor(titleX, tft.height() / 2 - 20);
  tft.println(title);
}

void showTotpCodeScreen(const char* title, const char* code, int secondsRemaining) {
  tft.fillScreen(TFT_BLACK);
  tft.setTextColor(TFT_WHITE, TFT_BLACK);
  tft.setTextSize(2);
  int titleX = (tft.width() - strlen(title) * 12) / 2;
  tft.setCursor(titleX, 12);
  tft.println(title);

  int boxX = (tft.width() - 200) / 2, boxY = 42;
  tft.drawRoundRect(boxX, boxY, 200, 54, 10, TFT_LIGHTGREY);
  tft.setTextSize(4);
  int codeX = boxX + (200 - strlen(code) * 24) / 2;
  tft.setCursor(codeX, boxY + 10);
  tft.println(code);

  int barX = (tft.width() - 180) / 2, barY = 112;
  tft.drawRoundRect(barX, barY, 180, 12, 6, TFT_DARKGREY);
  int progressWidth = (secondsRemaining * 180) / 30;
  if (progressWidth > 0)
    tft.fillRoundRect(barX + 2, barY + 2, progressWidth, 8, 4, TFT_GREEN);

  tft.setTextSize(2);
  char timeText[6];
  sprintf(timeText, "%ds", secondsRemaining);
  tft.setCursor(barX + 190, barY - 2);
  tft.print(timeText);
}

void drawBootScreen() {
  tft.fillScreen(TFT_BLACK);
  tft.setTextColor(0xFCC0, TFT_BLACK);
  tft.setTextSize(3);
  const char* title = "Dr. Passwords";
  int x = (tft.width() - strlen(title) * 18) / 2;
  int y = tft.height() / 2 - 12;
  tft.setCursor(x, y);
  tft.println(title);
}

void moveUp() {
  int itemCount = getCurrentMenuCount();
  selectedIndex--;
  if (selectedIndex < 0) selectedIndex = itemCount - 1;
  drawMenu();
}

void moveDown() {
  int itemCount = getCurrentMenuCount();
  selectedIndex++;
  if (selectedIndex >= itemCount) selectedIndex = 0;
  drawMenu();
}

void refreshPasswordMenuItems() {
  for (int i = 0; i < passwordMenuCount; i++) {
    passwordMenuItems[i].name = passwordNameValues[i];
    passwordMenuItems[i].type = ITEM_TEXT;
  }
}

void loadSavedPasswords() {
  prefs.begin(PREFERENCES_NAMESPACE, true);
  int storedCount = prefs.getInt("count", 4);
  if (storedCount < 1) storedCount = 1;
  if (storedCount > MAX_PASSWORD_ITEMS) storedCount = MAX_PASSWORD_ITEMS;
  passwordMenuCount = storedCount;
  prefs.end();
  refreshPasswordMenuItems();
}

void savePasswordsToPreferences() {
  prefs.begin(PREFERENCES_NAMESPACE, false);
  prefs.putInt("count", passwordMenuCount);
  prefs.end();
}

String generateApPassword() {
  const char charset[] = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#$%^&*";
  String result = "";
  for (int i = 0; i < 16; i++)
    result += charset[esp_random() % (sizeof(charset) - 1)];
  return result;
}

void stopSettingsPortal() {
  if (!settingsPortalActive) return;
  dnsServer.stop();
  server.stop();
  WiFi.softAPdisconnect(true);
  WiFi.mode(WIFI_OFF);
  settingsPortalActive = false;
}

void startSettingsPortal() {
  stopSettingsPortal();
  WiFi.disconnect(true, true);
  delay(200);
  WiFi.mode(WIFI_AP);
  delay(100);
  bool apStarted = WiFi.softAP("Dr. Passwords", settingsApPassword.c_str());
  if (!apStarted) {
    currentScreen = SCREEN_MAIN;
    drawMenu();
    return;
  }
  dnsServer.stop();
  server.stop();
  dnsServer.start(DNS_PORT, "*", WiFi.softAPIP());
  server.on("/", HTTP_GET, []() { server.send(200, "text/plain", "Portal Active"); });
  server.begin();
  settingsPortalActive = true;
}

void processSettingsPortal() {
  if (!settingsPortalActive) return;
  dnsServer.processNextRequest();
  server.handleClient();
}

void sendSelectedItem() {
  if (currentScreen == SCREEN_TOTP_VIEW) {
    time_t now;
    if (getCurrentUnixTime(now)) {
      char* code = totpMenuItems[0].totp->getCode(now);
      Keyboard.print(code);
    }
    return;
  }

  if (settingsPortalActive) {
    Keyboard.print(settingsApPassword);
    return;
  }

  if (currentScreen == SCREEN_PASSWORD_ACTIONS) {
    showSendingScreen(passwordMenuItems[activePasswordIndex].name);
    delay(250);
    if (selectedIndex == 0)
      Keyboard.print(passwordUsernameValues[activePasswordIndex]);
    else if (selectedIndex == 1)
      Keyboard.print(passwordTextValues[activePasswordIndex]);
    else if (selectedIndex == 2) {
      Keyboard.print(passwordUsernameValues[activePasswordIndex]);
      Keyboard.write(KEY_TAB);
      Keyboard.print(passwordTextValues[activePasswordIndex]);
    }
    delay(400);
    drawMenu();
    return;
  }

  if (currentScreen == SCREEN_MAIN) {
    if (selectedIndex == 0) {
      currentScreen = SCREEN_PASSWORDS;
      selectedIndex = 0;
      drawMenu();
    } else if (selectedIndex == 1) {
      if (!timeSynced) {
        showStatusScreen("Connecting WiFi", "");
        syncTimeOverWiFi();
        timeSynced = true;
      }
      currentScreen = SCREEN_TOTP_VIEW;
    } else if (selectedIndex == 2) {
      startSettingsPortal();
    }
  } else if (currentScreen == SCREEN_PASSWORDS && selectedIndex < passwordMenuCount) {
    activePasswordIndex = selectedIndex;
    currentScreen = SCREEN_PASSWORD_ACTIONS;
    selectedIndex = 0;
    drawMenu();
  }
}

void setup() {
  Serial.begin(115200);
  delay(1000);

  pinMode(BTN_OK_UP, INPUT_PULLUP);
  pinMode(BTN_DOWN, INPUT_PULLUP);

  settingsApPassword = generateApPassword();
  loadSavedPasswords();

  tft.init();
  tft.setRotation(DISPLAY_ROTATION);

  if (!initTotp()) {
    tft.fillScreen(TFT_BLACK);
    tft.setTextColor(TFT_RED, TFT_BLACK);
    tft.setTextSize(2);
    tft.setCursor(20, 40);
    tft.println("TOTP Error");
    while (true) delay(1000);
  }

  totpMenuItems[0].totp = gmailTotp;
  drawBootScreen();
  delay(1200);
  drawMenu();

  Keyboard.begin();
  USB.begin();
  delay(USB_STARTUP_DELAY_MS);
}

void loop() {
  processSettingsPortal();
  bool okUpState = digitalRead(BTN_OK_UP);
  bool downState = digitalRead(BTN_DOWN);
  unsigned long nowMs = millis();

  if (currentScreen == SCREEN_TOTP_VIEW) {
    time_t now;
    if (getCurrentUnixTime(now)) {
      int secondsRemaining = 30 - (now % 30);
      if (secondsRemaining == 30) secondsRemaining = 0;
      if (lastTotpRedraw != (unsigned long)now) {
        char* code = totpMenuItems[0].totp->getCode(now);
        showTotpCodeScreen("Google TOTP", code, secondsRemaining);
        lastTotpRedraw = (unsigned long)now;
      }
    }
  }

  if (okUpState == LOW) {
    if (!btnPressed) {
      btnPressed = true;
      btnPressStart = nowMs;
      holdTriggered = false;
    } else if (!holdTriggered && (nowMs - btnPressStart >= HOLD_TIME_MS)) {
      holdTriggered = true;
      sendSelectedItem();
    }
  } else {
    if (btnPressed && !holdTriggered) {
      if (currentScreen != SCREEN_TOTP_VIEW && !settingsPortalActive)
        moveDown();
    }
    btnPressed = false;
    holdTriggered = false;
  }

  if (downState == LOW) {
    if (lastDownState == HIGH) {
      lastDownPress = nowMs;
      downHoldHandled = false;
    }
    if (!downHoldHandled && (nowMs - lastDownPress >= HOLD_TIME_MS)) {
      downHoldHandled = true;
      if (currentScreen != SCREEN_MAIN) {
        currentScreen = SCREEN_MAIN;
        selectedIndex = 0;
        drawMenu();
      } else if (settingsPortalActive) {
        stopSettingsPortal();
        drawMenu();
      }
    }
  } else {
    if (lastDownState == LOW && !downHoldHandled && (nowMs - lastDownPress < HOLD_TIME_MS)) {
      if (currentScreen != SCREEN_TOTP_VIEW && !settingsPortalActive)
        moveUp();
    }
    downHoldHandled = false;
  }

  lastDownState = downState;
  delay(20);
}
# Dr. Passwords - LilyGO T-HMI Firmware

برنامج إدارة كلمات المرور والتحقق الثنائي (TOTP) لجهاز LilyGO T-HMI

## المميزات ✨

- 🔐 **إدارة كلمات المرور**: حفظ واسترجاع كلمات المرور بسهولة
- 🔑 **TOTP Support**: دعم التحقق الثنائي من Google Authenticator
- 📱 **WiFi Portal**: واجهة ويب لإدارة كلمات المرور عن بُعد
- 📺 **شاشة IPS**: عرض واضح وملون على شاشة 480×320
- ⌨️ **USB HID Keyboard**: إدخال تلقائي للبيانات عبر USB
- 💾 **تخزين محلي**: حفظ البيانات في الذاكرة الداخلية (Preferences)

## المتطلبات 📋

### الأجهزة:
- **LilyGO T-HMI** (ESP32-S3)
- كابل USB-C

### البرامج:
- **PlatformIO** أو **Arduino IDE**
- Python 3.x (لـ esptool)

### المكتبات:
- TFT_eSPI
- TOTP
- WiFi
- WebServer
- DNSServer
- Preferences

## التثبيت 🚀

### الطريقة 1: استخدام PlatformIO (الموصى به)

```bash
# تثبيت PlatformIO
pip install platformio

# نسخ المشروع
git clone https://github.com/krmj3264-star/tntn.git
cd tntn

# البناء والرفع
platformio run --target upload --environment lilygo-t-hmi
```

### الطريقة 2: استخدام Arduino IDE

1. افتح Arduino IDE
2. انسخ محتوى `src/main.cpp` في الـ Sketch
3. ثبّت المكتبات المطلوبة من Library Manager
4. عيّن الإعدادات:
   - Board: `ESP32S3 Dev Module`
   - Upload Speed: `921600`
   - Port: اختر منفذ USB لجهازك
5. اضغط Upload

### الخطوة الهامة: تكوين TFT_eSPI 🎨

افتح `Arduino/libraries/TFT_eSPI/User_Setup.h` وأضف:

```cpp
#define ILI9488_DRIVER
#define TFT_CS   14
#define TFT_DC   22
#define TFT_RST  5
#define TFT_MOSI 23
#define TFT_SCLK 18
#define TFT_MISO 19
#define TFT_BL   21

#define TFT_WIDTH  480
#define TFT_HEIGHT 320
#define SPI_FREQUENCY 80000000
```

## الاستخدام 📖

### الأزرار:
- **الزر العلوي (GPIO 0)**: تحديد/إرسال
  - اضغط: نزول في القائمة
  - اضغط طويل: إرسال كلمة المرور

- **الزر السفلي (GPIO 14)**: رجوع
  - اضغط: صعود في القائمة
  - اضغط طويل: رجوع للقائمة الرئيسية

### القوائم:
1. **Passwords**: إدارة كلمات المرور المحفوظة
2. **TOTP**: عرض أكوار التحقق الثنائي
3. **Settings**: بوابة الويب لإضافة/تعديل كلمات المرور

### بوابة الويب (WiFi Portal):
1. اذهب للإعدادات واختر WiFi Portal
2. اتصل بـ WiFi باسم "Dr. Passwords"
3. افتح أي موقع (سيتم توجيهك تلقائياً)
4. أضف أو عدّل كلمات المرور

## التكوين ⚙️

عدّل `include/config.h`:

```cpp
#define WIFI_SSID "your_ssid"
#define WIFI_PASSWORD "your_password"
#define GMAIL_TOTP_BASE32 "your_base32_secret"
```

## البناء والتحميل 🔧

### استخراج Binary File:

```bash
# بعد البناء الناجح
platformio run --target upload --environment lilygo-t-hmi

# الملف النهائي يكون في:
.pio/build/lilygo-t-hmi/firmware.bin
```

### تحميل Binary مباشرة:

```bash
# تثبيت esptool
pip install esptool

# مسح الذاكرة (اختياري)
esptool.py --chip esp32s3 --port COM3 erase_flash

# تحميل البرنامج
esptool.py --chip esp32s3 --port COM3 --baud 921600 write_flash -z 0x0 firmware.bin
```

## الهيكل 📁

```
tntn/
├── platformio.ini          # إعدادات البناء
├── include/
│   └── config.h           # ملف التكوين
├── src/
│   └── main.cpp           # الكود الرئيسي
├── .gitignore             # ملفات المجلد المتجاهلة
└── README.md              # هذا الملف
```

## الإضافات المستقبلية 🚧

- [ ] دعم كلمات مرور متعددة لـ TOTP
- [ ] تشفير البيانات في الذاكرة
- [ ] نسخ احتياطي عبر السحابة
- [ ] واجهة رسومية محسّنة
- [ ] دعم بصمات الأصابع

## استكشاف الأخطاء 🐛

### الشاشة لا تعمل:
- تحقق من كابل USB
- تأكد من تكوين TFT_eSPI الصحيح
- حاول مسح الذاكرة: `esptool.py erase_flash`

### مشاكل WiFi:
- تحقق من بيانات الدخول في `config.h`
- أعد تشغيل الجهاز
- جرب WiFi شبكة أخرى

### أزرار لا تعمل:
- تحقق من الأسلاك والاتصالات
- جرب معايرة الأزرار

## الرخصة 📄

MIT License - استخدم بحرية!

## المساهمة 🤝

نرحب بالمساهمات! يرجى فتح Pull Request أو Issue.

## التواصل 📧

للأسئلة والاستفسارات، فتح Issue في المستودع.

---

**صُنع بـ ❤️ للأمان الرقمي**
# 🔐 Dr. Passwords - Security & Build Guide

## ⚠️ أمان البيانات (Security First!)

هذا المشروع يتعامل مع **بيانات حساسة جداً** - كلمات مرور وأكوار التحقق الثنائي.

### 🛡️ ملاحظات الأمان الهامة:

#### 1. **عدم مشاركة config.h**
```bash
# تأكد من أن config.h موجود في .gitignore
echo "include/config.h" >> .gitignore
```

**لا تنشر أبداً:**
- ✗ بيانات WiFi الحقيقية
- ✗ أكوار TOTP Base32
- ✗ كلمات المرور المخزنة

#### 2. **الجهاز الفعلي هو المستودع الآمن**
```
الجهاز (LilyGO T-HMI)
    ↓
الذاكرة الداخلية (ESP32-S3 Preferences)
    ↓
بيانات محلية محمية
    ↓
لا توجد نسخة بعيدة!
```

#### 3. **ملف البناء النصي (Placeholder)**
```
firmware/firmware.bin ← ملف نصي للتوثيق فقط
```

**هذا ليس البرنامج الثنائي الحقيقي!**

---

## 🔧 البناء الآمن

### المتطلبات الأساسية:

```bash
# 1. تثبيت Python
python --version  # 3.8+

# 2. تثبيت PlatformIO
pip install platformio esptool

# 3. نسخ المشروع محلياً فقط
git clone https://github.com/krmj3264-star/Tntn.git
cd Tntn
```

### خطوات البناء الآمنة:

#### Linux/Mac:
```bash
# 1. جعل السكريبت قابلاً للتنفيذ
chmod +x build_firmware.sh

# 2. البناء
./build_firmware.sh build

# 3. النتيجة
ls -lh build_output/firmware.bin
```

#### Windows:
```batch
# 1. البناء مباشرة
build_firmware.bat build

# 2. النتيجة
dir build_output\firmware.bin
```

---

## ⚡ الفلاش الآمن

### خطوات الفلاش:

```bash
# 1. تثبيت esptool (إن لم تكن مثبتاً)
pip install esptool

# 2. البحث عن المنفذ التسلسلي
# Windows: Device Manager → Ports (COMx)
# Linux: ls /dev/ttyUSB*
# macOS: ls /dev/tty.usbserial-*

# 3. الفلاش (استبدل COM3 بمنفذك)
esptool.py --chip esp32s3 --port COM3 --baud 921600 write_flash -z 0x0 build_output/firmware.bin

# 4. المراقبة
esptool.py --chip esp32s3 --port COM3 --baud 115200 read_flash_status
```

---

## 🔐 إعداد الجهاز الآمن

### 1. تحرير ملف التكوين:
```cpp
// include/config.h

#define WIFI_SSID "شبكتك_الخاصة"           // ❌ لا تشاركها!
#define WIFI_PASSWORD "كلمة_مرورك"          // ❌ سرية!
#define GMAIL_TOTP_BASE32 "رمزك_السري"      // ❌ جداً سرية!
```

### 2. توليد كود TOTP آمن:
```bash
# استخدم Google Authenticator أو Authy
# انسخ Base32 Code من تطبيق المصادقة
# ألصقه في config.h فقط
```

### 3. حفظ البيانات محلياً:
```cpp
// عند التشغيل الأول
// الجهاز يحفظ البيانات في Preferences (EEPROM)
// لا توجد نسخة بعيدة تلقائياً
```

---

## 📱 استخدام الجهاز بأمان

### القوائم الرئيسية:

1. **Passwords** 🔐
   - اضغط للتنقل
   - اضغط طويل لإرسال كلمة المرور عبر USB HID

2. **TOTP** 🔑
   - عرض رمز التحقق الثنائي
   - ينتقل تلقائياً كل 30 ثانية

3. **Settings** ⚙️
   - بوابة WiFi محلية لإضافة كلمات مرور جديدة
   - اسم الشبكة: "Dr. Passwords"
   - كلمة المرور: عشوائية تماماً ✅

---

## ✅ قائمة التحقق الأمني

قبل استخدام الجهاز:

- [ ] تم حذف config.h من Git
- [ ] تم تعيين كلمات مرور WiFi الحقيقية
- [ ] تم إضافة رمز TOTP الصحيح
- [ ] تم الفلاش بنجاح
- [ ] الجهاز يعمل بدون أخطاء
- [ ] تم حفظ البيانات محلياً فقط

---

## 🚀 بعد الفلاش الأول

```
1. الجهاز سيعرض شاشة البداية
2. انتظر 2 ثانية للقائمة الرئيسية
3. استخدم الأزرار للتنقل
4. البيانات محفوظة محلياً تلقائياً
```

---

## 🐛 استكشاف الأخطاء

### المشكلة: "لا توجد بيانات"
```
الحل: استخدم Settings لإضافة كلمات مرور جديدة
```

### المشكلة: "خطأ في TOTP"
```
تحقق من:
1. Base32 Code صحيح؟
2. الوقت في الجهاز صحيح؟
3. WiFi متصل أثناء المزامنة؟
```

### المشكلة: "USB HID لا يعمل"
```
1. تحقق من كابل USB
2. جرب منفذ USB آخر
3. أعد تشغيل الجهاز
```

---

## 📝 ملاحظات مهمة

### ❌ لا تفعل:
- ❌ لا تشارك config.h
- ❌ لا تحفظ كلمات المرور في GitHub
- ❌ لا تنشر Binary الحقيقي علناً بدون تشفير
- ❌ لا تستخدم WiFi عام دون VPN

### ✅ افعل:
- ✅ احفظ config.h محلياً فقط
- ✅ استخدم شبكة WiFi آمنة
- ✅ غيّر كلمة مرور WiFi Portal بانتظام
- ✅ احتفظ بنسخة احتياطية من الجهاز نفسه

---

## 🔗 موارد إضافية

- [PlatformIO Documentation](https://docs.platformio.org/)
- [ESP32-S3 DevKit](https://docs.espressif.com/projects/esp-idf/en/latest/)
- [TOTP Standards (RFC 6238)](https://tools.ietf.org/html/rfc6238)
- [Google Authenticator](https://support.google.com/accounts/answer/1066447)

---

## 🆘 الدعم والمساعدة

في حالة المشاكل:
1. اقرأ README.md
2. تحقق من BUILD.md
3. افتح Issue على GitHub (بدون بيانات حساسة!)

---

**🛡️ تذكر: أمان بياناتك هو مسؤوليتك الأولى!**

**صُنع بـ ❤️ للأمان الرقمي**

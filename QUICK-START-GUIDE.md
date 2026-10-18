# 🚀 Quick Start Guide - SiLAKES Scanner

## ⏱️ Estimasi Waktu: 20 menit

Panduan cepat untuk menjalankan aplikasi SiLAKES Scanner dari awal hingga siap digunakan.

---

## 📋 Prerequisites Check

Pastikan Anda sudah install:

```bash
# Check Flutter
flutter --version
# Output harus: Flutter 3.x.x atau lebih baru

# Check Dart
dart --version

# Check device (Android emulator atau real device)
flutter devices
```

---

## 🔥 STEP 1: Setup Firebase (15 menit)

### 1.1 Buat Firebase Project

1. Buka: https://console.firebase.google.com/
2. Klik **"Add project"**
3. Project name: `SiLAKES Scanner`
4. Disable Google Analytics
5. Klik **Create project**

### 1.2 Enable Realtime Database

1. Di sidebar, klik **"Realtime Database"**
2. Klik **"Create Database"**
3. Location: **Singapore** (asia-southeast1)
4. Security rules: **"Start in test mode"**
5. Klik **Enable**

### 1.3 Catat Database URL

Setelah database dibuat, lihat URL di bagian atas:
```
https://silakes-scanner-xxxxx-default-rtdb.firebaseio.com/
```

**SIMPAN URL INI!** ⚠️

### 1.4 Register Android App

1. Klik ⚙️ (Settings) → **Project settings**
2. Scroll ke bawah → klik icon **Android** (🤖)
3. Isi:
   - **Package name**: `id.labkesdasumenep.silakes.silakes_scanner`
   - **App nickname**: `SiLAKES Scanner`
4. Klik **Register app**
5. **Download** file `google-services.json`

### 1.5 Copy google-services.json

```bash
# Copy file yang baru di-download ke:
D:\Project APP\silakes_scanner\android\app\google-services.json
```

⚠️ **PENTING**: File harus di folder `android/app/`, BUKAN di folder `android/`!

---

## ⚙️ STEP 2: Update Configuration (5 menit)

Edit file: `lib/core/config/app_config.dart`

### 2.1 Update Base URL

Ganti dengan URL backend Laravel Anda:

```dart
static const String baseUrl = 'https://api.silakes.labkesdasumenep.id/api/v1';
```

### 2.2 Update Encryption Key

⚠️ **CRITICAL**: Key HARUS 32 karakter dan SAMA dengan Laravel!

```dart
static const String flutterEncryptionKey = 'your-32-character-secret-key!!';
```

Contoh key yang valid (32 karakter):
- `my-super-secret-256-bit-key--`
- `12345678901234567890123456789012`

**Cara generate random key:**
```bash
# PowerShell
-join ((65..90) + (97..122) + (48..57) | Get-Random -Count 32 | % {[char]$_})
```

### 2.3 Update Firebase Database URL

Ganti dengan URL yang Anda catat di Step 1.3:

```dart
static const String firebaseRealtimeDatabaseUrl = 
    'https://silakes-scanner-xxxxx-default-rtdb.firebaseio.com';
```

**Save file!** 💾

---

## 🔨 STEP 3: Build & Run

### 3.1 Install Dependencies

```bash
cd "D:\Project APP\silakes_scanner"
flutter pub get
```

### 3.2 Verify Configuration

```bash
# Check if google-services.json exists
dir android\app\google-services.json

# Should show the file. If not, go back to Step 1.5!
```

### 3.3 Run App

```bash
# Connect Android device or start emulator
flutter devices

# Run app
flutter run
```

**First run akan lama** (2-3 menit) karena download dependencies Android.

---

## ✅ STEP 4: Testing

### 4.1 Test Dashboard

- ✅ App terbuka dengan logo SiLAKES
- ✅ Ada tombol biru "Mulai Scan"
- ✅ Tampilan smooth dan tidak ada error

### 4.2 Test Camera

1. Tap **"Mulai Scan"**
2. Allow camera permission (pop-up pertama kali)
3. Camera preview muncul dengan frame guide KTP
4. Ada tombol capture (lingkaran putih besar)

### 4.3 Test OCR

1. Ambil foto KTP (bisa foto KTP dari layar komputer dulu untuk testing)
2. Tunggu loading "Memproses gambar..."
3. Form preview & edit muncul dengan data terisi

**Expected behavior:**
- Loading screen: ✅ Muncul animasi loading
- OCR process: ✅ Data ter-ekstrak (bisa tidak sempurna, normal)
- Form edit: ✅ Bisa edit data manual

### 4.4 Test Validation NIK

Gunakan NIK test: `1234567890123456` (16 digit)

1. Edit NIK di form
2. Tap **"Simpan Data"**
3. Loading → Data terkirim

**Check Firebase:**
1. Buka Firebase Console
2. Realtime Database → Tab "Data"
3. Expand node `patients`
4. Lihat data baru masuk ✅

### 4.5 Test History

1. Kembali ke Dashboard
2. Scroll kebawah → Lihat "Riwayat Scan"
3. Data yang baru di-scan muncul
4. Tap card untuk lihat detail
5. Swipe delete untuk hapus

---

## 🐛 Troubleshooting

### Problem 1: "No devices found"

**Solution:**
```bash
# Enable USB Debugging di Android
# Settings → Developer Options → USB Debugging

# Atau gunakan emulator
flutter emulators --launch Pixel_3a_API_30
```

### Problem 2: "google-services.json not found"

**Solution:**
```bash
# Pastikan file ada di path yang benar:
D:\Project APP\silakes_scanner\android\app\google-services.json

# Bukan di:
# android\google-services.json ❌
```

### Problem 3: "Failed to initialize Firebase"

**Solution:**
```bash
# Clean & rebuild
flutter clean
flutter pub get
flutter run

# Check internet connection
# Check Firebase project is active
```

### Problem 4: "Camera permission denied"

**Solution:**
- Uninstall app dari device
- Re-run: `flutter run`
- Allow permission saat diminta

### Problem 5: "API Key error / Decryption failed"

**Solution:**
```dart
// Check encryption key di app_config.dart:
// 1. Harus TEPAT 32 karakter
// 2. Harus SAMA dengan Laravel .env

// Test dengan key ini dulu:
static const String flutterEncryptionKey = 
    'test-key-32-characters-long!!';
    
// 12345678901234567890123456789012 (count the chars!)
```

### Problem 6: "Data tidak masuk Firebase"

**Solution:**
1. Check Firebase Rules → harus `test mode` (write: true)
2. Check Database URL di `app_config.dart`
3. Check internet connection
4. Lihat error log di console: `flutter run --verbose`

---

## 📱 Build APK untuk Testing

### Debug APK (Quick)

```bash
flutter build apk --debug
```

File output:
```
build\app\outputs\flutter-apk\app-debug.apk
```

### Release APK (Optimized)

```bash
flutter build apk --release
```

File output:
```
build\app\outputs\flutter-apk\app-release.apk
```

Install ke device:
```bash
# Via USB
flutter install

# Atau copy APK manual
adb install build\app\outputs\flutter-apk\app-release.apk
```

---

## 📊 Testing Checklist

Sebelum deploy ke production:

### ✅ Functionality
- [ ] Dashboard load dengan benar
- [ ] Camera bisa dibuka
- [ ] Foto bisa diambil
- [ ] OCR extract data (minimal 80% akurat)
- [ ] Edit form bisa diisi manual
- [ ] Validation NIK bekerja (16 digit)
- [ ] Data masuk ke Firebase
- [ ] Data muncul di History
- [ ] Refresh API key bekerja
- [ ] Delete history bekerja

### ✅ UI/UX
- [ ] Logo muncul di AppBar
- [ ] Tema biru muda konsisten
- [ ] Loading animations smooth
- [ ] Snackbar notifications muncul
- [ ] No lag saat scroll
- [ ] Button tap responsive

### ✅ Edge Cases
- [ ] Test dengan foto blur → error message jelas
- [ ] Test dengan NIK invalid → validation error
- [ ] Test tanpa internet → error message
- [ ] Test dengan required field kosong → validation
- [ ] Test back button → tidak crash

### ✅ Production Ready
- [ ] Firebase rules di-update (tidak test mode)
- [ ] Encryption key production (bukan test key)
- [ ] Backend Laravel sudah ready
- [ ] Endpoint `/cek-nik` berfungsi
- [ ] Endpoint `/config/gemini-key` berfungsi

---

## 🎯 Next Actions

### For Development
```bash
# Always check errors
flutter analyze

# Format code
flutter format .

# Run with verbose logging
flutter run --verbose
```

### For Production
```bash
# Build release APK
flutter build apk --release --shrink

# Build App Bundle (Google Play)
flutter build appbundle --release

# Generate icons (if needed)
flutter pub run flutter_launcher_icons:main
```

---

## 📞 Need Help?

### Logs Location
```bash
# Real-time logs saat run
flutter run --verbose

# Or check logcat (Android)
adb logcat | findstr "SiLAKES"
```

### Common Commands
```bash
# Clear cache
flutter clean

# Update packages
flutter pub upgrade

# Check outdated
flutter pub outdated

# Doctor check
flutter doctor -v
```

---

## 🎉 Success!

Jika semua checklist ✅ berhasil, aplikasi Anda siap digunakan!

**Total Time**: ~20 menit setup + 5 menit testing = **25 menit** 🚀

---

## 📝 Summary

✅ **Firebase**: Database URL configured  
✅ **google-services.json**: Downloaded & placed  
✅ **app_config.dart**: 3 values updated  
✅ **App**: Running without errors  
✅ **Camera**: Working  
✅ **OCR**: Extracting data  
✅ **Firebase**: Data saved  
✅ **History**: Showing correctly  

**Status**: 🟢 **READY TO USE**

---

**Happy Scanning! 📸**

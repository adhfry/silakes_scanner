# 🚀 Quick Build Guide - SiLAKES Scanner

## ⚡ Fast Track (Untuk yang sudah punya keystore)

### 1️⃣ Pastikan file `key.properties` sudah ada
Lokasi: `android/key.properties`

### 2️⃣ Jalankan script build
```bash
build_release.bat
```

### 3️⃣ Ambil APK
Lokasi: `build\app\outputs\flutter-apk\app-release.apk`

---

## 📋 Checklist Cepat

✅ File `google-services.json` ada di `android/app/`  
✅ Firebase Realtime Database configured  
✅ Gemini API Key configured di Firebase  
✅ File `key.properties` ada (untuk production)  
✅ Version number updated di `pubspec.yaml`  

---

## 🔥 Build Sekarang (Tanpa Keystore - Debug Signing)

Jika Anda belum punya keystore, bisa build dulu dengan debug signing:

```bash
cd "D:\Project APP\silakes_scanner"
flutter clean
flutter pub get
flutter build apk --release
```

APK akan di-sign dengan debug key (OK untuk internal testing, TIDAK untuk Play Store).

---

## 🏗️ Setup Keystore (Sekali Saja)

### Generate Keystore:
```bash
keytool -genkey -v -keystore silakes-scanner-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias silakes-scanner
```

Ikuti instruksi, masukkan:
- Password (SIMPAN BAIK-BAIK!)
- Nama organisasi: LabKesDa Sumenep
- Kota: Sumenep
- Provinsi: Jawa Timur
- Negara: ID

### Buat `android/key.properties`:
```properties
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=silakes-scanner
storeFile=D:/Project APP/silakes-scanner-release-key.jks
```

Ganti `YOUR_PASSWORD` dengan password yang Anda buat tadi.

### Build lagi:
```bash
build_release.bat
```

---

## 📱 Teknologi yang Digunakan

- **Database**: Firebase Realtime Database (RTDB)
- **OCR**: Google Gemini AI
- **Local Storage**: Hive
- **State Management**: Riverpod
- **UI**: Material Design 3

---

## 🎯 Output Files

### APK (Direct Install)
- File: `app-release.apk`
- Ukuran: ~40-50 MB
- Untuk: Install langsung di device
- Distribusi: Manual sharing

### AAB (Play Store)
- File: `app-release.aab`
- Ukuran: ~30-40 MB
- Untuk: Upload ke Google Play Console
- Distribusi: Play Store

---

## ⚠️ Important Notes

### RTDB Configuration
- ✅ Menggunakan Firebase Realtime Database (BUKAN Firestore)
- ✅ Path: `vue-firebase/newDataPatient` & `vue-firebase/tempDataPatient`
- ✅ Format sesuai dengan sistem Vue.js yang ada

### Permissions Required
- Camera (untuk scan KTP)
- Internet (untuk OCR & Firebase)
- Storage (untuk simpan foto KTP lokal)

### API Keys
- Gemini API Key: Stored di Firebase RTDB
- Firebase: Configured via `google-services.json`

---

## 🐛 Common Issues

### "Keystore not found"
➡️ Pastikan path di `key.properties` benar (gunakan `/` bukan `\`)

### "Wrong password"
➡️ Password di `key.properties` harus sama dengan saat create keystore

### "Firebase not initialized"
➡️ Pastikan `google-services.json` ada di `android/app/`

### "OCR failed"
➡️ Pastikan Gemini API Key sudah configured di Firebase

---

## 📊 Build Time Estimates

- **First time**: 10-15 menit
- **Subsequent builds**: 5-8 menit
- **Clean build**: 8-12 menit

---

## 🎉 Ready to Build?

### Option 1: Automated (Recommended)
```bash
build_release.bat
```

### Option 2: Manual
```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter build apk --release
flutter build appbundle --release
```

---

**Version**: 1.0.0+1  
**Last Updated**: 18 November 2025  
**Status**: ✅ Ready for Production  

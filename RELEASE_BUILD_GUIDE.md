# 📦 Panduan Build Release APK - SiLAKES Scanner

## Langkah 1: Persiapan Signing Key

### Membuat Keystore (Jika Belum Ada)

Jalankan command berikut di terminal:

```bash
keytool -genkey -v -keystore D:\Project APP\silakes-scanner-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias silakes-scanner
```

**Informasi yang akan ditanyakan:**
- Password keystore: `[Buat password yang kuat dan simpan!]`
- Nama dan organisasi: `LabKesDa Sumenep`
- Kota: `Sumenep`
- Provinsi: `Jawa Timur`
- Negara: `ID`

**PENTING:** Simpan password dan keystore file dengan AMAN! Jangan pernah hilang!

---

## Langkah 2: Konfigurasi Signing

### Buat file `key.properties`

Lokasi: `D:\Project APP\silakes_scanner\android\key.properties`

Isi file:
```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=silakes-scanner
storeFile=D:/Project APP/silakes-scanner-release-key.jks
```

**Ganti:**
- `YOUR_STORE_PASSWORD` dengan password keystore Anda
- `YOUR_KEY_PASSWORD` dengan password key Anda (bisa sama dengan store password)

---

## Langkah 3: Update Build Configuration

File `android/app/build.gradle.kts` sudah dikonfigurasi otomatis untuk membaca `key.properties`.

---

## Langkah 4: Update Version

Edit `pubspec.yaml`:
```yaml
version: 1.0.0+1
```

Format: `MAJOR.MINOR.PATCH+BUILD_NUMBER`
- Untuk update: `1.0.1+2`, `1.1.0+3`, dll

---

## Langkah 5: Clean & Build Release APK

### Clean Project
```bash
cd "D:\Project APP\silakes_scanner"
flutter clean
flutter pub get
```

### Build Release APK
```bash
flutter build apk --release
```

### Build App Bundle (Untuk Play Store)
```bash
flutter build appbundle --release
```

---

## Langkah 6: Lokasi File Output

### APK:
```
D:\Project APP\silakes_scanner\build\app\outputs\flutter-apk\app-release.apk
```

### App Bundle (AAB):
```
D:\Project APP\silakes_scanner\build\app\outputs\bundle\release\app-release.aab
```

---

## Langkah 7: Testing Release Build

### Install di Device
```bash
flutter install --release
```

Atau manual via ADB:
```bash
adb install build\app\outputs\flutter-apk\app-release.apk
```

---

## 📋 Checklist Sebelum Release

- [ ] Semua fitur sudah ditest
- [ ] Tour guide berfungsi dengan baik
- [ ] OCR validation bekerja
- [ ] Delete history berfungsi
- [ ] Badge status (Hijau/Kuning) tampil
- [ ] Edit & Resend berfungsi
- [ ] Firebase connection OK
- [ ] Gemini API Key configured
- [ ] No debug logs in production
- [ ] App icon updated
- [ ] Version number updated
- [ ] Keystore tersimpan AMAN

---

## 🔧 Troubleshooting

### Error: "Keystore not found"
- Pastikan path di `key.properties` benar
- Gunakan forward slash (/) bukan backslash (\)

### Error: "Wrong password"
- Pastikan password di `key.properties` benar
- Password harus sama dengan saat create keystore

### Build terlalu lama
- Normal untuk release build pertama (5-15 menit)
- Selanjutnya lebih cepat

### APK terlalu besar
- Release APK sudah di-obfuscate dan shrink
- Ukuran normal: 30-50MB

---

## 📱 Distribusi

### Google Play Store
1. Upload `app-release.aab` (App Bundle)
2. Isi metadata (deskripsi, screenshot, dll)
3. Submit untuk review

### Direct Install
1. Share `app-release.apk`
2. User perlu enable "Install from Unknown Sources"
3. Install APK

---

## 🔐 Security Notes

### JANGAN commit ke Git:
- `key.properties`
- `*.jks` (keystore file)
- Password dalam bentuk apapun

### Backup yang WAJIB:
- Keystore file (`.jks`)
- Password keystore
- File `key.properties`

Simpan di tempat yang aman (cloud storage pribadi, USB, dll)

---

## 📊 Build Variants

### Debug Build (Development)
```bash
flutter build apk --debug
```
- Dengan debug info
- Ukuran lebih besar
- Bisa debug di Android Studio

### Profile Build (Testing Performance)
```bash
flutter build apk --profile
```
- Performance profiling enabled
- Untuk test performance

### Release Build (Production)
```bash
flutter build apk --release
```
- Optimized & obfuscated
- Ukuran terkecil
- Untuk distribusi

---

## 🎯 Next Steps After Build

1. **Test di Multiple Devices**
   - Test di Android versi berbeda
   - Test ukuran layar berbeda
   - Test dengan koneksi lambat

2. **Prepare Play Store Assets**
   - Icon (512x512px)
   - Feature graphic (1024x500px)
   - Screenshots (min 2, max 8)
   - Deskripsi aplikasi
   - Privacy policy URL

3. **Create Release Notes**
   - Fitur baru
   - Bug fixes
   - Improvements

---

**Last Updated**: 18 November 2025  
**Version**: 1.0.0  
**Build**: Ready for Release  

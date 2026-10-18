# 🔥 YOUR TASK 1: Firebase Configuration

Aplikasi SiLAKES Scanner membutuhkan Firebase Realtime Database untuk menyimpan data pasien. Berikut langkah-langkah yang harus Anda lakukan:

## 📋 Langkah-Langkah

### 1. Buat Firebase Project
1. Buka [Firebase Console](https://console.firebase.google.com/)
2. Klik "Add Project" atau "Tambah Proyek"
3. Beri nama project: **SiLAKES Scanner** (atau nama lain sesuai keinginan)
4. Nonaktifkan Google Analytics (opsional)
5. Klik "Create Project"

### 2. Setup Firebase Realtime Database
1. Di Firebase Console, pilih project Anda
2. Klik menu **"Realtime Database"** di sidebar kiri
3. Klik **"Create Database"**
4. Pilih lokasi: **Singapore (asia-southeast1)** atau terdekat dengan Indonesia
5. Pilih mode: **"Start in test mode"** (untuk development)
   ```json
   {
     "rules": {
       ".read": true,
       ".write": true
     }
   }
   ```
   ⚠️ **PENTING**: Untuk production, ubah rules menjadi lebih secure!

### 3. Catat Database URL
1. Setelah database dibuat, lihat URL database Anda
2. URL berbentuk: `https://YOUR-PROJECT-ID-default-rtdb.firebaseio.com/`
3. Catat URL ini, akan digunakan di langkah selanjutnya

### 4. Setup Android App
1. Di Firebase Console, klik ikon **Android** (⚙️)
2. Masukkan Android package name: `id.labkesdasumenep.silakes.silakes_scanner`
3. Masukkan App nickname: **SiLAKES Scanner Android**
4. Klik "Register app"
5. **Download file `google-services.json`**
6. Copy file `google-services.json` ke folder:
   ```
   D:\Project APP\silakes_scanner\android\app\google-services.json
   ```

### 5. Update Android Configuration
File `android/app/build.gradle` sudah dikonfigurasi otomatis, tapi pastikan:

```gradle
// android/build.gradle (project level) - sudah ada
dependencies {
    classpath 'com.google.gms:google-services:4.4.0'
}

// android/app/build.gradle - sudah ada
apply plugin: 'com.google.gms.google-services'
```

### 6. Setup iOS App (Opsional jika akan build iOS)
1. Di Firebase Console, klik ikon **iOS** (🍎)
2. Masukkan iOS bundle ID: `id.labkesdasumenep.silakes.silakesScanner`
3. Download file `GoogleService-Info.plist`
4. Buka Xcode, tambahkan file ke project di `ios/Runner/`

### 7. Update App Config
Edit file `lib/core/config/app_config.dart`:

```dart
// Ganti dengan Database URL Anda
static const String firebaseRealtimeDatabaseUrl = 'https://YOUR-PROJECT-ID-default-rtdb.firebaseio.com';
```

### 8. Update Encryption Key
Di file yang sama (`app_config.dart`), ganti encryption key dengan key yang sama dengan backend Laravel:

```dart
// Harus sama dengan yang ada di Laravel .env: FLUTTER_ENCRYPTION_KEY
static const String flutterEncryptionKey = 'YOUR_32_CHARACTER_SHARED_KEY_HERE';
```

⚠️ **PENTING**: 
- Key harus **32 karakter** (256-bit)
- Harus **sama persis** dengan yang ada di backend Laravel
- Contoh key yang baik: `my-super-secret-256-bit-key--`

### 9. Testing
Setelah semua langkah di atas selesai:

```bash
cd "D:\Project APP\silakes_scanner"
flutter run
```

Scan KTP dan cek apakah data masuk ke Firebase Realtime Database di Firebase Console.

---

## 🔒 Security Rules untuk Production

Setelah testing selesai, ubah Firebase Realtime Database Rules menjadi:

```json
{
  "rules": {
    "patients": {
      ".read": "auth != null",
      ".write": "auth != null",
      "$patientId": {
        ".validate": "newData.hasChildren(['nik', 'nama', 'scanned_at'])"
      }
    }
  }
}
```

Atau gunakan rules yang lebih spesifik sesuai kebutuhan backend Laravel Anda.

---

## 📝 Checklist

- [ ] Firebase project dibuat
- [ ] Realtime Database aktif
- [ ] `google-services.json` sudah di copy ke `android/app/`
- [ ] Database URL sudah diupdate di `app_config.dart`
- [ ] Encryption key sudah diupdate di `app_config.dart`
- [ ] Aplikasi berjalan tanpa error
- [ ] Data berhasil masuk ke Firebase saat scan KTP

---

## ❓ Troubleshooting

### Error: "FirebaseException: No Firebase App '[DEFAULT]' has been created"
**Solusi**: Pastikan `google-services.json` sudah ada di folder yang benar dan rebuild aplikasi.

### Error: "Failed to initialize Firebase"
**Solusi**: 
1. Cek internet connection
2. Pastikan Firebase project aktif
3. Cek konfigurasi `google-services.json`

### Data tidak masuk ke Firebase
**Solusi**:
1. Cek Firebase Rules (pastikan write: true untuk testing)
2. Cek Database URL sudah benar
3. Lihat log error di console

---

## 📞 Support

Jika ada masalah, lihat log error di console:
```bash
flutter run --verbose
```

Good luck! 🚀

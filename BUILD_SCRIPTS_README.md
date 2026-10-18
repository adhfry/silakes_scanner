# 🔧 Build Scripts - SiLAKES Scanner

## 📝 Available Scripts

### 1. `build_fix_and_release.bat` ⭐ **RECOMMENDED**
**Script utama untuk build APK release**

**Apa yang dilakukan:**
- Stop Gradle daemon
- Clean Flutter project
- Hapus semua cache (build, .dart_tool, gradle cache)
- Get dependencies baru
- Generate Hive adapters
- Build APK release
- Tampilkan lokasi APK

**Kapan digunakan:**
- Saat ingin build APK untuk distribusi
- Saat ada error "Gradle daemon disappeared"
- Saat ada error cache/build

**Cara pakai:**
```bash
# Double click atau:
build_fix_and_release.bat
```

**Output:**
```
build\app\outputs\flutter-apk\app-release.apk
```

**Waktu:** 5-10 menit (first build)

---

### 2. `force_clean.bat` 🧹
**Deep clean - hapus semua cache**

**Apa yang dilakukan:**
- Kill semua proses Java/Gradle
- Flutter clean
- Hapus build folders (semua)
- Hapus Android gradle cache
- Clear pub-cache
- Get dependencies fresh

**Kapan digunakan:**
- Saat build script gagal berulang kali
- Saat ada error cache yang aneh
- Saat ingin reset project ke clean state

**Cara pakai:**
```bash
# Double click atau:
force_clean.bat
```

**WARNING:** Akan hapus SEMUA cache! Proses download dependencies dari awal.

**Waktu:** 2-3 menit + waktu download

---

### 3. `test_build.bat` 🧪
**Quick test build (debug mode)**

**Apa yang dilakukan:**
- Clean cepat
- Get dependencies
- Build DEBUG APK (lebih cepat)

**Kapan digunakan:**
- Saat ingin test build cepat
- Saat ingin cek apakah ada error compile
- BUKAN untuk distribusi (debug only!)

**Cara pakai:**
```bash
test_build.bat
```

**Output:**
```
build\app\outputs\flutter-apk\app-debug.apk
```

**Waktu:** 3-5 menit

---

## 🚀 Recommended Workflow

### First Time Build:
```bash
1. force_clean.bat          # Reset project
2. build_fix_and_release.bat  # Build release APK
```

### Normal Build:
```bash
build_fix_and_release.bat  # Langsung build
```

### When Errors Occur:
```bash
1. force_clean.bat          # Deep clean
2. build_fix_and_release.bat  # Try build again
```

### Quick Testing:
```bash
test_build.bat  # Debug build untuk test cepat
```

---

## 🐛 Common Errors & Solutions

### Error: "Gradle daemon disappeared"
**Solution:**
```bash
build_fix_and_release.bat
```
Script ini sudah handle dengan stop gradle daemon dulu.

### Error: "Could not close incremental caches"
**Solution:**
```bash
1. force_clean.bat
2. build_fix_and_release.bat
```

### Error: "Build timed out"
**Solution:**
- Pastikan internet stabil
- Close aplikasi lain yang berat
- Jalankan ulang: `build_fix_and_release.bat`

### Error: "Out of memory"
**Solution:**
- Close aplikasi lain
- Restart komputer
- Run: `force_clean.bat` lalu `build_fix_and_release.bat`

### Error: "Unable to resolve dependency"
**Solution:**
```bash
1. Check internet connection
2. flutter pub cache clean
3. build_fix_and_release.bat
```

---

## ⚙️ Build Configuration

### Current Settings:
- **Min SDK:** 21 (Android 5.0)
- **Target SDK:** Latest
- **Shrinking:** OFF (untuk first build)
- **Minification:** OFF (untuk first build)
- **Signing:** Debug key (jika tidak ada key.properties)

### For Production:
1. Create `android/key.properties`:
```properties
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=silakes-scanner
storeFile=D:/Project APP/silakes-scanner-release-key.jks
```

2. Generate keystore:
```bash
keytool -genkey -v -keystore silakes-scanner-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias silakes-scanner
```

3. Run build:
```bash
build_fix_and_release.bat
```

---

## 📊 Build Output

### APK Location:
```
build\app\outputs\flutter-apk\app-release.apk
```

### Expected Size:
- **Without shrinking:** 40-60 MB
- **With shrinking:** 30-45 MB (enable di build.gradle.kts nanti)

### What to Check:
✅ APK berhasil di-generate  
✅ Size reasonable (< 100MB)  
✅ Bisa di-install di device  
✅ Semua fitur berfungsi  

---

## 🔍 Debugging Build Issues

### Enable Verbose Output:
Edit `build_fix_and_release.bat`, ganti:
```batch
call flutter build apk --release --no-shrink
```

Jadi:
```batch
call flutter build apk --release --no-shrink --verbose
```

### Check Gradle Output:
```bash
cd android
gradlew assembleRelease --stacktrace
```

### Check Flutter Doctor:
```bash
flutter doctor -v
```

---

## 📝 Notes

### Build Time:
- **First time:** 10-15 minutes
- **Incremental:** 5-8 minutes
- **After clean:** 8-12 minutes

### Disk Space Required:
- Minimum: 2 GB free
- Recommended: 5 GB free

### RAM Required:
- Minimum: 4 GB
- Recommended: 8 GB

### Internet:
- Required untuk download dependencies
- ~500 MB download (first time)

---

## 🎯 Quick Reference

| Script | Purpose | Time | When to Use |
|--------|---------|------|-------------|
| `build_fix_and_release.bat` | Build APK | 5-10 min | Normal build, has errors |
| `force_clean.bat` | Deep clean | 2-3 min | Persistent errors |
| `test_build.bat` | Quick test | 3-5 min | Testing only |

---

## ✅ Checklist Before Build

- [ ] Internet connection stable
- [ ] Enough disk space (5 GB+)
- [ ] Close other heavy apps
- [ ] Flutter doctor shows no critical issues
- [ ] Android SDK installed
- [ ] `google-services.json` in `android/app/`

---

## 🆘 Support

Jika masih ada masalah setelah mencoba semua script:

1. Check Flutter version: `flutter --version`
2. Check Java version: `java -version`
3. Update Flutter: `flutter upgrade`
4. Reinstall dependencies: `force_clean.bat`
5. Contact IT support

---

**Last Updated:** 18 November 2025  
**Status:** ✅ Ready to Use  

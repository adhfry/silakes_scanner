# 🎯 Tour Guide Documentation - SiLAKES Scanner

## Overview
Tour guide interaktif yang memandu pengguna baru menggunakan aplikasi SiLAKES Scanner. Tour guide akan muncul otomatis saat pertama kali menggunakan aplikasi.

## Fitur Tour Guide

### 1. **Auto-Show on First Launch**
- Tour guide otomatis muncul saat aplikasi pertama kali digunakan
- Tersimpan di SharedPreferences untuk tracking status
- Setiap halaman memiliki tour guide tersendiri

### 2. **Tour Progress Tracking**
- Dashboard Tour
- Camera Tour  
- Preview/Edit Tour
- Status tersimpan per-halaman

### 3. **Interactive Controls**
- **Tombol "Paham"**: Lanjut ke tour berikutnya
- **Tombol "Lewati Semua"**: Skip semua tour (termasuk halaman lain)
- User bisa reset tour kapan saja dari menu

---

## Tour Guide Per Halaman

### 📱 **Dashboard Screen Tour**

#### Tour Point 1: Logo & Welcome
- **Target**: Logo SiLAKES di AppBar
- **Judul**: "Selamat Datang di SiLAKES Scanner! 🏥"
- **Penjelasan**:
  - Pengenalan aplikasi
  - Fungsi utama: scan KTP dan registrasi otomatis
  - Ajakan untuk memulai tour

#### Tour Point 2: Refresh API Button
- **Target**: Tombol refresh di AppBar
- **Judul**: "Tombol Refresh API Key 🔄"
- **Penjelasan**:
  - Fungsi refresh API Key Gemini
  - Kapan harus menggunakan (jika OCR gagal)
  - API Key dari Firebase

#### Tour Point 3: Menu (3 Dots)
- **Target**: Icon menu (⋮) di AppBar
- **Judul**: "Menu Aplikasi ⚙️"
- **Penjelasan**:
  - Hapus semua riwayat
  - Reset tour guide
  - Opsi pengaturan lainnya

#### Tour Point 4: Scan Button
- **Target**: Tombol "Mulai Scan" di tengah
- **Judul**: "Tombol Mulai Scan 📸"
- **Penjelasan**:
  - Tombol utama aplikasi
  - 4 langkah proses: buka kamera → foto KTP → ekstrak data → simpan riwayat
  - Otomatis cek status registrasi pasien

#### Tour Point 5: History Header
- **Target**: Header "Riwayat Scan"
- **Judul**: "Riwayat Scan 📋"
- **Penjelasan**:
  - Menampilkan semua KTP yang sudah di-scan
  - Jumlah data total
  - Bisa scroll untuk lihat semua

#### Tour Point 6: History List Item (jika ada data)
- **Target**: Item pertama di list
- **Judul**: "Item Riwayat & Status Registrasi 🏷️"
- **Penjelasan Detail**:
  - **Informasi yang ditampilkan**:
    - Nama & NIK pasien
    - Badge status (Hijau/Kuning)
    - Tempat/tanggal lahir
    - Alamat
    - Waktu scan
  
  - **Untuk Pasien BELUM TERDAFTAR**:
    - Tombol "Edit": Edit data sebelum kirim
    - Tombol "Kirim": Langsung kirim ke sistem
    - Tombol "Hapus": Hapus dari riwayat
  
  - **Untuk Pasien SUDAH TERDAFTAR**:
    - Hanya tombol "Hapus"
  
  - Klik item untuk detail lengkap

---

### 📸 **Camera Screen Tour**

#### Tour Point 1: Overlay Guide
- **Target**: Frame kotak putih di tengah layar
- **Judul**: "Area Panduan KTP 📋"
- **Penjelasan Lengkap**:
  - KTP harus di dalam kotak putih
  - Posisi horizontal (memanjang kiri-kanan)
  - Semua teks KTP harus terlihat jelas
  - Hindari bayangan/pantulan cahaya
  - Gunakan pencahayaan cukup
  - **Tips**: Letakkan KTP di permukaan datar

#### Tour Point 2: Flash Button
- **Target**: Tombol flash di kanan atas
- **Judul**: "Tombol Flash 💡"
- **Penjelasan**:
  - **Flash OFF**: Tanpa flash (default)
  - **Flash ON**: Selalu pakai flash
  - **Flash AUTO**: Flash otomatis
  - Kapan menggunakan flash
  - Hindari flash jika ada pantulan di KTP

#### Tour Point 3: Gallery Button
- **Target**: Tombol galeri di kiri bawah
- **Judul**: "Pilih dari Galeri 🖼️"
- **Penjelasan**:
  - Tidak perlu foto baru
  - Pilih foto KTP dari galeri
  - Gunakan foto yang sudah bagus
  - Tidak perlu scan ulang
  - Foto langsung diproses OCR

#### Tour Point 4: Capture Button
- **Target**: Tombol bulat besar di tengah bawah
- **Judul**: "Tombol Ambil Foto 📸"
- **Penjelasan Lengkap**:
  - Tombol utama untuk ambil foto
  
  - **Langkah-langkah**:
    1. Pastikan KTP di dalam kotak
    2. Pegang HP stabil
    3. Pastikan fokus jelas
    4. Klik tombol untuk foto
  
  - **Setelah Foto**:
    - AI ekstrak data otomatis (OCR)
    - Data bisa diedit jika salah
    - Foto & data tersimpan di riwayat

---

### ✏️ **Preview/Edit Screen Tour**

#### Tour Point 1: Image Preview
- **Target**: Foto KTP di atas
- **Judul**: "Preview Foto KTP 🖼️"
- **Penjelasan**:
  - Foto KTP hasil scan
  - Support zoom: pinch to zoom
  - Support pan: geser untuk melihat detail
  - Tombol reset zoom di kanan atas
  - Drag handle untuk resize tinggi preview

#### Tour Point 2: Form Fields
- **Target**: Form input data
- **Judul**: "Form Data Pasien 📝"
- **Penjelasan Lengkap**:
  - Data hasil OCR AI
  - **Wajib diisi** (tanda *):
    - NIK (16 digit)
    - Nama Lengkap
    - Tempat Lahir
    - Tanggal Lahir
    - Jenis Kelamin
    - Alamat
  
  - **Opsional**:
    - RT/RW
    - Kel/Desa
    - Kecamatan
    - Agama
    - Status Perkawinan
    - Pekerjaan
  
  - Edit jika ada data yang salah
  - Validasi otomatis sebelum kirim

#### Tour Point 3: Submit Button
- **Target**: Tombol "Simpan Data" di bawah
- **Judul**: "Simpan & Kirim Data 📤"
- **Penjelasan Lengkap**:
  - Proses saat klik tombol:
    1. Validasi form (wajib terisi)
    2. Cek NIK di database SiLAKES
    3. Jika sudah terdaftar: Update status & beri tahu
    4. Jika belum: Kirim ke Firebase
    5. Simpan ke riwayat lokal
    6. Kembali ke dashboard
  
  - Loading indicator saat proses
  - Notifikasi sukses/gagal

---

## 🔄 Reset & Re-show Tour

### Cara Reset Tour:
1. Buka Dashboard
2. Klik menu (⋮) di kanan atas
3. Pilih "Tampilkan Panduan"
4. Konfirmasi
5. Tour akan dimulai dari awal

### Skip All Tours:
- Klik "Lewati Semua" pada tour manapun
- Semua tour di halaman lain akan di-skip
- Bisa di-reset kapan saja dari menu

---

## 🎨 Design & UX

### Visual Style:
- **Background Overlay**: Blur dengan shadow warna primary
- **Tour Card**: White background dengan shadow
- **Icon**: Lightbulb dengan gradient primary
- **Typography**: Jelas dan mudah dibaca
- **Spacing**: Konsisten dengan app theme

### Button Colors:
- **"Paham"**: Primary color (Biru)
- **"Lewati Semua"**: Secondary color (Abu)

### Animation:
- Smooth transition antar tour point
- Focus highlight pada target widget
- Fade in/out tour card

---

## 💾 Technical Implementation

### Storage:
```dart
// SharedPreferences Keys
'tour_dashboard_completed'  // Boolean
'tour_camera_completed'     // Boolean
'tour_preview_completed'    // Boolean
'app_first_launch'          // Boolean
```

### Service Methods:
```dart
TourGuideService:
- isFirstLaunch()
- isDashboardTourCompleted()
- completeDashboardTour()
- isCameraTourCompleted()
- completeCameraTour()
- isPreviewTourCompleted()
- completePreviewTour()
- skipAllTours()
- resetAllTours()
```

### Dependencies:
- `tutorial_coach_mark: ^1.2.11`
- `shared_preferences: ^2.2.2`

---

## 📱 User Flow

### First Launch:
1. User install & buka app
2. Dashboard tour auto-show (6 points)
3. User klik "Paham" atau "Lewati Semua"
4. Jika paham semua → camera tour ready
5. Saat buka camera → camera tour auto-show (4 points)
6. Setelah foto → preview tour auto-show (3 points)

### Reset Tour:
1. User pilih "Tampilkan Panduan" di menu
2. Dashboard tour dimulai ulang
3. Camera & Preview tour juga di-reset
4. Ready untuk tour ulang

---

## ✅ Checklist Implementasi

### ✅ Dashboard Tour
- [x] 6 tour points lengkap
- [x] Keys pada semua target widget
- [x] Auto-show on first launch
- [x] Save completion state
- [x] Reset tour dari menu

### ✅ Camera Tour
- [x] 4 tour points lengkap
- [x] Keys pada target widgets
- [x] Auto-show setelah dashboard
- [x] Skip all functionality

### 🔄 Preview Tour (To be completed)
- [ ] Add tour keys to widgets
- [ ] Create tour points
- [ ] Auto-show on first preview
- [ ] Completion tracking

---

## 🎓 Tips untuk User

### Cara Maksimalkan Tour Guide:
1. **Baca dengan teliti** - Setiap tour berisi informasi penting
2. **Jangan skip** di penggunaan pertama - Tour membantu memahami app
3. **Coba sendiri** setelah tour - Praktik langsung lebih mudah dipahami
4. **Reset jika lupa** - Bisa tampilkan panduan kapan saja

### Best Practices:
- Ikuti tour dari awal sampai akhir di first launch
- Gunakan fitur reset jika perlu refresher
- Setiap tour point menjelaskan "WHY" dan "HOW"

---

## 📝 Notes

- Tour guide bersifat **non-blocking** - user bisa skip kapan saja
- **Persistent** - status tersimpan walaupun app ditutup
- **Contextual** - tour muncul sesuai halaman yang dibuka
- **Comprehensive** - semua fitur dijelaskan tanpa terkecuali
- **User-friendly** - bahasa yang mudah dipahami

---

## 🔮 Future Enhancements

Fitur yang bisa ditambahkan:
- [ ] Video tutorial per fitur
- [ ] Interactive demo mode
- [ ] Gamification (badges untuk completing tour)
- [ ] Multi-language support
- [ ] Voice-over narration
- [ ] Tooltip on-demand (long press)

---

**Last Updated**: 18 November 2025
**Version**: 1.0.0
**Status**: ✅ Dashboard & Camera Complete | 🔄 Preview In Progress

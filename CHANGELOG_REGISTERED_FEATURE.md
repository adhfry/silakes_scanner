# Changelog - Fitur Status Registrasi Pasien

## Tanggal: 18 November 2025

### ✨ Fitur Baru yang Ditambahkan

#### 1. **Status Registrasi Pasien**
- Menambahkan field `isRegistered` dan `isSubmitted` pada model `PatientData`
- Status registrasi otomatis dicek saat scan KTP pertama kali
- Status tersimpan di local history untuk tracking

#### 2. **Badge Status di History**
- **Badge Hijau (Terdaftar)**: Pasien sudah terdaftar di sistem SiLAKES
  - Background: `#E8F5E9` (light green)
  - Icon: `check_circle`
  - Text color: `#2E7D32` (dark green)
  
- **Badge Kuning (Belum Terdaftar)**: Pasien belum terdaftar
  - Background: `#FFF9C4` (light yellow)
  - Icon: `pending`
  - Text color: `#F57C00` (dark orange)

#### 3. **Tombol Aksi Berdasarkan Status**

##### Untuk Pasien yang **SUDAH TERDAFTAR**:
- Hanya menampilkan tombol **Hapus** (delete)
- Tidak ada opsi Edit dan Kirim

##### Untuk Pasien yang **BELUM TERDAFTAR**:
- **Tombol Hapus**: Menghapus dari history
- **Tombol Edit**: Mengedit data dan foto KTP yang tersimpan
  - Foto tidak perlu diambil ulang
  - Data bisa diedit sebelum dikirim
  - OCR tidak dijalankan lagi (menggunakan data tersimpan)
- **Tombol Kirim (Resend)**: Mengirim data langsung ke Firebase
  - Otomatis cek NIK terlebih dahulu
  - Jika sudah terdaftar, update status menjadi `registered: true`
  - Jika belum, kirim ke Firebase dan update status `submitted: true`

#### 4. **Halaman Edit dari History**
- Implementasi `PreviewEditScreenFromHistory` widget baru
- Menampilkan foto KTP yang sudah di-scan sebelumnya
- Support zoom & pan pada preview foto
- Form bisa diedit dengan validasi lengkap
- Otomatis cek status registrasi saat submit

#### 5. **Null Safety & Error Handling**
- Semua operasi async dilindungi dengan `mounted` check
- Validasi path foto sebelum membuka editor
- Pengecekan file exists sebelum load image
- Error handling yang proper di semua operasi

### 🔄 Perubahan pada File

#### Models
- `lib/core/models/patient_data.dart`
  - Menambah field `isRegistered` dan `isSubmitted`
  - Update `copyWith()` method
  - Update `toJson()` dan `fromJson()`
  - Field `imagePath` untuk menyimpan lokasi foto

#### Widgets
- `lib/features/dashboard/widgets/history_list_item.dart`
  - Menambah callback `onEdit` dan `onResend`
  - Implement `_buildStatusBadge()` untuk badge status
  - Menambah section tombol aksi conditional
  - UI modern dengan spacing yang proper

#### Screens
- `lib/features/dashboard/screen/dashboard_screen.dart`
  - Implement `_editPatient()` untuk buka editor
  - Implement `_resendPatient()` untuk kirim ulang data
  - Pengecekan NIK otomatis sebelum kirim
  - Update status registrasi di history

- `lib/features/scanner/screen/preview_edit_screen.dart`
  - Menambah parameter `existingData` di `PreviewEditScreen`
  - Membuat `PreviewEditScreenFromHistory` widget baru
  - Support load data dari history tanpa OCR
  - Validasi dan submit dengan cek registrasi

### 🎨 Update Logo

#### Logo Baru
- File: `assets/images/silakes-scanner-logo.png`
- Digunakan di:
  - Dashboard AppBar
  - Launcher icon (Android)
  - Adaptive icon

#### Perubahan
- `pubspec.yaml`: Update path launcher icon
- `dashboard_screen.dart`: Update path logo di AppBar
- Generate ulang launcher icons dengan `flutter_launcher_icons`

### 📋 Flow Kerja Baru

#### Saat Scan KTP Baru:
1. User scan KTP dengan kamera
2. OCR ekstrak data dari foto
3. **Cek NIK** di database SiLAKES
4. Simpan ke history dengan status:
   - `isRegistered: true` jika sudah terdaftar
   - `isRegistered: false` jika belum terdaftar
5. Simpan path foto untuk keperluan edit

#### Untuk Pasien Belum Terdaftar:
**Opsi 1 - Edit:**
1. User klik tombol "Edit"
2. Buka `PreviewEditScreenFromHistory`
3. Tampilkan foto KTP yang sudah disimpan
4. Load data dari history (tanpa OCR)
5. User edit data jika perlu
6. Submit → cek NIK → kirim ke Firebase

**Opsi 2 - Kirim Langsung:**
1. User klik tombol "Kirim"
2. Konfirmasi dialog
3. **Cek NIK** di database
   - Jika sudah terdaftar: Update status di history
   - Jika belum: Kirim ke Firebase
4. Refresh history list

### 🛡️ Null Safety

Semua operasi yang menggunakan `BuildContext` sudah dilindungi dengan check `mounted`:
```dart
if (mounted) {
  Helpers.showSuccess(context, 'Success message');
}
```

Validasi path dan file:
```dart
if (patient.imagePath == null || patient.imagePath!.isEmpty) {
  // Handle missing path
}

final imageFile = File(patient.imagePath!);
if (!await imageFile.exists()) {
  // Handle missing file
}
```

### 🎯 UI/UX Improvements

1. **Badge Status**: Visual indicator yang jelas untuk status registrasi
2. **Conditional Buttons**: Mengurangi clutter, hanya tampilkan tombol yang relevan
3. **Color Coding**: 
   - Hijau = Aman/Terdaftar
   - Kuning = Perlu Action/Belum Terdaftar
4. **Consistent Design**: Mengikuti prinsip UI/UX dari halaman lain
5. **Loading States**: Feedback visual saat proses berlangsung

### 🚀 Testing

Untuk testing fitur ini:
1. Scan KTP baru yang NIK-nya belum terdaftar
2. Cek badge "Belum Terdaftar" muncul
3. Test tombol Edit → buka editor → edit data → submit
4. Test tombol Kirim → konfirmasi → data terkirim
5. Cek status berubah setelah registrasi

### 📝 Notes

- Fitur ini meningkatkan efisiensi workflow registrasi pasien
- Menghindari registrasi duplikat dengan pengecekan NIK
- User bisa review dan edit data sebelum kirim
- Foto KTP tersimpan untuk referensi
- Status tracking yang jelas di history

### ⚙️ Technical Details

**Dependencies yang digunakan:**
- `hive` & `hive_flutter`: Local storage
- `flutter_riverpod`: State management
- `http`: API calls
- `firebase_database`: Firebase Realtime Database

**Hive Type Adapters:**
- Regenerate dengan: `flutter pub run build_runner build --delete-conflicting-outputs`

**Launcher Icons:**
- Generate dengan: `flutter pub run flutter_launcher_icons`

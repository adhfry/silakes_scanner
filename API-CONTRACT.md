# 🔌 API Contract - SiLAKES Scanner

Dokumentasi lengkap untuk API endpoints yang dibutuhkan oleh aplikasi Flutter.

---

## 📡 Base Configuration

```dart
Base URL: https://api.silakes.labkesdasumenep.id/api/v1
Timeout: 30 seconds
Protocol: HTTPS
Content-Type: application/json
```

---

## 🔐 Endpoint 1: Get Gemini API Key

Endpoint untuk mengambil API key Gemini yang terenkripsi.

### Request

```http
GET /config/gemini-key HTTP/1.1
Host: api.silakes.labkesdasumenep.id
Accept: application/json
```

**No authentication required** (public endpoint)

### Response Success (200 OK)

```json
{
  "status": "success",
  "data": {
    "encrypted_key": "4BDTWBYq3wdAZC9JjcGkWmWSpElYjcYchfQpvk1BPYzjm7Pcvf+ifboHfkH1MC4J",
    "iv": "uU22IFzMLXGEPumisE+urw=="
  },
  "message": "Berhasil mengambil API Key Gemini."
}
```

**Field Description:**

| Field | Type | Description |
|-------|------|-------------|
| `status` | string | Status response: "success" atau "error" |
| `data.encrypted_key` | string | API key Gemini yang di-encrypt dengan AES-256-CBC, lalu di-encode base64 |
| `data.iv` | string | Initialization Vector (IV) untuk dekripsi, di-encode base64 |
| `message` | string | Pesan informasi dari server |

### Response Error (404 Not Found)

```json
{
  "status": "error",
  "message": "API Key Gemini belum diatur di server.",
  "data": null
}
```

### Response Error (500 Internal Server Error)

```json
{
  "status": "error",
  "message": "Gagal mengambil API key: [error message]",
  "data": null
}
```

### Laravel Implementation Example

```php
// app/Http/Controllers/Api/V1/ConfigController.php

public function getGeminiKey(): JsonResponse
{
    $setting = Setting::where('key', 'GEMINI_API_KEY')->first();

    if (!$setting) {
        return response()->json([
            'error' => 'API Key Gemini belum diatur di server.'
        ], 404);
    }

    return response()->json([
        'status' => 'success',
        'data' => [
            'encrypted_key' => $setting->value, // Already base64
            'iv' => $setting->iv, // Already base64
        ],
        'message' => 'Berhasil mengambil API Key Gemini.'
    ]);
}
```

### Encryption Details

**Algorithm**: AES-256-CBC

**Process** (Laravel side):
```php
// Encryption key dari .env (32 characters)
$key = config('services.gemini.flutter_key'); // FLUTTER_ENCRYPTION_KEY

// Generate IV
$iv = openssl_random_pseudo_bytes(16); // 16 bytes untuk AES

// Encrypt
$encrypted = openssl_encrypt(
    $apiKey,
    'AES-256-CBC',
    $key,
    OPENSSL_RAW_DATA,
    $iv
);

// Store as base64
$setting->value = base64_encode($encrypted);
$setting->iv = base64_encode($iv);
```

**Process** (Flutter side):
```dart
// Decrypt
final encryptedData = encrypt_pkg.Encrypted.fromBase64(encryptedBase64);
final iv = encrypt_pkg.IV.fromBase64(ivBase64);
final key = encrypt_pkg.Key.fromUtf8(AppConfig.flutterEncryptionKey); // 32 chars

final encrypter = encrypt_pkg.Encrypter(
  encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.cbc),
);

final decrypted = encrypter.decrypt(encryptedData, iv: iv);
```

### Testing

```bash
# Test endpoint
curl -X GET https://api.silakes.labkesdasumenep.id/api/v1/config/gemini-key

# Expected response
{
  "data": {
    "api_key_encrypted": "L2xJ...",
    "iv": "a3F..."
  }
}
```

---

## 👤 Endpoint 2: Check NIK Registration

Endpoint untuk mengecek apakah NIK sudah terdaftar di database SiLAKES.

### Request

```http
GET /cek-nik/registered/{nik} HTTP/1.1
Host: api.silakes.labkesdasumenep.id
Accept: application/json
```

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `nik` | string | Yes | NIK 16 digit pasien |

**Example:**
```
GET /cek-nik/registered/3529012345678901
```

### Response Success - NIK Found (200 OK)

```json
{
  "registered": true,
  "data": {
    "id": 123,
    "nik": "3529012345678901",
    "nama": "AHMAD RIDWAN HAKIM",
    "tempat_lahir": "SUMENEP",
    "tanggal_lahir": "1990-08-15",
    "jenis_kelamin": "LAKI-LAKI",
    "alamat": "JL. TRUNOJOYO NO. 45",
    "created_at": "2024-01-15T10:30:00Z",
    "updated_at": "2024-01-15T10:30:00Z"
  }
}
```

### Response Success - NIK Not Found (200 OK or 404)

**Option 1** (Recommended - Status 200):
```json
{
  "registered": false,
  "data": null
}
```

**Option 2** (Status 404):
```json
{
  "registered": false,
  "message": "NIK tidak ditemukan"
}
```

**Note:** Flutter app handle both 200 (registered=false) and 404 as "not registered".

### Response Error (400 Bad Request)

```json
{
  "error": "NIK tidak valid. Harus 16 digit angka."
}
```

### Response Error (500 Internal Server Error)

```json
{
  "error": "Terjadi kesalahan server: [error message]"
}
```

### Laravel Implementation Example

```php
// app/Http/Controllers/Api/V1/PasienController.php

public function cekNik(string $nik): JsonResponse
{
    // Validasi NIK
    if (strlen($nik) !== 16 || !ctype_digit($nik)) {
        return response()->json([
            'error' => 'NIK tidak valid. Harus 16 digit angka.'
        ], 400);
    }

    // Cari pasien
    $pasien = Pasien::where('nik', $nik)->first();

    if ($pasien) {
        return response()->json([
            'registered' => true,
            'data' => $pasien
        ]);
    }

    // NIK not found
    return response()->json([
        'registered' => false,
        'data' => null
    ], 200);
}
```

### Route

```php
// routes/api.php

Route::prefix('v1')->group(function () {
    Route::get('/cek-nik/registered/{nik}', [PasienController::class, 'cekNik']);
});
```

### Testing

```bash
# Test with registered NIK
curl -X GET https://api.silakes.labkesdasumenep.id/api/v1/cek-nik/registered/3529012345678901

# Test with unregistered NIK
curl -X GET https://api.silakes.labkesdasumenep.id/api/v1/cek-nik/registered/1234567890123456

# Test with invalid NIK
curl -X GET https://api.silakes.labkesdasumenep.id/api/v1/cek-nik/registered/123
```

---

## 🔥 Firebase Realtime Database

Aplikasi Flutter akan mengirim data pasien baru ke Firebase RTDB dengan struktur berikut.

### Structure (Updated untuk VueJS Integration)

```
/vue-firebase
  ├── newDataPatient: true (trigger flag)
  └── tempDataPatient:
      ├── nik: "3529012345678901"
      ├── name: "AHMAD RIDWAN HAKIM"
      ├── tempat_lahir: "SUMENEP"
      ├── tgl_lahir: "15-08-1990"
      ├── gender: "LAKI-LAKI"
      ├── alamat: "JL. TRUNOJOYO NO. 45"
      ├── rt_rw: "003/002"
      ├── kel_desa: "KOLOR"
      ├── kecamatan: "KOTA SUMENEP"
      ├── agama: "ISLAM"
      ├── status_perkawinan: "KAWIN"
      ├── pekerjaan: "WIRASWASTA"
      ├── phone: "" (diisi manual di VueJS)
      ├── no_reg: "" (diisi oleh backend)
      ├── jabatan: "" (untuk pegawai)
      └── pangkat: "" (untuk pegawai)
```

### Trigger Field

**`newDataPatient: true`**

Field ini adalah **trigger** untuk VueJS frontend. Saat field ini `true`:
1. VueJS mendeteksi ada data baru dari Flutter Scanner
2. VueJS membaca data dari `tempDataPatient`
3. User di VueJS melengkapi data (phone, no_reg, jabatan, pangkat)
4. VueJS simpan ke database Laravel
5. VueJS set `newDataPatient = false` setelah selesai

**Flow:**
```
Flutter Scanner → Firebase (newDataPatient=true) → VueJS detects → 
User melengkapi data → Save to Laravel → Reset flag
```

### Firebase Rules (Development)

```json
{
  "rules": {
    ".read": true,
    ".write": true
  }
}
```

**⚠️ WARNING**: Untuk production, gunakan rules yang lebih ketat!

### Firebase Rules (Production)

```json
{
  "rules": {
    "patients": {
      ".read": "auth != null",
      ".write": "auth != null",
      "$patientId": {
        ".validate": "newData.hasChildren(['nik', 'nama', 'scanned_at', 'newDataPatient'])"
      }
    }
  }
}
```

### Backend Laravel Listener

Backend Laravel harus listen ke Firebase untuk trigger `newDataPatient`:

**Option 1**: Polling (Simple)
```php
// Schedule di Laravel
Schedule::call(function () {
    $firebase = app('firebase.database');
    $ref = $firebase->getReference('patients');
    
    $snapshot = $ref->orderByChild('newDataPatient')
                    ->equalTo(true)
                    ->getSnapshot();
    
    foreach ($snapshot->getValue() as $key => $data) {
        // Process & save to database
        Pasien::create($data);
        
        // Reset trigger
        $ref->getChild($key)->update(['newDataPatient' => false]);
    }
})->everyMinute();
```

**Option 2**: Firebase Cloud Functions (Recommended)
```javascript
// functions/index.js
exports.onNewPatient = functions.database
  .ref('/patients/{patientId}')
  .onCreate((snapshot, context) => {
    const data = snapshot.val();
    if (data.newDataPatient) {
      // Call Laravel API to save
      return axios.post('https://api.silakes.../save-patient', data);
    }
  });
```

---

## 📊 Data Flow Diagram

```
┌─────────────────┐
│  Flutter App    │
└────────┬────────┘
         │
         │ 1. GET /config/gemini-key
         ↓
┌─────────────────┐
│  Laravel API    │
└────────┬────────┘
         │
         │ 2. Return encrypted API key
         ↓
┌─────────────────┐
│  Flutter App    │
│  (Decrypt key)  │
└────────┬────────┘
         │
         │ 3. Camera scan KTP
         ↓
┌─────────────────┐
│  Gemini AI API  │
└────────┬────────┘
         │
         │ 4. Return OCR data
         ↓
┌─────────────────┐
│  Flutter App    │
│  (Parse data)   │
└────────┬────────┘
         │
         │ 5. GET /cek-nik/registered/{nik}
         ↓
┌─────────────────┐
│  Laravel API    │
└────────┬────────┘
         │
         ├─ 6a. If registered: Notify user
         │
         └─ 6b. If not: Continue to edit
                        ↓
               ┌─────────────────┐
               │  Flutter App    │
               │  (Edit & submit)│
               └────────┬────────┘
                        │
                        │ 7. Push data
                        ↓
               ┌─────────────────┐
               │ Firebase RTDB   │
               │ newDataPatient  │
               │ = true          │
               └────────┬────────┘
                        │
                        │ 8. Trigger event
                        ↓
               ┌─────────────────┐
               │  Laravel        │
               │  (Listen &      │
               │   save to DB)   │
               └─────────────────┘
```

---

## 🧪 Testing Checklist

### Endpoint 1: `/config/gemini-key`

- [ ] Returns 200 status
- [ ] Contains `data.api_key_encrypted` field
- [ ] Contains `data.iv` field
- [ ] Both fields are valid base64
- [ ] Decryption works with shared key
- [ ] Returns 404 if key not set

### Endpoint 2: `/cek-nik/registered/{nik}`

- [ ] Returns 200 for valid NIK
- [ ] Returns `registered: true` if found
- [ ] Returns `registered: false` if not found
- [ ] Returns 400 for invalid NIK
- [ ] Returns patient data if found
- [ ] Handles 16-digit validation

### Firebase Integration

- [ ] Data successfully written to RTDB
- [ ] `newDataPatient` field is `true`
- [ ] All required fields present
- [ ] Timestamp fields correct
- [ ] Backend receives trigger
- [ ] Data saved to Laravel DB
- [ ] Trigger reset after processing

---

## 🔐 Security Considerations

### 1. API Key Encryption

**✅ DO:**
- Use AES-256-CBC
- Generate unique IV per encryption
- Store IV alongside encrypted data
- Use 32-character shared key

**❌ DON'T:**
- Send plain API key in response
- Reuse IV
- Store shared key in database
- Use weak encryption

### 2. NIK Validation

**✅ DO:**
- Validate format (16 digits)
- Check type (numeric only)
- Rate limit endpoint

**❌ DON'T:**
- Accept non-numeric input
- Allow SQL injection
- Expose sensitive data

### 3. Firebase Security

**✅ DO:**
- Use authentication in production
- Validate data structure
- Set proper rules
- Monitor usage

**❌ DON'T:**
- Leave open write access
- Store sensitive data unencrypted
- Allow public read/write in prod

---

## 📝 Environment Variables

### Laravel `.env`

```env
# Base URL
APP_URL=https://api.silakes.labkesdasumenep.id

# Encryption key (MUST be 32 characters)
FLUTTER_ENCRYPTION_KEY=your-32-character-secret-key!!

# Firebase (if using Firebase Admin SDK)
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@your-project.iam.gserviceaccount.com

# Gemini API Key (stored encrypted in database)
# No need to put in .env, admin sets via panel
```

### Flutter `app_config.dart`

```dart
class AppConfig {
  static const String baseUrl = 
    'https://api.silakes.labkesdasumenep.id/api/v1';
  
  static const String flutterEncryptionKey = 
    'your-32-character-secret-key!!'; // SAME as Laravel
  
  static const String firebaseRealtimeDatabaseUrl = 
    'https://your-project-id-default-rtdb.firebaseio.com';
}
```

---

## 📞 Support

Untuk pertanyaan terkait API contract:
- Email: dev@labkesdasumenep.id
- Documentation: This file

---

**Last Updated**: 2024-11-18  
**Version**: 1.0.0  
**Status**: ✅ Production Ready

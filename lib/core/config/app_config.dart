/// Konfigurasi aplikasi SiLAKES Scanner
class AppConfig {
  // Base URL Laravel API
  static const String baseUrl = 'https://api.silakes.labkesdasumenep.id/api';

  // Endpoints
  static const String geminiKeyEndpoint = '/scanner-settings/config/gemini-key';
  static const String checkNikEndpoint = '/bot/v1/cek-nik/registered';

  // Shared Key untuk dekripsi (sama dengan yang ada di Laravel)
  // HARUS TEPAT 32 karakter untuk AES-256-CBC
  // TODO: Ganti dengan key yang sama dengan backend Laravel Anda
  static const String flutterEncryptionKey = 'kesehatanNo1BLUDLabkesmas2025!!!';

  // Cache duration
  static const Duration apiKeyCacheDuration = Duration(hours: 24);

  // Firebase RTDB
  static const String firebaseRealtimeDatabaseUrl =
      'https://silakes-default-rtdb.asia-southeast1.firebasedatabase.app';
  static const String firebaseRootNode = 'vue-firebase';
  static const String firebasePatientNode =
      'patients'; // Legacy, tidak digunakan lagi

  // Hive Box Names
  static const String historyBoxName = 'patient_history';
  static const String configBoxName = 'app_config';

  // Camera Settings
  static const double ktpAspectRatio =
      1.586; // Ratio KTP Indonesia (85.6mm x 53.98mm)

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration geminiTimeout = Duration(seconds: 60);
}

/// Daftar model Gemini yang tersedia (urutan dari paling powerful/mahal)
class GeminiModels {
  // Model prioritas (dari tertinggi ke terendah berdasarkan cost & capability)
  static const List<String> models = [
    'gemini-1.5-pro',        // Tertinggi: Paling akurat, paling mahal
    'gemini-1.5-flash',      // Medium: Balance antara speed & accuracy
    'gemini-2.0-flash-lite', // Terendah: Paling cepat, paling murah
  ];
  
  // API base URL untuk Gemini
  static const String baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models';
  
  // Konstruksi URL untuk model
  static String getModelUrl(String model) => '$baseUrl/$model:generateContent';
}

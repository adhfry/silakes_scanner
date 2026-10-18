import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/models/patient_data.dart';
import '../core/utils/logger.dart';
import '../core/config/app_config.dart';

// ---------------------------------------------------------------------------
// Custom Exception
// ---------------------------------------------------------------------------

/// Exception khusus untuk Rate Limit (HTTP 429).
class RateLimitException implements Exception {
  final String message;

  /// Nilai dari header `Retry-After` (dalam detik), kalau ada.
  final int? retryAfterSeconds;

  const RateLimitException(this.message, {this.retryAfterSeconds});

  @override
  String toString() =>
      'RateLimitException: $message'
      '${retryAfterSeconds != null ? ' (retry after ${retryAfterSeconds}s)' : ''}';
}

/// Exception untuk model yang tidak ditemukan / tidak tersedia.
class ModelUnavailableException implements Exception {
  final String message;
  const ModelUnavailableException(this.message);

  @override
  String toString() => 'ModelUnavailableException: $message';
}

// ---------------------------------------------------------------------------
// Rate Limiter sederhana berbasis token bucket
// ---------------------------------------------------------------------------

/// Membatasi request agar tidak melebihi `maxRequestsPerMinute`.
/// Menggunakan pendekatan token-bucket dengan antrian (queue).
class _RateLimiter {
  final int maxRequestsPerMinute;
  final _queue = <Completer<void>>[];
  final _timestamps = <DateTime>[];
  bool _processing = false;

  _RateLimiter({this.maxRequestsPerMinute = 50});

  /// Tunggu sampai slot tersedia, lalu lanjutkan.
  Future<void> acquire() async {
    final completer = Completer<void>();
    _queue.add(completer);
    _process();
    return completer.future;
  }

  void _process() {
    if (_processing) return;
    _processing = true;

    Future.microtask(() async {
      while (_queue.isNotEmpty) {
        // Buang timestamps yang sudah lebih dari 60 detik
        final now = DateTime.now();
        _timestamps.removeWhere((t) => now.difference(t).inSeconds >= 60);

        if (_timestamps.length < maxRequestsPerMinute) {
          _timestamps.add(now);
          _queue.removeAt(0).complete();
        } else {
          // Hitung berapa lama harus nunggu sampai slot paling lama expired
          final oldest = _timestamps.first;
          final waitMs =
              60000 -
              now.difference(oldest).inMilliseconds +
              100; // +100ms buffer
          Logger.warning(
            'Rate limiter: waiting ${waitMs}ms for slot',
            tag: 'RateLimiter',
          );
          await Future.delayed(
            Duration(milliseconds: waitMs.clamp(100, 60000)),
          );
        }
      }
      _processing = false;
    });
  }
}

// ---------------------------------------------------------------------------
// GeminiService
// ---------------------------------------------------------------------------

/// Service OCR menggunakan Google Gemini AI.
///
/// Fitur utama:
/// - **Exponential backoff** saat kena 429 (1s → 2s → 4s → 8s).
/// - **Model cooldown**: model yang kena rate-limit diblok sementara.
/// - **Static rate limiter**: dibagi antar seluruh instance agar tidak
///   flooding API walau ada banyak call bersamaan.
/// - **Retry-After header**: menghormati petunjuk waktu tunggu dari server.
/// - **Model rotation**: fallback otomatis ke model berikutnya bila perlu.
class GeminiService {
  // -------------------------------------------------------------------------
  // Static / shared state — persists across all instances
  // -------------------------------------------------------------------------

  /// Index model yang sedang aktif (bersama antar instance).
  static int _currentModelIndex = 0;

  /// Waktu kapan setiap model boleh digunakan lagi setelah cooldown.
  static final Map<String, DateTime> _modelCooldownUntil = {};

  /// Rate limiter global — max 50 req/menit (aman di bawah limit 4K RPM
  /// agar tidak ada burst yang memicu 429).
  static final _RateLimiter _rateLimiter = _RateLimiter(
    maxRequestsPerMinute: 50,
  );

  // -------------------------------------------------------------------------
  // Config
  // -------------------------------------------------------------------------

  /// Maksimum retry per model sebelum pindah ke model berikutnya.
  static const int _maxRetriesPerModel = 3;

  /// Base delay untuk exponential backoff (milidetik).
  static const int _baseBackoffMs = 1000;

  /// Cooldown default (detik) saat 429 tapi tidak ada `Retry-After` header.
  static const int _defaultCooldownSec = 60;

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Proses OCR dari file KTP.
  ///
  /// Mencoba setiap model di [GeminiModels.models] dengan exponential backoff.
  /// Melempar [Exception] bila semua model gagal.
  Future<PatientData> extractKtpData(File imageFile, String apiKey) async {
    Logger.info('Starting OCR process', tag: 'GeminiService');

    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);
    final requestBody = _buildRequestBody(_buildPrompt(), base64Image);

    // Iterasi model mulai dari index terakhir yang berhasil
    for (int i = _currentModelIndex; i < GeminiModels.models.length; i++) {
      final model = GeminiModels.models[i];

      // Lewati model yang sedang cooldown
      if (_isInCooldown(model)) {
        final remaining = _remainingCooldown(model);
        Logger.warning(
          'Model $model in cooldown, skipping (${remaining}s remaining)',
          tag: 'GeminiService',
        );
        continue;
      }

      // Retry loop per model dengan exponential backoff
      bool switchModel = false;
      for (int retry = 0; retry < _maxRetriesPerModel; retry++) {
        // Tunggu slot dari rate limiter sebelum setiap request
        await _rateLimiter.acquire();

        // Backoff setelah gagal (retry ke-0 tidak perlu delay)
        if (retry > 0) {
          final delayMs = _baseBackoffMs * (1 << retry); // 1s, 2s, 4s
          Logger.info(
            'Backoff retry $retry/$_maxRetriesPerModel for $model → ${delayMs}ms',
            tag: 'GeminiService',
          );
          await Future.delayed(Duration(milliseconds: delayMs));
        }

        Logger.info(
          'Trying model: $model '
          '(model ${i + 1}/${GeminiModels.models.length}, retry $retry)',
          tag: 'GeminiService',
        );

        try {
          final result = await _callGeminiApi(model, requestBody, apiKey);
          // Berhasil — simpan model index ini untuk call berikutnya
          _currentModelIndex = i;
          Logger.success(
            'OCR successful with model: $model',
            tag: 'GeminiService',
          );
          return result;
        } on RateLimitException catch (e) {
          Logger.warning('Rate limit hit: $e', tag: 'GeminiService');

          if (retry < _maxRetriesPerModel - 1) {
            // Masih ada retry — lanjutkan backoff loop
            continue;
          }

          // Sudah habis retry → set cooldown dan pindah model
          final cooldownSec = e.retryAfterSeconds ?? _defaultCooldownSec;
          _setCooldown(model, cooldownSec);
          switchModel = true;
          break;
        } on ModelUnavailableException catch (e) {
          Logger.warning('Model unavailable: $e', tag: 'GeminiService');
          // Langsung pindah model tanpa retry
          switchModel = true;
          break;
        } catch (e) {
          Logger.warning(
            'Model $model unexpected error: $e',
            tag: 'GeminiService',
          );

          if (i == GeminiModels.models.length - 1 &&
              retry == _maxRetriesPerModel - 1) {
            Logger.error(
              'All models exhausted',
              tag: 'GeminiService',
              error: e,
            );
            throw Exception('OCR failed with all models. Last error: $e');
          }
          // Error lain — coba retry dulu
        }
      }

      if (switchModel) {
        Logger.info('Switching to next model...', tag: 'GeminiService');
      }
    }

    // Semua model dalam cooldown atau habis
    throw Exception(
      'No models available at this time. '
      'All models are either rate-limited or unavailable. '
      'Please try again later.',
    );
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  bool _isInCooldown(String model) {
    final until = _modelCooldownUntil[model];
    return until != null && DateTime.now().isBefore(until);
  }

  int _remainingCooldown(String model) {
    final until = _modelCooldownUntil[model];
    if (until == null) return 0;
    return until.difference(DateTime.now()).inSeconds.clamp(0, 9999);
  }

  void _setCooldown(String model, int seconds) {
    _modelCooldownUntil[model] = DateTime.now().add(Duration(seconds: seconds));
    Logger.warning(
      'Model $model cooldown set for ${seconds}s',
      tag: 'GeminiService',
    );
  }

  Map<String, dynamic> _buildRequestBody(String prompt, String base64Image) {
    return {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image},
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.1,
        'topK': 1,
        'topP': 1,
        'maxOutputTokens': 2048,
      },
    };
  }

  /// Panggil Gemini REST API untuk satu model tertentu.
  ///
  /// Melempar:
  /// - [RateLimitException]         → HTTP 429 atau pesan quota/token
  /// - [ModelUnavailableException]  → HTTP 404 / 503
  /// - [Exception]                  → error lainnya
  Future<PatientData> _callGeminiApi(
    String model,
    Map<String, dynamic> requestBody,
    String apiKey,
  ) async {
    final url = Uri.parse('${GeminiModels.getModelUrl(model)}?key=$apiKey');
    Logger.info('→ POST $model', tag: 'GeminiService');

    final http.Response response;
    try {
      response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestBody),
          )
          .timeout(AppConfig.geminiTimeout);
    } on TimeoutException {
      throw Exception('Gemini API timeout after ${AppConfig.geminiTimeout}');
    }

    Logger.info(
      'Response ${response.statusCode} from $model',
      tag: 'GeminiService',
    );

    // --- Tangani HTTP error ---
    switch (response.statusCode) {
      case 429:
        // Rate limit — baca Retry-After jika ada
        final retryAfter = _parseRetryAfter(response);
        throw RateLimitException(
          'Rate limit exceeded (429) for $model',
          retryAfterSeconds: retryAfter,
        );

      case 400:
        final body = _tryDecodeJson(response.body);
        final msg = body?['error']?['message']?.toString() ?? 'Unknown error';
        // Quota / token limit → perlakukan seperti rate limit
        if (_isQuotaMessage(msg)) {
          throw RateLimitException('Quota/token limit (400): $msg');
        }
        throw Exception('Bad request (400): $msg');

      case 404:
        throw ModelUnavailableException('Model not found (404): $model');

      case 503:
        throw ModelUnavailableException('Service unavailable (503): $model');

      case 200:
        break; // lanjut ke parsing

      default:
        throw Exception(
          'Unexpected status ${response.statusCode} from $model: ${response.body}',
        );
    }

    // --- Parse response 200 ---
    final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
    final candidates = jsonResponse['candidates'] as List<dynamic>?;

    if (candidates == null || candidates.isEmpty) {
      throw Exception('Empty candidates in response from $model');
    }

    final content = candidates[0]['content'] as Map<String, dynamic>?;
    final parts = content?['parts'] as List<dynamic>?;
    final text = parts?.first['text'] as String?;

    if (text == null || text.isEmpty) {
      throw Exception('Empty text in response from $model');
    }

    Logger.info('Raw response received from $model', tag: 'GeminiService');
    Logger.log(
      'Response snippet: ${text.substring(0, text.length.clamp(0, 200))}',
      tag: 'GeminiService',
    );

    return _parseGeminiResponse(text);
  }

  // -------------------------------------------------------------------------
  // Utilities
  // -------------------------------------------------------------------------

  /// Ambil nilai `Retry-After` header (bisa angka detik atau tanggal HTTP).
  int? _parseRetryAfter(http.Response response) {
    final raw =
        response.headers['retry-after'] ?? response.headers['Retry-After'];
    if (raw == null) return null;
    // Coba parse sebagai integer (detik)
    final asInt = int.tryParse(raw.trim());
    if (asInt != null) return asInt;
    // Coba parse sebagai HTTP-date
    try {
      final date = HttpDate.parse(raw);
      return date.difference(DateTime.now().toUtc()).inSeconds.clamp(0, 3600);
    } catch (_) {
      return null;
    }
  }

  bool _isQuotaMessage(String msg) {
    final lower = msg.toLowerCase();
    return lower.contains('quota') ||
        lower.contains('token') ||
        lower.contains('limit') ||
        lower.contains('exceeded') ||
        lower.contains('resource_exhausted');
  }

  Map<String, dynamic>? _tryDecodeJson(String body) {
    try {
      return json.decode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // Prompt
  // -------------------------------------------------------------------------

  String _buildPrompt() => '''
Anda adalah sistem OCR untuk membaca KTP Indonesia. Ekstrak informasi dari gambar KTP ini dengan sangat teliti.

Kembalikan data dalam format JSON berikut (pastikan valid JSON):
{
  "nik": "16 digit NIK",
  "nama": "Nama lengkap",
  "tempat_lahir": "Tempat lahir",
  "tanggal_lahir": "Format: DD-MM-YYYY",
  "jenis_kelamin": "LAKI-LAKI atau PEREMPUAN",
  "alamat": "Alamat lengkap",
  "rt_rw": "RT/RW (contoh: 001/002)",
  "kel_desa": "Kelurahan/Desa",
  "kecamatan": "Kecamatan",
  "agama": "Agama",
  "status_perkawinan": "BELUM KAWIN, KAWIN, CERAI HIDUP, atau CERAI MATI",
  "pekerjaan": "Pekerjaan"
}

Penting:
1. Ekstrak field-field yang disebutkan di atas.
2. Jika field tidak terlihat jelas, berikan nilai null.
3. NIK harus 16 digit angka.
4. Tanggal lahir dalam format DD-MM-YYYY.
5. Jenis kelamin harus UPPERCASE.
6. Return HANYA JSON, tanpa teks lain.
7. Pastikan JSON valid dan bisa di-parse.
8. JANGAN ekstrak field "kewarganegaraan" dan "berlaku_hingga".
''';

  // -------------------------------------------------------------------------
  // Response parser
  // -------------------------------------------------------------------------

  PatientData _parseGeminiResponse(String responseText) {
    try {
      String cleaned = responseText.trim();

      // Hapus markdown code fence jika ada
      final fencePattern = RegExp(r'^```(?:json)?\s*', multiLine: true);
      cleaned = cleaned
          .replaceAll(fencePattern, '')
          .replaceAll('```', '')
          .trim();

      final jsonData = json.decode(cleaned) as Map<String, dynamic>;

      final patient = PatientData(
        nik: jsonData['nik']?.toString(),
        nama: jsonData['nama']?.toString(),
        tempatLahir: jsonData['tempat_lahir']?.toString(),
        tanggalLahir: jsonData['tanggal_lahir']?.toString(),
        jenisKelamin: jsonData['jenis_kelamin']?.toString(),
        alamat: jsonData['alamat']?.toString(),
        rtRw: jsonData['rt_rw']?.toString(),
        kelDesa: jsonData['kel_desa']?.toString(),
        kecamatan: jsonData['kecamatan']?.toString(),
        agama: jsonData['agama']?.toString(),
        statusPerkawinan: jsonData['status_perkawinan']?.toString(),
        pekerjaan: jsonData['pekerjaan']?.toString(),
        scannedAt: DateTime.now(),
      );

      // Validasi: semua field penting null → KTP tidak terdeteksi
      final coreFields = [
        patient.nik,
        patient.nama,
        patient.tempatLahir,
        patient.tanggalLahir,
        patient.jenisKelamin,
        patient.alamat,
      ];
      if (coreFields.every((f) => f == null)) {
        throw Exception('KTP_NOT_DETECTED');
      }

      // Minimal NIK atau Nama harus ada
      if (patient.nik == null && patient.nama == null) {
        throw Exception('KTP_INCOMPLETE');
      }

      Logger.success('Patient data parsed successfully', tag: 'GeminiService');
      return patient;
    } catch (e) {
      Logger.error('Failed to parse response', tag: 'GeminiService', error: e);
      throw Exception('Failed to parse OCR result: $e');
    }
  }
}

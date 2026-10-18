import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/app_config.dart';
import '../core/utils/logger.dart';

/// Service untuk mengelola konfigurasi dan API key
class ConfigService {
  static const String _cacheKeyApiKey = 'gemini_api_key';
  static const String _cacheKeyTimestamp = 'gemini_api_key_timestamp';

  /// Mendapatkan Gemini API Key
  /// 1. Cek cache lokal (valid 24 jam)
  /// 2. Jika tidak ada/expired, ambil dari server Laravel
  /// 3. Dekripsi menggunakan shared key
  /// 4. Simpan ke cache
  Future<String> getGeminiApiKey() async {
    try {
      // Cek cache dulu
      final cachedKey = await _getCachedApiKey();
      if (cachedKey != null) {
        Logger.success('Using cached Gemini API key', tag: 'ConfigService');
        return cachedKey;
      }

      // Ambil dari server
      Logger.info('Fetching Gemini API key from server', tag: 'ConfigService');
      final apiKey = await _fetchAndDecryptApiKey();

      // Cache untuk 24 jam
      await _cacheApiKey(apiKey);

      Logger.success('Gemini API key retrieved successfully', tag: 'ConfigService');
      return apiKey;
    } catch (e) {
      Logger.error('Failed to get Gemini API key', tag: 'ConfigService', error: e);
      rethrow;
    }
  }

  /// Refresh API key (hapus cache dan ambil yang baru)
  Future<String> refreshApiKey() async {
    Logger.info('Refreshing API key', tag: 'ConfigService');
    await _clearCache();
    return await getGeminiApiKey();
  }

  /// Ambil API key dari cache jika masih valid
  Future<String?> _getCachedApiKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedKey = prefs.getString(_cacheKeyApiKey);
      final timestamp = prefs.getInt(_cacheKeyTimestamp);

      if (cachedKey == null || timestamp == null) {
        return null;
      }

      // Cek apakah cache masih valid (24 jam)
      final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(cacheTime);

      if (difference < AppConfig.apiKeyCacheDuration) {
        return cachedKey;
      }

      // Cache expired
      await _clearCache();
      return null;
    } catch (e) {
      Logger.error('Error reading cached API key', tag: 'ConfigService', error: e);
      return null;
    }
  }

  /// Simpan API key ke cache
  Future<void> _cacheApiKey(String apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKeyApiKey, apiKey);
      await prefs.setInt(_cacheKeyTimestamp, DateTime.now().millisecondsSinceEpoch);
      Logger.success('API key cached successfully', tag: 'ConfigService');
    } catch (e) {
      Logger.error('Error caching API key', tag: 'ConfigService', error: e);
    }
  }

  /// Hapus cache
  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKeyApiKey);
      await prefs.remove(_cacheKeyTimestamp);
      Logger.info('Cache cleared', tag: 'ConfigService');
    } catch (e) {
      Logger.error('Error clearing cache', tag: 'ConfigService', error: e);
    }
  }

  /// Ambil dan dekripsi API key dari server
  Future<String> _fetchAndDecryptApiKey() async {
    try {
      // Panggil endpoint Laravel
      final url = Uri.parse('${AppConfig.baseUrl}${AppConfig.geminiKeyEndpoint}');
      
      Logger.info('Calling API: $url', tag: 'ConfigService');
      
      final response = await http.get(url).timeout(
        AppConfig.apiTimeout,
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );

      Logger.info('Response status: ${response.statusCode}', tag: 'ConfigService');

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch API key: ${response.statusCode}');
      }

      // Parse response
      // Expected format: {"status":"success","data":{"encrypted_key":"...","iv":"..."},"message":"..."}
      Logger.log('API Response body: ${response.body}', tag: 'ConfigService');
      
      final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
      
      // Validasi response
      final status = jsonResponse['status'] as String?;
      if (status != 'success') {
        throw Exception('API returned error status: $status');
      }

      if (!jsonResponse.containsKey('data')) {
        Logger.error('Response: $jsonResponse', tag: 'ConfigService');
        throw Exception('Invalid response format: missing data field');
      }

      final data = jsonResponse['data'] as Map<String, dynamic>?;
      if (data == null) {
        Logger.error('Data is null in response', tag: 'ConfigService');
        throw Exception('Data field is null');
      }

      Logger.log('Data content: $data', tag: 'ConfigService');
      
      final encryptedKeyBase64 = data['encrypted_key'] as String?;
      final ivBase64 = data['iv'] as String?;

      if (encryptedKeyBase64 == null || ivBase64 == null) {
        Logger.error('encrypted_key: $encryptedKeyBase64, iv: $ivBase64', tag: 'ConfigService');
        throw Exception('Missing encryption data in response');
      }
      
      Logger.info('Encrypted key and IV received', tag: 'ConfigService');

      // Dekripsi
      final decryptedKey = _decryptApiKey(encryptedKeyBase64, ivBase64);

      if (decryptedKey.isEmpty) {
        throw Exception('Decryption resulted in empty key');
      }

      return decryptedKey;
    } catch (e) {
      Logger.error('Error fetching and decrypting API key', tag: 'ConfigService', error: e);
      rethrow;
    }
  }

  /// Dekripsi API key menggunakan AES-256-CBC
  String _decryptApiKey(String encryptedBase64, String ivBase64) {
    try {
      // Validasi shared key
      if (AppConfig.flutterEncryptionKey.length != 32) {
        throw Exception('Encryption key must be 32 characters (256-bit)');
      }

      // Decode base64
      final encryptedData = encrypt_pkg.Encrypted.fromBase64(encryptedBase64);
      final iv = encrypt_pkg.IV.fromBase64(ivBase64);

      // Setup encrypter
      final key = encrypt_pkg.Key.fromUtf8(AppConfig.flutterEncryptionKey);
      final encrypter = encrypt_pkg.Encrypter(
        encrypt_pkg.AES(key, mode: encrypt_pkg.AESMode.cbc),
      );

      // Dekripsi
      final decrypted = encrypter.decrypt(encryptedData, iv: iv);

      Logger.success('API key decrypted successfully', tag: 'ConfigService');
      return decrypted;
    } catch (e) {
      Logger.error('Decryption failed', tag: 'ConfigService', error: e);
      throw Exception('Failed to decrypt API key: $e');
    }
  }
}

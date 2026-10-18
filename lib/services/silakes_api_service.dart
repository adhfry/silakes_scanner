import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import '../core/utils/logger.dart';

/// Service untuk berkomunikasi dengan API SiLAKES
class SilakesApiService {
  /// Cek apakah NIK sudah terdaftar di database SiLAKES
  /// Return: true jika sudah terdaftar, false jika belum
  Future<bool> isNikRegistered(String nik) async {
    try {
      Logger.info('Checking NIK: $nik', tag: 'SilakesApi');

      final url = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.checkNikEndpoint}/$nik',
      );

      final response = await http
          .get(url)
          .timeout(
            AppConfig.apiTimeout,
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );
      Logger.info('Request URL: $url', tag: 'SilakesApi');
      Logger.info('Response body: ${response.body}', tag: 'SilakesApi');
      Logger.info('Response status: ${response.statusCode}', tag: 'SilakesApi');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;

        // Response format: {"data":{"registered":true},"error":false,"message":"..."}
        final data = jsonResponse['data'] as Map<String, dynamic>?;
        final isRegistered = data?['registered'] as bool? ?? false;

        Logger.success(
          'NIK check result: ${isRegistered ? "REGISTERED" : "NOT REGISTERED"}',
          tag: 'SilakesApi',
        );

        return isRegistered;
      } else if (response.statusCode == 404) {
        // NIK tidak ditemukan
        Logger.info('NIK not found (404)', tag: 'SilakesApi');
        return false;
      } else {
        throw Exception('Unexpected status code: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('Error checking NIK', tag: 'SilakesApi', error: e);
      rethrow;
    }
  }

  /// Get patient data by NIK (optional, jika diperlukan)
  Future<Map<String, dynamic>?> getPatientByNik(String nik) async {
    try {
      Logger.info('Fetching patient data for NIK: $nik', tag: 'SilakesApi');

      final url = Uri.parse(
        '${AppConfig.baseUrl}${AppConfig.checkNikEndpoint}/$nik',
      );

      final response = await http
          .get(url)
          .timeout(
            AppConfig.apiTimeout,
            onTimeout: () {
              throw Exception('Request timeout');
            },
          );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        final data = jsonResponse['data'] as Map<String, dynamic>?;

        Logger.success('Patient data retrieved', tag: 'SilakesApi');
        return data;
      } else if (response.statusCode == 404) {
        Logger.info('Patient not found', tag: 'SilakesApi');
        return null;
      } else {
        throw Exception('Failed to fetch patient: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('Error fetching patient data', tag: 'SilakesApi', error: e);
      rethrow;
    }
  }
}

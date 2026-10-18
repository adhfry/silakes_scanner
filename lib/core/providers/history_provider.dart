import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/patient_data.dart';
import '../../services/local_cache_service.dart';
import 'service_providers.dart';

/// Provider untuk history list
final historyProvider = StateNotifierProvider<HistoryNotifier, List<PatientData>>((ref) {
  final cacheService = ref.watch(localCacheServiceProvider);
  return HistoryNotifier(cacheService);
});

/// State notifier untuk mengelola history
class HistoryNotifier extends StateNotifier<List<PatientData>> {
  final LocalCacheService _cacheService;

  HistoryNotifier(this._cacheService) : super([]) {
    loadHistory();
  }

  /// Load history dari cache
  Future<void> loadHistory() async {
    state = await _cacheService.getAllHistory();
  }

  /// Tambah ke history
  Future<void> addToHistory(PatientData patientData) async {
    await _cacheService.saveToHistory(patientData);
    await loadHistory();
  }

  /// Hapus dari history by ID
  Future<void> removeFromHistory(String id) async {
    await _cacheService.deleteById(id);
    await loadHistory();
  }

  /// Clear all history
  Future<void> clearAll() async {
    await _cacheService.clearAllHistory();
    state = [];
  }

  /// Refresh history
  Future<void> refresh() async {
    await loadHistory();
  }
}

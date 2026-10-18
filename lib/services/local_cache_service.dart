import 'package:hive_flutter/hive_flutter.dart';
import '../core/models/patient_data.dart';
import '../core/config/app_config.dart';
import '../core/utils/logger.dart';

/// Service untuk menyimpan riwayat scan lokal menggunakan Hive
class LocalCacheService {
  Box<PatientData>? _historyBox;

  /// Inisialisasi Hive dan box
  Future<void> init() async {
    try {
      // Jika box sudah terbuka, langsung return
      if (_historyBox != null && _historyBox!.isOpen) {
        Logger.info('Hive already initialized', tag: 'LocalCacheService');
        return;
      }

      Logger.info('Initializing Hive', tag: 'LocalCacheService');
      
      // Initialize Hive jika belum
      if (!Hive.isBoxOpen(AppConfig.historyBoxName)) {
        await Hive.initFlutter();
      }
      
      // Register adapter jika belum
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(PatientDataAdapter());
      }

      // Buka box untuk history (atau ambil yang sudah terbuka)
      if (Hive.isBoxOpen(AppConfig.historyBoxName)) {
        _historyBox = Hive.box<PatientData>(AppConfig.historyBoxName);
        Logger.info('Using existing Hive box', tag: 'LocalCacheService');
      } else {
        _historyBox = await Hive.openBox<PatientData>(AppConfig.historyBoxName);
        Logger.info('Opened new Hive box', tag: 'LocalCacheService');
      }

      Logger.success('Hive initialized successfully', tag: 'LocalCacheService');
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to initialize Hive',
        tag: 'LocalCacheService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Simpan data pasien ke history
  Future<void> saveToHistory(PatientData patientData) async {
    try {
      if (_historyBox == null) {
        await init();
      }

      Logger.info('Saving patient to history', tag: 'LocalCacheService');

      // Gunakan ID unik sebagai key
      final key = patientData.id ?? DateTime.now().millisecondsSinceEpoch.toString();
      
      // Update existing atau tambah baru
      await _historyBox!.put(key, patientData);

      Logger.success('Patient saved to history with key: $key', tag: 'LocalCacheService');
    } catch (e) {
      Logger.error('Failed to save to history', tag: 'LocalCacheService', error: e);
      rethrow;
    }
  }

  /// Ambil semua history (sorted by scannedAt descending)
  Future<List<PatientData>> getAllHistory() async {
    try {
      // Ensure box is initialized
      if (_historyBox == null || !_historyBox!.isOpen) {
        Logger.warning('History box not initialized, initializing...', tag: 'LocalCacheService');
        await init();
      }

      if (_historyBox == null) {
        Logger.error('History box still null after init', tag: 'LocalCacheService');
        return [];
      }

      final allData = _historyBox!.values.toList();
      
      // Sort by scannedAt (terbaru dulu)
      allData.sort((a, b) {
        if (a.scannedAt == null) return 1;
        if (b.scannedAt == null) return -1;
        return b.scannedAt!.compareTo(a.scannedAt!);
      });

      Logger.info('Retrieved ${allData.length} history items', tag: 'LocalCacheService');
      return allData;
    } catch (e) {
      Logger.error('Failed to get history', tag: 'LocalCacheService', error: e);
      return [];
    }
  }

  /// Cari patient by NIK
  PatientData? getByNik(String nik) {
    try {
      if (_historyBox == null) return null;
      return _historyBox!.get(nik);
    } catch (e) {
      Logger.error('Failed to get patient by NIK', tag: 'LocalCacheService', error: e);
      return null;
    }
  }

  /// Hapus history by ID
  Future<void> deleteById(String id) async {
    try {
      if (_historyBox == null) {
        Logger.warning('History box not initialized', tag: 'LocalCacheService');
        return;
      }
      
      Logger.info('Attempting to delete by ID: $id', tag: 'LocalCacheService');
      
      // Coba delete langsung dengan key (ID)
      if (_historyBox!.containsKey(id)) {
        await _historyBox!.delete(id);
        Logger.success('Deleted history with ID: $id', tag: 'LocalCacheService');
        return;
      }
      
      // Jika tidak ada dengan key tersebut, cari di semua entries berdasarkan ID field
      final entries = _historyBox!.toMap();
      String? keyToDelete;
      
      for (var entry in entries.entries) {
        if (entry.value.id == id) {
          keyToDelete = entry.key as String;
          break;
        }
      }
      
      if (keyToDelete != null) {
        await _historyBox!.delete(keyToDelete);
        Logger.success('Deleted history with ID: $id (key: $keyToDelete)', tag: 'LocalCacheService');
      } else {
        Logger.warning('History not found for deletion: $id', tag: 'LocalCacheService');
      }
    } catch (e) {
      Logger.error('Failed to delete history', tag: 'LocalCacheService', error: e);
      rethrow;
    }
  }

  /// Hapus history by NIK (deprecated, use deleteById instead)
  @Deprecated('Use deleteById instead')
  Future<void> deleteByNik(String nik) async {
    // Fallback untuk backward compatibility
    await deleteById(nik);
  }

  /// Hapus semua history
  Future<void> clearAllHistory() async {
    try {
      if (_historyBox == null) return;
      
      await _historyBox!.clear();
      Logger.success('All history cleared', tag: 'LocalCacheService');
    } catch (e) {
      Logger.error('Failed to clear history', tag: 'LocalCacheService', error: e);
      rethrow;
    }
  }

  /// Get history count
  int getHistoryCount() {
    return _historyBox?.length ?? 0;
  }

  /// Close box
  Future<void> close() async {
    await _historyBox?.close();
    Logger.info('History box closed', tag: 'LocalCacheService');
  }
}

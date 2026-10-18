import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/history_provider.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/tour_helper.dart';
import '../../../core/models/patient_data.dart';
import '../widgets/history_list_item.dart';
import '../../scanner/screen/camera_screen.dart';
import '../../scanner/screen/preview_edit_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isRefreshingApi = false;

  // Tour Guide Keys
  final GlobalKey _logoKey = GlobalKey();
  final GlobalKey _refreshKey = GlobalKey();
  final GlobalKey _menuKey = GlobalKey();
  final GlobalKey _scanButtonKey = GlobalKey();
  final GlobalKey _historyHeaderKey = GlobalKey();
  final GlobalKey _historyListKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Load history saat pertama kali
    Future.microtask(() {
      ref.read(historyProvider.notifier).loadHistory();
      _checkAndShowTour();
    });
  }

  /// Check dan tampilkan tour jika diperlukan
  Future<void> _checkAndShowTour() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final tourService = ref.read(tourGuideServiceProvider);
    final isCompleted = await tourService.isDashboardTourCompleted();

    if (!isCompleted && mounted) {
      _showDashboardTour();
    }
  }

  /// Tampilkan dashboard tour
  void _showDashboardTour() {
    final targets = <TargetFocus>[
      // 1. Logo & App Name
      TourHelper.createTarget(
        key: _logoKey,
        title: 'Selamat Datang di SiLAKES Scanner! 🏥',
        description:
            'Aplikasi untuk memindai KTP pasien dan melakukan registrasi otomatis ke sistem SiLAKES. '
            'Mari saya tunjukkan cara menggunakan aplikasi ini.',
        align: ContentAlign.bottom,
      ),

      // 2. Refresh API Button
      TourHelper.createTarget(
        key: _refreshKey,
        title: 'Tombol Refresh API Key 🔄',
        description:
            'Gunakan tombol ini untuk memperbarui API Key Gemini dari Firebase. '
            'API Key digunakan untuk proses OCR (membaca KTP). Klik tombol ini jika OCR gagal atau API Key berubah.',
        align: ContentAlign.bottom,
      ),

      // 3. Menu (3 Dots)
      TourHelper.createTarget(
        key: _menuKey,
        title: 'Menu Aplikasi ⚙️',
        description:
            'Di sini Anda dapat:\n'
            '• Menghapus semua riwayat scan\n'
            '• Reset tour guide (untuk melihat panduan lagi)\n'
            'Klik ikon tiga titik untuk melihat opsi menu.',
        align: ContentAlign.bottom,
      ),

      // 4. Scan Button
      TourHelper.createTarget(
        key: _scanButtonKey,
        title: 'Tombol Mulai Scan 📸',
        description:
            'Ini adalah tombol utama! Klik tombol "Mulai Scan" untuk:\n'
            '1. Membuka kamera\n'
            '2. Mengambil foto KTP pasien\n'
            '3. Ekstrak data otomatis dengan AI\n'
            '4. Simpan ke riwayat\n\n'
            'Setelah scan, data akan otomatis dicek apakah pasien sudah terdaftar atau belum.',
        align: ContentAlign.bottom,
        shape: ShapeLightFocus.RRect,
      ),

      // 5. History Header
      TourHelper.createTarget(
        key: _historyHeaderKey,
        title: 'Riwayat Scan 📋',
        description:
            'Bagian ini menampilkan semua KTP yang sudah Anda scan. '
            'Jumlah data akan ditampilkan di sebelah kanan. '
            'Anda bisa scroll ke bawah untuk melihat semua riwayat.',
        align: ContentAlign.bottom,
      ),

      // 6. History List (jika ada data)
      if (ref.read(historyProvider).isNotEmpty)
        TourHelper.createTarget(
          key: _historyListKey,
          title: 'Item Riwayat & Status Registrasi 🏷️',
          description:
              'Setiap item menampilkan:\n'
              '• Nama & NIK pasien\n'
              '• Badge status (Hijau = Terdaftar, Kuning = Belum Terdaftar)\n'
              '• Info tempat/tanggal lahir, alamat\n'
              '• Waktu scan\n\n'
              'Untuk pasien BELUM TERDAFTAR:\n'
              '- Tombol "Edit": Edit data & foto sebelum kirim\n'
              '- Tombol "Kirim": Langsung kirim ke sistem\n'
              '- Tombol "Hapus": Hapus dari riwayat\n\n'
              'Untuk pasien SUDAH TERDAFTAR:\n'
              '- Hanya tombol "Hapus" saja\n\n'
              'Klik item untuk melihat detail lengkap.',
          align: ContentAlign.top,
        ),
    ];

    TourHelper.showTour(
      context: context,
      targets: targets,
      onFinish: () async {
        final tourService = ref.read(tourGuideServiceProvider);
        await tourService.completeDashboardTour();
        Logger.info('Dashboard tour completed', tag: 'Dashboard');
      },
      onSkip: () async {
        final tourService = ref.read(tourGuideServiceProvider);
        await tourService.skipAllTours();
        Logger.info('All tours skipped', tag: 'Dashboard');
      },
    );
  }

  Future<void> _refreshApiKey() async {
    setState(() => _isRefreshingApi = true);

    try {
      final configService = ref.read(configServiceProvider);
      await configService.refreshApiKey();

      if (mounted) {
        Helpers.showSuccess(context, 'API Key berhasil di-refresh');
      }
    } catch (e) {
      Logger.error('Failed to refresh API key', error: e);
      if (mounted) {
        Helpers.showError(context, 'Gagal refresh API Key: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshingApi = false);
      }
    }
  }

  Future<void> _navigateToScanner() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );

    // Refresh history jika ada data baru
    if (result == true) {
      ref.read(historyProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          key: _logoKey,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/SiLAKES-Scanner-logo-nobg.png',
              height: 40,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.local_hospital, size: 32);
              },
            ),
            const SizedBox(width: 12),
            const Text('SiLAKES Scanner'),
          ],
        ),
        actions: [
          IconButton(
            key: _refreshKey,
            icon: _isRefreshingApi
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshingApi ? null : _refreshApiKey,
            tooltip: 'Refresh API Key',
          ),
          PopupMenuButton<String>(
            key: _menuKey,
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'clear_history') {
                _confirmClearHistory();
              } else if (value == 'reset_tour') {
                _resetTour();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_history',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep, color: AppTheme.errorColor),
                    SizedBox(width: 8),
                    Text('Hapus Semua Riwayat'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset_tour',
                child: Row(
                  children: [
                    Icon(Icons.help_outline, color: AppTheme.infoColor),
                    SizedBox(width: 8),
                    Text('Tampilkan Panduan'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(historyProvider.notifier).refresh();
        },
        child: CustomScrollView(
          slivers: [
            // Header Section
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(AppTheme.spacingMedium),
                padding: const EdgeInsets.all(AppTheme.spacingLarge),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.qr_code_scanner,
                      size: 64,
                      color: Colors.white,
                    ),
                    const SizedBox(height: AppTheme.spacingMedium),
                    Text(
                      'Scan KTP Pasien',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacingSmall),
                    Text(
                      'Pindai KTP untuk registrasi pasien baru',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingLarge),
                    ElevatedButton.icon(
                      key: _scanButtonKey,
                      onPressed: _navigateToScanner,
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Mulai Scan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingXLarge,
                          vertical: AppTheme.spacingMedium,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // History Section Header
            SliverToBoxAdapter(
              child: Padding(
                key: _historyHeaderKey,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMedium,
                  vertical: AppTheme.spacingSmall,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Riwayat Scan',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (history.isNotEmpty)
                      Text(
                        '${history.length} data',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // History List
            if (history.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 80,
                        color: AppTheme.textHintColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: AppTheme.spacingMedium),
                      Text(
                        'Belum ada riwayat scan',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppTheme.textSecondaryColor),
                      ),
                      const SizedBox(height: AppTheme.spacingSmall),
                      Text(
                        'Mulai scan KTP untuk melihat riwayat',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMedium,
                  vertical: AppTheme.spacingSmall,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final patient = history[index];
                    return HistoryListItem(
                      key: index == 0 ? _historyListKey : null,
                      patientData: patient,
                      onDelete: () => _confirmDelete(patient.id ?? patient.nik ?? ''),
                      onEdit: patient.isRegistered
                          ? null
                          : () => _editPatient(patient),
                      onResend: patient.isRegistered
                          ? null
                          : () => _resendPatient(patient),
                    );
                  }, childCount: history.length),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(String id) async {
    final confirmed = await Helpers.showConfirmDialog(
      context,
      title: 'Hapus Riwayat',
      message: 'Yakin ingin menghapus riwayat ini?',
      confirmText: 'Hapus',
      cancelText: 'Batal',
    );

    if (confirmed) {
      try {
        Logger.info('Deleting history with ID: $id', tag: 'Dashboard');
        await ref.read(historyProvider.notifier).removeFromHistory(id);
        if (mounted) {
          Helpers.showSuccess(context, 'Riwayat berhasil dihapus');
        }
      } catch (e) {
        Logger.error('Failed to delete history', tag: 'Dashboard', error: e);
        if (mounted) {
          Helpers.showError(context, 'Gagal menghapus riwayat: $e');
        }
      }
    }
  }

  Future<void> _confirmClearHistory() async {
    final confirmed = await Helpers.showConfirmDialog(
      context,
      title: 'Hapus Semua Riwayat',
      message: 'Yakin ingin menghapus semua riwayat scan?',
      confirmText: 'Hapus Semua',
      cancelText: 'Batal',
    );

    if (confirmed) {
      try {
        await ref.read(historyProvider.notifier).clearAll();
        if (mounted) {
          Helpers.showSuccess(context, 'Semua riwayat berhasil dihapus');
        }
      } catch (e) {
        if (mounted) {
          Helpers.showError(context, 'Gagal menghapus riwayat');
        }
      }
    }
  }

  Future<void> _editPatient(PatientData patient) async {
    if (patient.imagePath == null || patient.imagePath!.isEmpty) {
      if (mounted) {
        Helpers.showWarning(context, 'Foto KTP tidak tersedia');
      }
      return;
    }

    final imageFile = File(patient.imagePath!);
    if (!await imageFile.exists()) {
      if (mounted) {
        Helpers.showWarning(context, 'Foto KTP tidak ditemukan');
      }
      return;
    }

    if (!mounted) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => PreviewEditScreenFromHistory(
          imageFile: imageFile,
          existingData: patient,
        ),
      ),
    );

    if (result == true && mounted) {
      ref.read(historyProvider.notifier).refresh();
    }
  }

  Future<void> _resendPatient(PatientData patient) async {
    final confirmed = await Helpers.showConfirmDialog(
      context,
      title: 'Kirim Data',
      message: 'Kirim data pasien ini ke sistem SiLAKES?',
      confirmText: 'Kirim',
      cancelText: 'Batal',
    );

    if (!confirmed) return;

    try {
      Helpers.showLoadingDialog(context, message: 'Mengirim data...');

      // 1. Cek NIK apakah sudah terdaftar
      bool isRegistered = false;
      if (patient.nik != null && patient.isNikValid) {
        final silakesApi = ref.read(silakesApiServiceProvider);
        isRegistered = await silakesApi.isNikRegistered(patient.nik!);
      }

      if (!mounted) return;
      Helpers.hideLoadingDialog(context);

      if (isRegistered) {
        // Jika sudah terdaftar, update status di history
        final updatedData = patient.copyWith(isRegistered: true);
        final cacheService = ref.read(localCacheServiceProvider);
        await cacheService.saveToHistory(updatedData);
        await ref.read(historyProvider.notifier).refresh();

        if (mounted) {
          Helpers.showInfo(context, 'Pasien sudah terdaftar di sistem');
        }
        return;
      }

      // 2. Kirim ke Firebase jika belum terdaftar
      final firebaseService = ref.read(firebaseServiceProvider);
      await firebaseService.sendNewPatient(patient);

      // 3. Update status submitted
      final updatedData = patient.copyWith(
        isSubmitted: true,
        isRegistered: false,
      );

      final cacheService = ref.read(localCacheServiceProvider);
      await cacheService.saveToHistory(updatedData);
      await ref.read(historyProvider.notifier).refresh();

      if (mounted) {
        Helpers.showSuccess(context, 'Data berhasil dikirim!');
      }
    } catch (e) {
      Logger.error('Resend failed', error: e);
      if (mounted) {
        Helpers.hideLoadingDialog(context);
        Helpers.showError(context, 'Gagal mengirim data: $e');
      }
    }
  }

  Future<void> _resetTour() async {
    final confirmed = await Helpers.showConfirmDialog(
      context,
      title: 'Tampilkan Panduan',
      message: 'Apakah Anda ingin melihat panduan aplikasi lagi?',
      confirmText: 'Ya',
      cancelText: 'Tidak',
    );

    if (confirmed) {
      final tourService = ref.read(tourGuideServiceProvider);
      await tourService.resetAllTours();
      if (mounted) {
        _showDashboardTour();
      }
    }
  }
}

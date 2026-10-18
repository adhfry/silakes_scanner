import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/tour_helper.dart';
import '../../../core/providers/service_providers.dart';
import '../widgets/camera_overlay_widget.dart';
import 'preview_edit_screen.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  FlashMode _flashMode = FlashMode.off;

  // Tour Guide Keys
  final GlobalKey _overlayKey = GlobalKey();
  final GlobalKey _captureButtonKey = GlobalKey();
  final GlobalKey _flashButtonKey = GlobalKey();
  final GlobalKey _galleryButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _checkAndShowTour();
  }

  /// Check dan tampilkan tour jika diperlukan
  Future<void> _checkAndShowTour() async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (!mounted || !_isInitialized) return;
    
    final tourService = ref.read(tourGuideServiceProvider);
    final isCompleted = await tourService.isCameraTourCompleted();
    
    if (!isCompleted && mounted) {
      _showCameraTour();
    }
  }

  /// Tampilkan camera tour
  void _showCameraTour() {
    final targets = <TargetFocus>[
      // 1. Camera Preview & Overlay
      TourHelper.createTarget(
        key: _overlayKey,
        title: 'Area Panduan KTP 📋',
        description: 'Ini adalah panduan untuk memposisikan KTP dengan benar:\n\n'
            '• Pastikan KTP berada di dalam kotak putih\n'
            '• KTP harus horizontal (memanjang kiri-kanan)\n'
            '• Pastikan semua teks KTP terlihat jelas\n'
            '• Hindari bayangan atau pantulan cahaya\n'
            '• Gunakan pencahayaan yang cukup\n\n'
            'Tips: Letakkan KTP di permukaan datar untuk hasil terbaik.',
        align: ContentAlign.bottom,
      ),
      
      // 2. Flash Button
      TourHelper.createTarget(
        key: _flashButtonKey,
        title: 'Tombol Flash 💡',
        description: 'Gunakan tombol ini untuk mengatur flash kamera:\n\n'
            '• Flash OFF: Tanpa lampu flash (default)\n'
            '• Flash ON: Selalu menggunakan flash\n'
            '• Flash AUTO: Flash otomatis sesuai kondisi cahaya\n\n'
            'Gunakan flash jika ruangan kurang terang, tapi hindari jika ada pantulan di KTP.',
        align: ContentAlign.bottom,
      ),
      
      // 3. Gallery Button
      TourHelper.createTarget(
        key: _galleryButtonKey,
        title: 'Pilih dari Galeri 🖼️',
        description: 'Tidak perlu foto baru? Klik tombol ini untuk:\n\n'
            '• Memilih foto KTP yang sudah ada di galeri\n'
            '• Menggunakan foto yang sudah jelas dan bagus\n'
            '• Tidak perlu scan ulang jika sudah punya foto\n\n'
            'Foto akan langsung diproses dengan OCR.',
        align: ContentAlign.bottom,
      ),
      
      // 4. Capture Button
      TourHelper.createTarget(
        key: _captureButtonKey,
        title: 'Tombol Ambil Foto 📸',
        description: 'Tombol utama untuk mengambil foto KTP:\n\n'
            'Langkah-langkah:\n'
            '1. Pastikan KTP di dalam kotak panduan\n'
            '2. Pegang HP dengan stabil\n'
            '3. Pastikan fokus kamera sudah jelas\n'
            '4. Klik tombol ini untuk ambil foto\n\n'
            'Setelah foto diambil:\n'
            '• AI akan mengekstrak data otomatis (OCR)\n'
            '• Data bisa diedit jika ada yang salah\n'
            '• Foto dan data tersimpan di riwayat',
        align: ContentAlign.top,
        shape: ShapeLightFocus.Circle,
      ),
    ];

    TourHelper.showTour(
      context: context,
      targets: targets,
      onFinish: () async {
        final tourService = ref.read(tourGuideServiceProvider);
        await tourService.completeCameraTour();
        Logger.info('Camera tour completed', tag: 'Camera');
      },
      onSkip: () async {
        final tourService = ref.read(tourGuideServiceProvider);
        await tourService.skipAllTours();
        Logger.info('All tours skipped from camera', tag: 'Camera');
      },
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      // Request permission
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          Helpers.showError(context, 'Izin kamera diperlukan');
          Navigator.of(context).pop();
        }
        return;
      }

      // Get available cameras
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('No cameras available');
      }

      // Initialize camera controller dengan kamera belakang
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() => _isInitialized = true);
        Logger.success('Camera initialized', tag: 'CameraScreen');
      }
    } catch (e) {
      Logger.error('Failed to initialize camera', tag: 'CameraScreen', error: e);
      if (mounted) {
        Helpers.showError(context, 'Gagal membuka kamera: $e');
      }
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (_isProcessing) return;

    try {
      setState(() => _isProcessing = true);

      // Take picture
      final XFile imageFile = await _cameraController!.takePicture();
      
      Logger.success('Picture taken: ${imageFile.path}', tag: 'CameraScreen');

      // Navigate to preview screen
      if (mounted) {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => PreviewEditScreen(
              imageFile: File(imageFile.path),
            ),
          ),
        );

        // Return result to dashboard
        if (result == true && mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      Logger.error('Failed to take picture', tag: 'CameraScreen', error: e);
      if (mounted) {
        Helpers.showError(context, 'Gagal mengambil foto');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null && mounted) {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => PreviewEditScreen(
              imageFile: File(image.path),
            ),
          ),
        );

        if (result == true && mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      Logger.error('Failed to pick image', tag: 'CameraScreen', error: e);
      if (mounted) {
        Helpers.showError(context, 'Gagal memilih gambar');
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      FlashMode newMode;
      if (_flashMode == FlashMode.off) {
        newMode = FlashMode.torch;
      } else {
        newMode = FlashMode.off;
      }

      await _cameraController!.setFlashMode(newMode);
      setState(() => _flashMode = newMode);
    } catch (e) {
      Logger.error('Failed to toggle flash', tag: 'CameraScreen', error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          if (_isInitialized && _cameraController != null)
            Center(
              child: CameraPreview(_cameraController!),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Overlay Guide
          if (_isInitialized)
            CameraOverlayWidget(key: _overlayKey),

          // Top Controls
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),

                    // Title
                    const Text(
                      'Scan KTP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Flash Toggle
                    IconButton(
                      key: _flashButtonKey,
                      icon: Icon(
                        _flashMode == FlashMode.torch
                            ? Icons.flash_on
                            : Icons.flash_off,
                        color: Colors.white,
                      ),
                      onPressed: _toggleFlash,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacingLarge),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Instruction
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMedium,
                        vertical: AppTheme.spacingSmall,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                      ),
                      child: const Text(
                        'Posisikan KTP di dalam frame',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingLarge),

                    // Camera Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Gallery Button
                        _buildControlButton(
                          key: _galleryButtonKey,
                          icon: Icons.photo_library,
                          onTap: _pickFromGallery,
                        ),

                        // Capture Button
                        GestureDetector(
                          key: _captureButtonKey,
                          onTap: _isProcessing ? null : _takePicture,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 4,
                              ),
                            ),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _isProcessing
                                    ? AppTheme.textSecondaryColor
                                    : Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: _isProcessing
                                  ? const Padding(
                                      padding: EdgeInsets.all(20),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.camera_alt,
                                      color: AppTheme.primaryColor,
                                      size: 36,
                                    ),
                            ),
                          ),
                        ),

                        // Placeholder for symmetry
                        const SizedBox(width: 56),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Processing Overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Mengambil foto...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    Key? key,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      key: key,
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

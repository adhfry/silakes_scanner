import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../../core/models/patient_data.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/logger.dart';
import '../../../core/providers/service_providers.dart';
import '../../../core/providers/history_provider.dart';

class PreviewEditScreen extends ConsumerStatefulWidget {
  final File imageFile;
  final PatientData? existingData;
  final bool isFromHistory;

  const PreviewEditScreen({
    super.key,
    required this.imageFile,
    this.existingData,
  }) : isFromHistory = false;

  @override
  ConsumerState<PreviewEditScreen> createState() => _PreviewEditScreenState();
}

class PreviewEditScreenFromHistory extends ConsumerStatefulWidget {
  final File imageFile;
  final PatientData existingData;

  const PreviewEditScreenFromHistory({
    super.key,
    required this.imageFile,
    required this.existingData,
  });

  @override
  ConsumerState<PreviewEditScreenFromHistory> createState() => _PreviewEditScreenFromHistoryState();
}

class _PreviewEditScreenState extends ConsumerState<PreviewEditScreen> {
  // State
  bool _isProcessing = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Controllers
  final Map<String, TextEditingController> _controllers = {};
  final _formKey = GlobalKey<FormState>();
  
  // Image zoom & pan
  final TransformationController _transformationController = TransformationController();
  
  // Layout control
  double _imagePreviewHeight = 250.0; // Initial height
  final double _minHeight = 150.0;
  final double _maxHeight = 500.0;

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      // Load dari existing data
      _initializeControllers(widget.existingData!);
      setState(() => _isProcessing = false);
    } else {
      // Process OCR untuk foto baru
      _processImage();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _transformationController.dispose();
    super.dispose();
  }

  /// Process image dengan OCR
  Future<void> _processImage() async {
    try {
      setState(() {
        _isProcessing = true;
        _errorMessage = null;
      });

      Logger.info('Starting OCR processing', tag: 'PreviewEdit');

      // 1. Get Gemini API Key
      final configService = ref.read(configServiceProvider);
      final apiKey = await configService.getGeminiApiKey();

      // 2. Process OCR
      final geminiService = ref.read(geminiServiceProvider);
      final extractedData = await geminiService.extractKtpData(
        widget.imageFile,
        apiKey,
      );

      Logger.success('OCR completed', tag: 'PreviewEdit');

      // 3. Check NIK di database SiLAKES
      bool isRegistered = false;
      if (extractedData.nik != null && extractedData.isNikValid) {
        Logger.info('Checking NIK: ${extractedData.nik}', tag: 'PreviewEdit');
        
        final silakesApi = ref.read(silakesApiServiceProvider);
        isRegistered = await silakesApi.isNikRegistered(extractedData.nik!);

        if (isRegistered) {
          Logger.warning('NIK already registered', tag: 'PreviewEdit');
        } else {
          Logger.info('NIK not registered, continue to edit', tag: 'PreviewEdit');
        }
      }

      // 4. Simpan ke history HANYA jika ada data yang valid
      // (tidak menyimpan jika semua field kosong)
      if (extractedData.nik != null || extractedData.nama != null) {
        final dataWithStatus = extractedData.copyWith(
          imagePath: widget.imageFile.path,
          isRegistered: isRegistered,
          isSubmitted: false,
        );
        
        Logger.info('Saving OCR result to history', tag: 'PreviewEdit');
        await ref.read(historyProvider.notifier).addToHistory(dataWithStatus);
        Logger.success('OCR result saved to history', tag: 'PreviewEdit');
      } else {
        Logger.warning('Skipping history save - no valid data', tag: 'PreviewEdit');
      }

      // 5. Jika sudah terdaftar, tampilkan dialog
      if (isRegistered && mounted) {
        _showAlreadyRegisteredDialog();
        return;
      }

      // 6. Setup form dengan data hasil OCR
      _initializeControllers(extractedData);

      setState(() {
        _isProcessing = false;
      });
    } catch (e, stackTrace) {
      Logger.error('Processing failed', tag: 'PreviewEdit', error: e, stackTrace: stackTrace);
      
      // Cek jenis error
      String errorMessage;
      String errorTitle = 'Gagal Memproses Gambar';
      
      if (e.toString().contains('KTP_NOT_DETECTED')) {
        errorTitle = 'KTP Tidak Terdeteksi';
        errorMessage = 'Foto KTP tidak dapat terdeteksi atau tidak jelas.\n\n'
            'Pastikan:\n'
            '• Foto KTP terlihat jelas dan tidak blur\n'
            '• KTP berada di dalam frame\n'
            '• Pencahayaan cukup terang\n'
            '• Tidak ada bayangan atau pantulan cahaya\n'
            '• KTP dalam posisi horizontal\n\n'
            'Silakan ambil foto ulang dengan kondisi yang lebih baik.';
      } else if (e.toString().contains('KTP_INCOMPLETE')) {
        errorTitle = 'Data KTP Tidak Lengkap';
        errorMessage = 'Data penting pada KTP tidak dapat terbaca.\n\n'
            'Pastikan:\n'
            '• NIK dan Nama terlihat jelas\n'
            '• Foto tidak terpotong\n'
            '• Fokus kamera tajam\n'
            '• Tidak ada objek yang menutupi KTP\n\n'
            'Silakan foto ulang dengan memastikan semua teks KTP terlihat jelas.';
      } else {
        errorMessage = 'Terjadi kesalahan saat memproses foto KTP.\n\n'
            'Kemungkinan penyebab:\n'
            '• Koneksi internet tidak stabil\n'
            '• Foto terlalu besar atau tidak didukung\n'
            '• Server OCR sedang sibuk\n\n'
            'Silakan coba lagi atau gunakan foto yang berbeda.';
      }
      
      setState(() {
        _isProcessing = false;
        _errorMessage = errorMessage;
      });

      if (mounted) {
        // Langsung tampilkan dialog tanpa setState error
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showOcrFailedDialog(errorTitle, errorMessage);
          }
        });
      }
    }
  }

  /// Dialog ketika OCR gagal
  void _showOcrFailedDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppTheme.warningColor,
          size: 64,
        ),
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(
            message,
            style: const TextStyle(height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Back to camera
            },
            child: const Text('Foto Ulang'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Back to camera
              Navigator.of(context).pop(false); // Back to dashboard
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Kembali ke Dashboard'),
          ),
        ],
      ),
    );
  }

  /// Initialize controllers dari data OCR
  void _initializeControllers(PatientData data) {
    _controllers['nik'] = TextEditingController(text: data.nik);
    _controllers['nama'] = TextEditingController(text: data.nama);
    _controllers['tempat_lahir'] = TextEditingController(text: data.tempatLahir);
    _controllers['tanggal_lahir'] = TextEditingController(text: data.tanggalLahir);
    _controllers['jenis_kelamin'] = TextEditingController(text: data.jenisKelamin);
    _controllers['alamat'] = TextEditingController(text: data.alamat);
    _controllers['rt_rw'] = TextEditingController(text: data.rtRw);
    _controllers['kel_desa'] = TextEditingController(text: data.kelDesa);
    _controllers['kecamatan'] = TextEditingController(text: data.kecamatan);
    _controllers['agama'] = TextEditingController(text: data.agama);
    _controllers['status_perkawinan'] = TextEditingController(text: data.statusPerkawinan);
    _controllers['pekerjaan'] = TextEditingController(text: data.pekerjaan);
  }

  /// Dialog NIK sudah terdaftar
  void _showAlreadyRegisteredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(
          Icons.info_outline,
          color: AppTheme.infoColor,
          size: 48,
        ),
        title: const Text('Pasien Sudah Terdaftar'),
        content: const Text(
          'NIK ini sudah terdaftar di sistem SiLAKES. '
          'Tidak perlu melakukan registrasi ulang.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Back to camera
              Navigator.of(context).pop(false); // Back to dashboard
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Submit data ke Firebase
  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) {
      Helpers.showWarning(context, 'Mohon lengkapi semua field yang wajib diisi');
      return;
    }

    try {
      setState(() => _isSubmitting = true);

      // Build patient data dari form
      final updatedData = PatientData(
        nik: _controllers['nik']!.text.trim(),
        nama: _controllers['nama']!.text.trim(),
        tempatLahir: _controllers['tempat_lahir']!.text.trim(),
        tanggalLahir: _controllers['tanggal_lahir']!.text.trim(),
        jenisKelamin: _controllers['jenis_kelamin']!.text.trim(),
        alamat: _controllers['alamat']!.text.trim(),
        rtRw: _controllers['rt_rw']!.text.trim(),
        kelDesa: _controllers['kel_desa']!.text.trim(),
        kecamatan: _controllers['kecamatan']!.text.trim(),
        agama: _controllers['agama']!.text.trim(),
        statusPerkawinan: _controllers['status_perkawinan']!.text.trim(),
        pekerjaan: _controllers['pekerjaan']!.text.trim(),
        scannedAt: DateTime.now(),
      );

      Logger.info('Submitting patient data', tag: 'PreviewEdit');

      // 1. Kirim ke Firebase
      final firebaseService = ref.read(firebaseServiceProvider);
      await firebaseService.sendNewPatient(updatedData);

      // 2. Update status submitted di history
      final dataWithSubmitted = updatedData.copyWith(
        imagePath: widget.imageFile.path,
        isSubmitted: true,
        isRegistered: false,
      );
      
      final cacheService = ref.read(localCacheServiceProvider);
      await cacheService.saveToHistory(dataWithSubmitted);

      // 3. Refresh history provider
      await ref.read(historyProvider.notifier).refresh();

      Logger.success('Patient data submitted successfully', tag: 'PreviewEdit');

      if (mounted) {
        Helpers.showSuccess(context, 'Data pasien berhasil disimpan!');
        
        // Delay sedikit agar snackbar muncul
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          // Langsung kembali ke dashboard dengan popUntil
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e, stackTrace) {
      Logger.error('Submit failed', tag: 'PreviewEdit', error: e, stackTrace: stackTrace);
      
      if (mounted) {
        Helpers.showError(context, 'Gagal menyimpan data: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview & Edit Data'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isProcessing) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    return _buildFormState();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LoadingAnimationWidget.staggeredDotsWave(
            color: AppTheme.primaryColor,
            size: 64,
          ),
          const SizedBox(height: AppTheme.spacingLarge),
          const Text(
            'Memproses gambar...',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          const Text(
            'Mengekstrak data KTP dengan AI',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textHintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: AppTheme.errorColor,
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            const Text(
              'Gagal Memproses Gambar',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            Text(
              _errorMessage ?? 'Terjadi kesalahan',
              style: const TextStyle(color: AppTheme.textSecondaryColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Kembali'),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            OutlinedButton.icon(
              onPressed: _processImage,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormState() {
    return Column(
      children: [
        // Image Preview dengan Zoom & Pan
        Container(
          height: _imagePreviewHeight,
          width: double.infinity,
          color: Colors.black,
          child: Stack(
            children: [
              // Zoomable Image
              InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.5,
                maxScale: 4.0,
                panEnabled: true,
                scaleEnabled: true,
                child: Center(
                  child: Image.file(
                    widget.imageFile,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              
              // Reset Zoom Button
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    onTap: () {
                      _transformationController.value = Matrix4.identity();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.zoom_out_map,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Zoom Info
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Pinch to zoom',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Drag Handle untuk resize
        GestureDetector(
          onVerticalDragUpdate: (details) {
            setState(() {
              _imagePreviewHeight = (_imagePreviewHeight + details.delta.dy)
                  .clamp(_minHeight, _maxHeight);
            });
          },
          child: Container(
            height: 32,
            width: double.infinity,
            color: AppTheme.surfaceColor,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textHintColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textHintColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Form
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              children: [
                _buildSectionTitle('Data Identitas'),
                _buildTextField('nik', 'NIK', required: true, maxLength: 16),
                _buildTextField('nama', 'Nama Lengkap', required: true),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField('tempat_lahir', 'Tempat Lahir', required: true),
                    ),
                    const SizedBox(width: AppTheme.spacingSmall),
                    Expanded(
                      child: _buildTextField('tanggal_lahir', 'Tanggal Lahir', required: true),
                    ),
                  ],
                ),
                
                _buildTextField('jenis_kelamin', 'Jenis Kelamin', required: true),
                
                const SizedBox(height: AppTheme.spacingMedium),
                _buildSectionTitle('Alamat'),
                _buildTextField('alamat', 'Alamat', required: true, maxLines: 2),
                _buildTextField('rt_rw', 'RT/RW'),
                _buildTextField('kel_desa', 'Kel/Desa'),
                _buildTextField('kecamatan', 'Kecamatan'),
                
                const SizedBox(height: AppTheme.spacingMedium),
                _buildSectionTitle('Data Lainnya'),
                _buildTextField('agama', 'Agama'),
                _buildTextField('status_perkawinan', 'Status Perkawinan'),
                _buildTextField('pekerjaan', 'Pekerjaan'),
                
                const SizedBox(height: AppTheme.spacingLarge),
                
                // Submit Button
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitData,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send),
                  label: Text(_isSubmitting ? 'Mengirim...' : 'Simpan Data'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacingMedium),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppTheme.spacingSmall,
        bottom: AppTheme.spacingMedium,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String key,
    String label, {
    bool required = false,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      child: TextFormField(
        controller: _controllers[key],
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: 'Masukkan $label',
          counterText: '',
        ),
        maxLines: maxLines,
        maxLength: maxLength,
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$label wajib diisi';
                }
                if (key == 'nik' && !Helpers.isValidNik(value)) {
                  return 'NIK harus 16 digit angka';
                }
                return null;
              }
            : null,
      ),
    );
  }
}

/// State untuk edit dari history (tidak perlu OCR lagi)
class _PreviewEditScreenFromHistoryState extends ConsumerState<PreviewEditScreenFromHistory> {
  // State
  bool _isSubmitting = false;

  // Controllers
  final Map<String, TextEditingController> _controllers = {};
  final _formKey = GlobalKey<FormState>();
  
  // Image zoom & pan
  final TransformationController _transformationController = TransformationController();
  
  // Layout control
  double _imagePreviewHeight = 250.0;
  final double _minHeight = 150.0;
  final double _maxHeight = 500.0;

  @override
  void initState() {
    super.initState();
    _initializeControllers(widget.existingData);
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _transformationController.dispose();
    super.dispose();
  }

  void _initializeControllers(PatientData data) {
    _controllers['nik'] = TextEditingController(text: data.nik);
    _controllers['nama'] = TextEditingController(text: data.nama);
    _controllers['tempat_lahir'] = TextEditingController(text: data.tempatLahir);
    _controllers['tanggal_lahir'] = TextEditingController(text: data.tanggalLahir);
    _controllers['jenis_kelamin'] = TextEditingController(text: data.jenisKelamin);
    _controllers['alamat'] = TextEditingController(text: data.alamat);
    _controllers['rt_rw'] = TextEditingController(text: data.rtRw);
    _controllers['kel_desa'] = TextEditingController(text: data.kelDesa);
    _controllers['kecamatan'] = TextEditingController(text: data.kecamatan);
    _controllers['agama'] = TextEditingController(text: data.agama);
    _controllers['status_perkawinan'] = TextEditingController(text: data.statusPerkawinan);
    _controllers['pekerjaan'] = TextEditingController(text: data.pekerjaan);
  }

  Future<void> _submitData() async {
    if (!_formKey.currentState!.validate()) {
      Helpers.showWarning(context, 'Mohon lengkapi semua field yang wajib diisi');
      return;
    }

    try {
      setState(() => _isSubmitting = true);

      final updatedData = PatientData(
        nik: _controllers['nik']!.text.trim(),
        nama: _controllers['nama']!.text.trim(),
        tempatLahir: _controllers['tempat_lahir']!.text.trim(),
        tanggalLahir: _controllers['tanggal_lahir']!.text.trim(),
        jenisKelamin: _controllers['jenis_kelamin']!.text.trim(),
        alamat: _controllers['alamat']!.text.trim(),
        rtRw: _controllers['rt_rw']!.text.trim(),
        kelDesa: _controllers['kel_desa']!.text.trim(),
        kecamatan: _controllers['kecamatan']!.text.trim(),
        agama: _controllers['agama']!.text.trim(),
        statusPerkawinan: _controllers['status_perkawinan']!.text.trim(),
        pekerjaan: _controllers['pekerjaan']!.text.trim(),
        scannedAt: widget.existingData.scannedAt ?? DateTime.now(),
        imagePath: widget.imageFile.path,
      );

      Logger.info('Checking NIK and submitting', tag: 'PreviewEditHistory');

      // 1. Cek NIK apakah sudah terdaftar
      bool isRegistered = false;
      if (updatedData.nik != null && updatedData.isNikValid) {
        final silakesApi = ref.read(silakesApiServiceProvider);
        isRegistered = await silakesApi.isNikRegistered(updatedData.nik!);
      }

      if (isRegistered) {
        // Update status di history
        final dataWithRegistered = updatedData.copyWith(
          isRegistered: true,
          isSubmitted: true,
        );
        
        final cacheService = ref.read(localCacheServiceProvider);
        await cacheService.saveToHistory(dataWithRegistered);
        await ref.read(historyProvider.notifier).refresh();

        Logger.info('NIK already registered', tag: 'PreviewEditHistory');

        if (mounted) {
          Helpers.showInfo(context, 'Pasien sudah terdaftar di sistem');
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        }
        return;
      }

      // 2. Kirim ke Firebase
      final firebaseService = ref.read(firebaseServiceProvider);
      await firebaseService.sendNewPatient(updatedData);

      // 3. Update status submitted
      final dataWithSubmitted = updatedData.copyWith(
        isSubmitted: true,
        isRegistered: false,
      );
      
      final cacheService = ref.read(localCacheServiceProvider);
      await cacheService.saveToHistory(dataWithSubmitted);
      await ref.read(historyProvider.notifier).refresh();

      Logger.success('Patient data submitted successfully', tag: 'PreviewEditHistory');

      if (mounted) {
        Helpers.showSuccess(context, 'Data pasien berhasil disimpan!');
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e, stackTrace) {
      Logger.error('Submit failed', tag: 'PreviewEditHistory', error: e, stackTrace: stackTrace);
      
      if (mounted) {
        Helpers.showError(context, 'Gagal menyimpan data: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Data Pasien'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Image Preview dengan Zoom & Pan
          Container(
            height: _imagePreviewHeight,
            width: double.infinity,
            color: Colors.black,
            child: Stack(
              children: [
                InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 0.5,
                  maxScale: 4.0,
                  panEnabled: true,
                  scaleEnabled: true,
                  child: Center(
                    child: Image.file(
                      widget.imageFile,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: () {
                        _transformationController.value = Matrix4.identity();
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.zoom_out_map,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Pinch to zoom',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Drag Handle
          GestureDetector(
            onVerticalDragUpdate: (details) {
              setState(() {
                _imagePreviewHeight = (_imagePreviewHeight + details.delta.dy)
                    .clamp(_minHeight, _maxHeight);
              });
            },
            child: Container(
              height: 32,
              width: double.infinity,
              color: AppTheme.surfaceColor,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.textHintColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.textHintColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Form
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                children: [
                  _buildSectionTitle('Data Identitas'),
                  _buildTextField('nik', 'NIK', required: true, maxLength: 16),
                  _buildTextField('nama', 'Nama Lengkap', required: true),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField('tempat_lahir', 'Tempat Lahir', required: true),
                      ),
                      const SizedBox(width: AppTheme.spacingSmall),
                      Expanded(
                        child: _buildTextField('tanggal_lahir', 'Tanggal Lahir', required: true),
                      ),
                    ],
                  ),
                  
                  _buildTextField('jenis_kelamin', 'Jenis Kelamin', required: true),
                  
                  const SizedBox(height: AppTheme.spacingMedium),
                  _buildSectionTitle('Alamat'),
                  _buildTextField('alamat', 'Alamat', required: true, maxLines: 2),
                  _buildTextField('rt_rw', 'RT/RW'),
                  _buildTextField('kel_desa', 'Kel/Desa'),
                  _buildTextField('kecamatan', 'Kecamatan'),
                  
                  const SizedBox(height: AppTheme.spacingMedium),
                  _buildSectionTitle('Data Lainnya'),
                  _buildTextField('agama', 'Agama'),
                  _buildTextField('status_perkawinan', 'Status Perkawinan'),
                  _buildTextField('pekerjaan', 'Pekerjaan'),
                  
                  const SizedBox(height: AppTheme.spacingLarge),
                  
                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _submitData,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(_isSubmitting ? 'Mengirim...' : 'Simpan Data'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  
                  const SizedBox(height: AppTheme.spacingMedium),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppTheme.spacingSmall,
        bottom: AppTheme.spacingMedium,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildTextField(
    String key,
    String label, {
    bool required = false,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      child: TextFormField(
        controller: _controllers[key],
        decoration: InputDecoration(
          labelText: required ? '$label *' : label,
          hintText: 'Masukkan $label',
          counterText: '',
        ),
        maxLines: maxLines,
        maxLength: maxLength,
        validator: required
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return '$label wajib diisi';
                }
                if (key == 'nik' && !Helpers.isValidNik(value)) {
                  return 'NIK harus 16 digit angka';
                }
                return null;
              }
            : null,
      ),
    );
  }
}

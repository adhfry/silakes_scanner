import 'package:firebase_database/firebase_database.dart';
import '../core/models/patient_data.dart';
import '../core/config/app_config.dart';
import '../core/utils/logger.dart';

/// Service untuk mengirim data ke Firebase Realtime Database
class FirebaseService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// Kirim data pasien baru ke Firebase RTDB
  /// Sesuai struktur Vue-Firebase: newDataPatient & tempDataPatient
  Future<void> sendNewPatient(PatientData patientData) async {
    try {
      Logger.info('Sending patient data to Firebase', tag: 'FirebaseService');

      // Prepare tempDataPatient sesuai format VueJS
      final tempDataPatient = {
        'nik': patientData.nik ?? '',
        'name': patientData.nama ?? '',
        'tempat_lahir': patientData.tempatLahir ?? '',
        'tgl_lahir': patientData.tanggalLahir ?? '',
        'gender': patientData.jenisKelamin?.toUpperCase().substring(0, 1) ?? '',
        'alamat': patientData.alamat ?? '',
        'rt_rw': patientData.rtRw ?? '',
        'kel_desa': patientData.kelDesa ?? '',
        'kecamatan': patientData.kecamatan ?? '',
        'agama': patientData.agama ?? '',
        'status_perkawinan': patientData.statusPerkawinan ?? '',
        'pekerjaan': patientData.pekerjaan ?? '',
        'phone': '', // Tidak ada di KTP
        'no_reg': '', // Diisi oleh backend/VueJS
        'jabatan': '', // Tidak ada di KTP
        'pangkat': '', // Tidak ada di KTP
      };

      // Set ke path vue-firebase
      final ref = _database.child(AppConfig.firebaseRootNode);

      await ref.update({
        'newDataPatient': true,
        'tempDataPatient': tempDataPatient,
      });

      Logger.success(
        'Patient data sent to Firebase (vue-firebase)',
        tag: 'FirebaseService',
      );
    } catch (e, stackTrace) {
      Logger.error(
        'Failed to send patient data to Firebase',
        tag: 'FirebaseService',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Update status trigger (optional, jika diperlukan)
  Future<void> updateNewDataTrigger(String patientId, bool value) async {
    try {
      final ref = _database
          .child(AppConfig.firebasePatientNode)
          .child(patientId)
          .child('newDataPatient');

      await ref.set(value);

      Logger.info(
        'Updated newDataPatient trigger: $value',
        tag: 'FirebaseService',
      );
    } catch (e) {
      Logger.error(
        'Failed to update trigger',
        tag: 'FirebaseService',
        error: e,
      );
      rethrow;
    }
  }

  /// Test koneksi Firebase
  Future<bool> testConnection() async {
    try {
      Logger.info('Testing Firebase connection', tag: 'FirebaseService');

      final ref = _database.child('test');
      await ref.set({'timestamp': ServerValue.timestamp});
      await ref.remove();

      Logger.success(
        'Firebase connection test successful',
        tag: 'FirebaseService',
      );
      return true;
    } catch (e) {
      Logger.error(
        'Firebase connection test failed',
        tag: 'FirebaseService',
        error: e,
      );
      return false;
    }
  }
}

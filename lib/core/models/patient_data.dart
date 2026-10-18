import 'package:hive/hive.dart';

part 'patient_data.g.dart';

/// Model data pasien dari hasil scan KTP
@HiveType(typeId: 0)
class PatientData {
  @HiveField(0)
  final String? nik;

  @HiveField(1)
  final String? nama;

  @HiveField(2)
  final String? tempatLahir;

  @HiveField(3)
  final String? tanggalLahir;

  @HiveField(4)
  final String? jenisKelamin;

  @HiveField(5)
  final String? alamat;

  @HiveField(6)
  final String? rtRw;

  @HiveField(7)
  final String? kelDesa;

  @HiveField(8)
  final String? kecamatan;

  @HiveField(9)
  final String? agama;

  @HiveField(10)
  final String? statusPerkawinan;

  @HiveField(11)
  final String? pekerjaan;

  @HiveField(14)
  final DateTime? scannedAt;

  @HiveField(15)
  final String? imageUrl;

  @HiveField(16)
  final String? imagePath; // Path lokal gambar KTP

  @HiveField(17)
  final bool isRegistered; // Status apakah sudah terdaftar di database

  @HiveField(18)
  final bool isSubmitted; // Status apakah sudah berhasil submit ke Firebase

  @HiveField(19)
  final String? id; // Unique ID untuk identifikasi record

  PatientData({
    this.nik,
    this.nama,
    this.tempatLahir,
    this.tanggalLahir,
    this.jenisKelamin,
    this.alamat,
    this.rtRw,
    this.kelDesa,
    this.kecamatan,
    this.agama,
    this.statusPerkawinan,
    this.pekerjaan,
    this.scannedAt,
    this.imageUrl,
    this.imagePath,
    this.isRegistered = false,
    this.isSubmitted = false,
    String? id,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  /// Copy with method untuk immutability
  PatientData copyWith({
    String? nik,
    String? nama,
    String? tempatLahir,
    String? tanggalLahir,
    String? jenisKelamin,
    String? alamat,
    String? rtRw,
    String? kelDesa,
    String? kecamatan,
    String? agama,
    String? statusPerkawinan,
    String? pekerjaan,
    DateTime? scannedAt,
    String? imageUrl,
    String? imagePath,
    bool? isRegistered,
    bool? isSubmitted,
    String? id,
  }) {
    return PatientData(
      nik: nik ?? this.nik,
      nama: nama ?? this.nama,
      tempatLahir: tempatLahir ?? this.tempatLahir,
      tanggalLahir: tanggalLahir ?? this.tanggalLahir,
      jenisKelamin: jenisKelamin ?? this.jenisKelamin,
      alamat: alamat ?? this.alamat,
      rtRw: rtRw ?? this.rtRw,
      kelDesa: kelDesa ?? this.kelDesa,
      kecamatan: kecamatan ?? this.kecamatan,
      agama: agama ?? this.agama,
      statusPerkawinan: statusPerkawinan ?? this.statusPerkawinan,
      pekerjaan: pekerjaan ?? this.pekerjaan,
      scannedAt: scannedAt ?? this.scannedAt,
      imageUrl: imageUrl ?? this.imageUrl,
      imagePath: imagePath ?? this.imagePath,
      isRegistered: isRegistered ?? this.isRegistered,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      id: id ?? this.id,
    );
  }

  /// Convert to JSON untuk Firebase
  Map<String, dynamic> toJson() {
    return {
      'nik': nik,
      'nama': nama,
      'tempat_lahir': tempatLahir,
      'tanggal_lahir': tanggalLahir,
      'jenis_kelamin': jenisKelamin,
      'alamat': alamat,
      'rt_rw': rtRw,
      'kel_desa': kelDesa,
      'kecamatan': kecamatan,
      'agama': agama,
      'status_perkawinan': statusPerkawinan,
      'pekerjaan': pekerjaan,
      'scanned_at': scannedAt?.toIso8601String(),
      'image_url': imageUrl,
      'is_registered': isRegistered,
      'is_submitted': isSubmitted,
      'id': id,
    };
  }

  /// Create from JSON
  factory PatientData.fromJson(Map<String, dynamic> json) {
    return PatientData(
      nik: json['nik'] as String?,
      nama: json['nama'] as String?,
      tempatLahir: json['tempat_lahir'] as String?,
      tanggalLahir: json['tanggal_lahir'] as String?,
      jenisKelamin: json['jenis_kelamin'] as String?,
      alamat: json['alamat'] as String?,
      rtRw: json['rt_rw'] as String?,
      kelDesa: json['kel_desa'] as String?,
      kecamatan: json['kecamatan'] as String?,
      agama: json['agama'] as String?,
      statusPerkawinan: json['status_perkawinan'] as String?,
      pekerjaan: json['pekerjaan'] as String?,
      scannedAt: json['scanned_at'] != null
          ? DateTime.parse(json['scanned_at'] as String)
          : null,
      imageUrl: json['image_url'] as String?,
      imagePath: json['image_path'] as String?,
      isRegistered: json['is_registered'] as bool? ?? false,
      isSubmitted: json['is_submitted'] as bool? ?? false,
      id: json['id'] as String?,
    );
  }

  /// Validate NIK (16 digits)
  bool get isNikValid {
    if (nik == null) return false;
    return nik!.length == 16 && int.tryParse(nik!) != null;
  }

  /// Check if data is complete
  bool get isComplete {
    return nik != null &&
        nama != null &&
        tempatLahir != null &&
        tanggalLahir != null &&
        jenisKelamin != null &&
        alamat != null;
  }

  @override
  String toString() {
    return 'PatientData(nik: $nik, nama: $nama)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PatientData && other.nik == nik;
  }

  @override
  int get hashCode => nik.hashCode;
}

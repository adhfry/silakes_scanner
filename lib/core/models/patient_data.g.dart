// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PatientDataAdapter extends TypeAdapter<PatientData> {
  @override
  final int typeId = 0;

  @override
  PatientData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PatientData(
      nik: fields[0] as String?,
      nama: fields[1] as String?,
      tempatLahir: fields[2] as String?,
      tanggalLahir: fields[3] as String?,
      jenisKelamin: fields[4] as String?,
      alamat: fields[5] as String?,
      rtRw: fields[6] as String?,
      kelDesa: fields[7] as String?,
      kecamatan: fields[8] as String?,
      agama: fields[9] as String?,
      statusPerkawinan: fields[10] as String?,
      pekerjaan: fields[11] as String?,
      scannedAt: fields[14] as DateTime?,
      imageUrl: fields[15] as String?,
      imagePath: fields[16] as String?,
      isRegistered: fields[17] as bool,
      isSubmitted: fields[18] as bool,
      id: fields[19] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PatientData obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.nik)
      ..writeByte(1)
      ..write(obj.nama)
      ..writeByte(2)
      ..write(obj.tempatLahir)
      ..writeByte(3)
      ..write(obj.tanggalLahir)
      ..writeByte(4)
      ..write(obj.jenisKelamin)
      ..writeByte(5)
      ..write(obj.alamat)
      ..writeByte(6)
      ..write(obj.rtRw)
      ..writeByte(7)
      ..write(obj.kelDesa)
      ..writeByte(8)
      ..write(obj.kecamatan)
      ..writeByte(9)
      ..write(obj.agama)
      ..writeByte(10)
      ..write(obj.statusPerkawinan)
      ..writeByte(11)
      ..write(obj.pekerjaan)
      ..writeByte(14)
      ..write(obj.scannedAt)
      ..writeByte(15)
      ..write(obj.imageUrl)
      ..writeByte(16)
      ..write(obj.imagePath)
      ..writeByte(17)
      ..write(obj.isRegistered)
      ..writeByte(18)
      ..write(obj.isSubmitted)
      ..writeByte(19)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatientDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

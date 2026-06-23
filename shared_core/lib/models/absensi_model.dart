enum AbsensiStatus { Hadir, Sakit, Izin, Alpa }

class AbsensiModel {
  final int absensiId;
  final int sesiId;
  final int mahasiswaId;
  final DateTime waktuScan;
  final double latMahasiswa;
  final double longMahasiswa;
  final double jarakMeter;
  final AbsensiStatus status;

  AbsensiModel({
    required this.absensiId,
    required this.sesiId,
    required this.mahasiswaId,
    required this.waktuScan,
    required this.latMahasiswa,
    required this.longMahasiswa,
    required this.jarakMeter,
    required this.status,
  });

  factory AbsensiModel.fromJson(Map<String, dynamic> json) {
    return AbsensiModel(
      absensiId: json['absensi_id'],
      sesiId: json['sesi_id'],
      mahasiswaId: json['mahasiswa_id'],
      waktuScan: DateTime.parse(json['waktu_scan']),
      latMahasiswa: double.parse(json['lat_mahasiswa'].toString()),
      longMahasiswa: double.parse(json['long_mahasiswa'].toString()),
      jarakMeter: double.parse(json['jarak_meter'].toString()),
      status: AbsensiStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => AbsensiStatus.Alpa,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'absensi_id': absensiId,
      'sesi_id': sesiId,
      'mahasiswa_id': mahasiswaId,
      'waktu_scan': waktuScan.toIso8601String(),
      'lat_mahasiswa': latMahasiswa,
      'long_mahasiswa': longMahasiswa,
      'jarak_meter': jarakMeter,
      'status': status.name,
    };
  }
}

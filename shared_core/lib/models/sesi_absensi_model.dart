enum SesiStatus { active, expired }

class SesiAbsensiModel {
  final int sesiId;
  final int kelasId;
  final DateTime tanggal;
  final int pertemuanKe;
  final String qrToken;
  final DateTime expiredTime;
  final double latKelas;
  final double longKelas;
  final double radiusKelas;
  final SesiStatus status;

  SesiAbsensiModel({
    required this.sesiId,
    required this.kelasId,
    required this.tanggal,
    required this.pertemuanKe,
    required this.qrToken,
    required this.expiredTime,
    required this.latKelas,
    required this.longKelas,
    required this.radiusKelas,
    required this.status,
  });

  factory SesiAbsensiModel.fromJson(Map<String, dynamic> json) {
    return SesiAbsensiModel(
      sesiId: json['sesi_id'],
      kelasId: json['kelas_id'],
      tanggal: DateTime.parse(json['tanggal']),
      pertemuanKe: json['pertemuan_ke'],
      qrToken: json['qr_token'],
      expiredTime: DateTime.parse(json['expired_time']),
      latKelas: double.parse(json['lat_kelas'].toString()),
      longKelas: double.parse(json['long_kelas'].toString()),
      radiusKelas: double.parse(json['radius_kelas'].toString()),
      status: SesiStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SesiStatus.expired,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sesi_id': sesiId,
      'kelas_id': kelasId,
      'tanggal': tanggal.toIso8601String(),
      'pertemuan_ke': pertemuanKe,
      'qr_token': qrToken,
      'expired_time': expiredTime.toIso8601String(),
      'lat_kelas': latKelas,
      'long_kelas': longKelas,
      'radius_kelas': radiusKelas,
      'status': status.name,
    };
  }
}

class KelasModel {
  final int kelasId;
  final int matakuliahId;
  final int dosenId;
  final String kodeKelas;
  final String namaKelas;
  final String hari;
  final String jamMulai;
  final String jamSelesai;

  KelasModel({
    required this.kelasId,
    required this.matakuliahId,
    required this.dosenId,
    required this.kodeKelas,
    required this.namaKelas,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
  });

  factory KelasModel.fromJson(Map<String, dynamic> json) {
    return KelasModel(
      kelasId: json['kelas_id'],
      matakuliahId: json['matakuliah_id'],
      dosenId: json['dosen_id'],
      kodeKelas: json['kode_kelas'],
      namaKelas: json['nama_kelas'],
      hari: json['hari'],
      jamMulai: json['jam_mulai'],
      jamSelesai: json['jam_selesai'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kelas_id': kelasId,
      'matakuliah_id': matakuliahId,
      'dosen_id': dosenId,
      'kode_kelas': kodeKelas,
      'nama_kelas': namaKelas,
      'hari': hari,
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
    };
  }
}

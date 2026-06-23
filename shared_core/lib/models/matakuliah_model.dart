class MatakuliahModel {
  final int matakuliahId;
  final int prodiId;
  final String kodeMk;
  final String namaMk;
  final int sks;

  MatakuliahModel({
    required this.matakuliahId,
    required this.prodiId,
    required this.kodeMk,
    required this.namaMk,
    required this.sks,
  });

  factory MatakuliahModel.fromJson(Map<String, dynamic> json) {
    return MatakuliahModel(
      matakuliahId: json['matakuliah_id'],
      prodiId: json['prodi_id'],
      kodeMk: json['kode_mk'],
      namaMk: json['nama_mk'],
      sks: json['sks'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'matakuliah_id': matakuliahId,
      'prodi_id': prodiId,
      'kode_mk': kodeMk,
      'nama_mk': namaMk,
      'sks': sks,
    };
  }
}

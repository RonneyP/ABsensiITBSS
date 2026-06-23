class ProdiModel {
  final int prodiId;
  final String namaProdi;

  ProdiModel({
    required this.prodiId,
    required this.namaProdi,
  });

  factory ProdiModel.fromJson(Map<String, dynamic> json) {
    return ProdiModel(
      prodiId: json['prodi_id'],
      namaProdi: json['nama_prodi'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prodi_id': prodiId,
      'nama_prodi': namaProdi,
    };
  }
}

enum UserRole { admin, dosen, mahasiswa }

class UserModel {
  final int userId;
  final String username;
  final String nama;
  final String email;
  final UserRole role;

  UserModel({
    required this.userId,
    required this.username,
    required this.nama,
    required this.email,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] ?? json['id'] ?? 0,
      username: json['username'] ?? '',
      nama: json['nama'] ?? '',
      email: json['email'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => UserRole.mahasiswa,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'nama': nama,
      'email': email,
      'role': role.name,
    };
  }
}

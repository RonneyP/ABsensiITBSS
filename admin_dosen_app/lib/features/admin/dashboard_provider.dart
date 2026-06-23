import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiClient apiClient;

  bool _isLoading = false;
  List<dynamic> _schedules = [];
  List<dynamic> _adminSchedules = [];
  List<dynamic> _sessions = [];
  List<dynamic> _attendanceRecords = [];
  List<dynamic> _users = [];
  List<dynamic> _mataKuliahs = [];
  List<dynamic> _kelas = [];
  List<dynamic> _prodis = [];
  String? _errorMessage;

  DashboardProvider(this.apiClient);

  bool get isLoading => _isLoading;
  List<dynamic> get schedules => _schedules;
  List<dynamic> get adminSchedules => _adminSchedules;
  List<dynamic> get sessions => _sessions;
  List<dynamic> get attendanceRecords => _attendanceRecords;
  List<dynamic> get users => _users;
  List<dynamic> get mataKuliahs => _mataKuliahs;
  List<dynamic> get kelasList => _kelas;
  List<dynamic> get prodis => _prodis;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDosenSchedules() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.get('/lecturer/schedules');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _schedules = data['schedules'] ?? data ?? [];
      } else {
        _errorMessage = 'Gagal memuat jadwal kuliah.';
      }
    } catch (e) {
      _errorMessage = 'Koneksi bermasalah: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAdminSessions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.get('/admin/attendance-sessions');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _sessions = data['sessions'] ?? data ?? [];
      } else {
        _errorMessage = 'Gagal memuat sesi absensi.';
      }
    } catch (e) {
      _errorMessage = 'Koneksi bermasalah: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAdminAttendanceRecords() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.get('/admin/attendance-records');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _attendanceRecords = data['records'] ?? data ?? [];
      } else {
        _errorMessage = 'Gagal memuat data rekap absensi.';
      }
    } catch (e) {
      _errorMessage = 'Koneksi bermasalah: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAdminSchedules() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.get('/admin/schedules');
      if (response.statusCode == 200) {
        _adminSchedules = jsonDecode(response.body);
      } else {
        _errorMessage = 'Gagal memuat jadwal semua dosen.';
      }
    } catch (e) {
      _errorMessage = 'Koneksi bermasalah: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createSession({
    required int kelasId,
    required int scheduleId,
    required String tanggal,
    required int pertemuanKe,
    required String startAt,
    required String endAt,
    required double latKelas,
    required double longKelas,
    required double radiusKelas,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiClient.post('/lecturer/sessions', {
        'kelas_id': kelasId,
        'schedule_id': scheduleId,
        'tanggal': tanggal,
        'pertemuan_ke': pertemuanKe,
        'start_at': startAt,
        'end_at': endAt,
        'lat_kelas': latKelas,
        'long_kelas': longKelas,
        'radius_kelas': radiusKelas,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchDosenSchedules();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorMsg = jsonDecode(response.body)['message'] ?? 'Gagal membuat sesi absensi.';
        _errorMessage = errorMsg;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Koneksi bermasalah: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> closeSession(int sesiId) async {
    try {
      final response = await apiClient.patch('/lecturer/sessions/$sesiId/close', {});
      if (response.statusCode == 200) {
        await fetchDosenSchedules();
        return true;
      }
    } catch (_) {}
    return false;
  }

  // --- CRUD: USER / MAHASISWA & DOSEN ---

  Future<void> fetchUsers(String role) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.get('/admin/users?role=$role');
      if (response.statusCode == 200) {
        _users = jsonDecode(response.body);
      } else {
        _errorMessage = 'Gagal mengambil data user.';
      }
    } catch (e) {
      _errorMessage = 'Koneksi bermasalah: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createUser({
    required String nama,
    required String username,
    required String email,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiClient.post('/admin/users', {
        'nama': nama,
        'username': username,
        'email': email,
        'password': password,
        'role': role,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchUsers(role);
        return true;
      } else {
        _errorMessage = jsonDecode(response.body)['message'] ?? 'Gagal membuat user.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Koneksi bermasalah: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateUser({
    required int id,
    required String nama,
    required String username,
    required String email,
    String? password,
    required String role,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final body = {
        'nama': nama,
        'username': username,
        'email': email,
        'role': role,
        if (password != null && password.isNotEmpty) 'password': password,
      };

      final response = await apiClient.put('/admin/users/$id', body);

      if (response.statusCode == 200) {
        await fetchUsers(role);
        return true;
      } else {
        _errorMessage = jsonDecode(response.body)['message'] ?? 'Gagal memperbarui user.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Koneksi bermasalah: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteUser(int id, String currentRoleFilter) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiClient.delete('/admin/users/$id');
      if (response.statusCode == 200) {
        await fetchUsers(currentRoleFilter);
        return true;
      } else {
        _errorMessage = jsonDecode(response.body)['message'] ?? 'Gagal menghapus user.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Koneksi bermasalah: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- CRUD: MATA KULIAH ---

  Future<void> fetchMataKuliahs() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.get('/admin/mata-kuliah');
      if (response.statusCode == 200) {
        _mataKuliahs = jsonDecode(response.body);
      } else {
        _errorMessage = 'Gagal memuat mata kuliah.';
      }
    } catch (e) {
      _errorMessage = 'Koneksi bermasalah: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createMataKuliah({
    required String kodeMk,
    required String namaMk,
    required int sks,
    required int prodiId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiClient.post('/admin/mata-kuliah', {
        'kode_mk': kodeMk,
        'nama_mk': namaMk,
        'sks': sks,
        'prodi_id': prodiId,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchMataKuliahs();
        return true;
      } else {
        _errorMessage = jsonDecode(response.body)['message'] ?? 'Gagal membuat mata kuliah.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Koneksi bermasalah: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateMataKuliah({
    required int id,
    required String kodeMk,
    required String namaMk,
    required int sks,
    required int prodiId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiClient.put('/admin/mata-kuliah/$id', {
        'kode_mk': kodeMk,
        'nama_mk': namaMk,
        'sks': sks,
        'prodi_id': prodiId,
      });

      if (response.statusCode == 200) {
        await fetchMataKuliahs();
        return true;
      } else {
        _errorMessage = jsonDecode(response.body)['message'] ?? 'Gagal memperbarui mata kuliah.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Koneksi bermasalah: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteMataKuliah(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiClient.delete('/admin/mata-kuliah/$id');
      if (response.statusCode == 200) {
        await fetchMataKuliahs();
        return true;
      } else {
        _errorMessage = jsonDecode(response.body)['message'] ?? 'Gagal menghapus mata kuliah.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Koneksi bermasalah: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- CRUD: KELAS ---

  Future<void> fetchKelasList() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.get('/admin/kelas');
      if (response.statusCode == 200) {
        _kelas = jsonDecode(response.body);
      } else {
        _errorMessage = 'Gagal memuat daftar kelas.';
      }
    } catch (e) {
      _errorMessage = 'Koneksi bermasalah: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createKelas({
    required int mkId,
    required int dosenUserId,
    required String kodeKelas,
    required String namaKelas,
    required int hari,
    required String jamMulai,
    required String jamSelesai,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiClient.post('/admin/kelas', {
        'mk_id': mkId,
        'dosen_id': dosenUserId,
        'kode_kelas': kodeKelas,
        'nama_kelas': namaKelas,
        'hari': hari,
        'jam_mulai': jamMulai,
        'jam_selesai': jamSelesai,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        await fetchKelasList();
        await fetchAdminSchedules();
        return true;
      } else {
        _errorMessage = jsonDecode(response.body)['message'] ?? 'Gagal membuat kelas.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Koneksi bermasalah: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateKelas({
    required int id,
    required int mkId,
    required int dosenUserId,
    required String kodeKelas,
    required String namaKelas,
    required int hari,
    required String jamMulai,
    required String jamSelesai,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiClient.put('/admin/kelas/$id', {
        'mk_id': mkId,
        'dosen_id': dosenUserId,
        'kode_kelas': kodeKelas,
        'nama_kelas': namaKelas,
        'hari': hari,
        'jam_mulai': jamMulai,
        'jam_selesai': jamSelesai,
      });

      if (response.statusCode == 200) {
        await fetchKelasList();
        await fetchAdminSchedules();
        return true;
      } else {
        _errorMessage = jsonDecode(response.body)['message'] ?? 'Gagal memperbarui kelas.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Koneksi bermasalah: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteKelas(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiClient.delete('/admin/kelas/$id');
      if (response.statusCode == 200) {
        await fetchKelasList();
        await fetchAdminSchedules();
        return true;
      } else {
        _errorMessage = jsonDecode(response.body)['message'] ?? 'Gagal menghapus kelas.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Koneksi bermasalah: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- PROGRAM STUDI (LOOKUP) ---

  Future<void> fetchProgramStudis() async {
    try {
      final response = await apiClient.get('/admin/program-studi');
      if (response.statusCode == 200) {
        _prodis = jsonDecode(response.body);
      }
    } catch (_) {}
    notifyListeners();
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient apiClient;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  AuthProvider(this.apiClient) {
    _loadUserFromPrefs();
  }

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user_data');
    if (userStr != null) {
      try {
        _currentUser = UserModel.fromJson(jsonDecode(userStr));
        notifyListeners();
      } catch (e) {
        // Clear corrupt data
        prefs.remove('user_data');
        prefs.remove('token');
      }
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await apiClient.post('/login', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        final userMap = data['user'];

        final user = UserModel.fromJson(userMap);

        // Check if user is allowed on the Dosen & Admin platform
        if (user.role != UserRole.admin && user.role != UserRole.dosen) {
          _errorMessage = 'Akses ditolak. Platform ini hanya untuk Dosen & Admin.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('user_data', jsonEncode(user.toJson()));

        _currentUser = user;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        _errorMessage = errorData['message'] ?? 'Login gagal. Silakan periksa kembali email & password Anda.';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Tidak dapat terhubung ke server. Pastikan backend aktif.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await apiClient.post('/logout', {});
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user_data');

    _currentUser = null;
    notifyListeners();
  }
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const AbsensiApp());
}

class AbsensiApp extends StatelessWidget {
  const AbsensiApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: Colors.indigo);
    return MaterialApp(
      title: 'Absensi Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        appBarTheme: const AppBarTheme(centerTitle: false),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: scheme.primary, width: 1.5),
          ),
        ),
      ),
      home: const SplashPage(),
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final auth = await AuthStore.load();
    if (!mounted) return;
    if (auth == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
      return;
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomePage(initialAuth: auth)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.verified_user_rounded, size: 42),
            SizedBox(height: 14),
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text('Menyiapkan aplikasi...'),
          ],
        ),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController(text: 'mahasiswa@kampus.test');
  final _password = TextEditingController(text: 'password123');
  final _baseUrl = TextEditingController(text: _defaultBaseUrl());
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _baseUrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = await ApiClient.login(
        baseUrl: _baseUrl.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      );
      await AuthStore.save(auth);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage(initialAuth: auth)),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              margin: const EdgeInsets.all(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Absensi Mobile', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 4),
                    Text('Masuk menggunakan akun backend Laravel', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 18),
                    TextField(
                      controller: _baseUrl,
                      decoration: const InputDecoration(
                        labelText: 'Base URL Laravel',
                        prefixIcon: Icon(Icons.link_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _email,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _password,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 16),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : _submit,
                        icon: _loading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.login_rounded),
                        label: const Text('Masuk'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _defaultBaseUrl() {
  if (kIsWeb) return 'http://127.0.0.1:8000';
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'http://10.0.2.2:8000';
    default:
      return 'http://127.0.0.1:8000';
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.initialAuth});
  final AuthState initialAuth;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late AuthState auth;
  @override
  void initState() {
    super.initState();
    auth = widget.initialAuth;
  }

  Future<void> _logout() async {
    await ApiClient.logout(auth);
    await AuthStore.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = auth.user['role']?.toString() ?? '-';
    return Scaffold(
      appBar: AppBar(
        title: Text('${auth.user['nama'] ?? auth.user['email']}'),
        actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout))],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Role aktif:'),
                Chip(label: Text(role.toUpperCase())),
              ],
            ),
          ),
          Expanded(
            child: role == 'mahasiswa'
                ? StudentPage(auth: auth)
                : EndpointListPage(
                    auth: auth,
                    title: role == 'dosen' ? 'Dosen' : 'Admin',
                    endpoints: role == 'dosen'
                        ? const ['/api/lecturer/schedules']
                        : const ['/api/admin/attendance-sessions', '/api/admin/attendance-records'],
                  ),
          ),
        ],
      ),
    );
  }
}

class StudentPage extends StatefulWidget {
  const StudentPage({super.key, required this.auth});
  final AuthState auth;

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  List<dynamic> classes = const [];
  List<dynamic> histories = const [];
  bool loading = false;
  String? message;

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  Future<void> refreshData() async {
    setState(() => loading = true);
    try {
      classes = await ApiClient.getList(widget.auth, '/api/student/classes');
      histories = await ApiClient.getList(widget.auth, '/api/student/histories');
      message = null;
    } catch (e) {
      message = e.toString();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _openQrScanner() async {
    final token = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerPage()),
    );
    if (token == null || token.isEmpty) return;

    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      setState(() => message = 'Izin lokasi dibutuhkan untuk check-in');
      return;
    }

    final position = await Geolocator.getCurrentPosition();
    try {
      final result = await ApiClient.post(
        widget.auth,
        '/api/student/checkin',
        {
          'qr_token': token,
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
        },
      );
      setState(() => message = result['message']?.toString() ?? 'Presensi berhasil');
      await refreshData();
    } catch (e) {
      setState(() => message = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: refreshData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Check-in Kehadiran', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  const Text('Scan QR dari dosen, lalu sistem akan validasi lokasi Anda.'),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: _openQrScanner,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan QR untuk Check-in'),
                  ),
                ],
              ),
            ),
          ),
          if (message != null) Text(message!, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Text('Kelas Saya', style: Theme.of(context).textTheme.titleLarge),
          if (loading) const LinearProgressIndicator(),
          if (!loading && classes.isEmpty) const _EmptyState(label: 'Belum ada data kelas.'),
          ...classes.map(
            (item) => Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.class_rounded, size: 18)),
                title: Text(item['nama_kelas']?.toString() ?? '-'),
                subtitle: Text(item['mata_kuliah']?['nama_mk']?.toString() ?? ''),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Riwayat Absensi', style: Theme.of(context).textTheme.titleLarge),
          if (!loading && histories.isEmpty) const _EmptyState(label: 'Belum ada riwayat absensi.'),
          ...histories.map(
            (item) => Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.checklist_rounded, size: 18)),
                title: Text(item['status_absensi']?.toString() ?? '-'),
                subtitle: Text(item['waktu_scan']?.toString() ?? '-'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EndpointListPage extends StatefulWidget {
  const EndpointListPage({
    super.key,
    required this.auth,
    required this.title,
    required this.endpoints,
  });
  final AuthState auth;
  final String title;
  final List<String> endpoints;

  @override
  State<EndpointListPage> createState() => _EndpointListPageState();
}

class _EndpointListPageState extends State<EndpointListPage> {
  String data = 'Memuat...';
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final buffer = StringBuffer();
    for (final endpoint in widget.endpoints) {
      try {
        final result = await ApiClient.get(widget.auth, endpoint);
        buffer.writeln('$endpoint\n${const JsonEncoder.withIndent('  ').convert(result)}\n');
      } catch (e) {
        buffer.writeln('$endpoint\nError: $e\n');
      }
    }
    if (mounted) setState(() => data = buffer.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: SingleChildScrollView(
            child: SelectableText('${widget.title} panel\n\n$data'),
          ),
        ),
      ),
    );
  }
}

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  bool handled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Token')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (handled) return;
              final code = capture.barcodes.firstOrNull?.rawValue;
              if (code == null || code.isEmpty) return;
              handled = true;
              Navigator.pop(context, code);
            },
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text('Arahkan kamera ke QR token absensi'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded),
            const SizedBox(width: 10),
            Expanded(child: Text(label)),
          ],
        ),
      ),
    );
  }
}

class AuthState {
  const AuthState({required this.baseUrl, required this.token, required this.user});
  final String baseUrl;
  final String token;
  final Map<String, dynamic> user;
}

class AuthStore {
  static const _baseUrlKey = 'base_url';
  static const _tokenKey = 'token';
  static const _userKey = 'user';

  static Future<void> save(AuthState auth) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, auth.baseUrl);
    await prefs.setString(_tokenKey, auth.token);
    await prefs.setString(_userKey, jsonEncode(auth.user));
  }

  static Future<AuthState?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString(_baseUrlKey);
    final token = prefs.getString(_tokenKey);
    final user = prefs.getString(_userKey);
    if (baseUrl == null || token == null || user == null) return null;
    return AuthState(baseUrl: baseUrl, token: token, user: jsonDecode(user) as Map<String, dynamic>);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_baseUrlKey);
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}

class ApiClient {
  static Future<AuthState> login({
    required String baseUrl,
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/api/login');
    late http.Response response;
    try {
      response = await http
          .post(uri, headers: {'Accept': 'application/json'}, body: {
            'email': email,
            'password': password,
          })
          .timeout(const Duration(seconds: 12));
    } catch (e) {
      throw Exception(_networkHelpMessage(baseUrl, e));
    }
    final data = _decode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(data['message'] ?? 'Login gagal');
    }
    return AuthState(
      baseUrl: baseUrl,
      token: data['access_token']?.toString() ?? '',
      user: (data['user'] as Map).cast<String, dynamic>(),
    );
  }

  static Future<void> logout(AuthState auth) async {
    await post(auth, '/api/logout', {});
  }

  static Future<Map<String, dynamic>> get(AuthState auth, String path) async {
    final uri = Uri.parse('${auth.baseUrl}$path');
    final response = await http.get(uri, headers: _headers(auth.token));
    final decoded = _decode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(decoded['message'] ?? 'Request gagal');
    }
    if (decoded is Map<String, dynamic>) return decoded;
    return {'data': decoded};
  }

  static Future<List<dynamic>> getList(AuthState auth, String path) async {
    final uri = Uri.parse('${auth.baseUrl}$path');
    final response = await http.get(uri, headers: _headers(auth.token));
    final decoded = _decode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(decoded['message'] ?? 'Request gagal');
    }
    if (decoded is List) return decoded;
    if (decoded is Map && decoded['data'] is List) return decoded['data'] as List;
    return [];
  }

  static Future<Map<String, dynamic>> post(AuthState auth, String path, Map<String, dynamic> body) async {
    final uri = Uri.parse('${auth.baseUrl}$path');
    final response = await http.post(
      uri,
      headers: _headers(auth.token),
      body: jsonEncode(body),
    );
    final decoded = _decode(response.body);
    if (response.statusCode >= 400) {
      throw Exception(decoded['message'] ?? 'Request gagal');
    }
    if (decoded is Map<String, dynamic>) return decoded;
    return {'data': decoded};
  }

  static Map<String, String> _headers(String token) => {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  static dynamic _decode(String body) {
    if (body.isEmpty) return {};
    return jsonDecode(body);
  }

  static String _networkHelpMessage(String baseUrl, Object error) {
    final isAndroidEmulatorUrl = baseUrl.contains('10.0.2.2');
    if (kIsWeb && isAndroidEmulatorUrl) {
      return 'Koneksi gagal. Anda sedang pakai Flutter Web, gunakan Base URL http://127.0.0.1:8000 (bukan 10.0.2.2).';
    }
    return 'Koneksi ke backend gagal ($baseUrl). Pastikan Laravel aktif (php artisan serve) dan URL benar. Detail: $error';
  }
}

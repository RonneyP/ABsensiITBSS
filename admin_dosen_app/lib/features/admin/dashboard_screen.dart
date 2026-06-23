import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../auth/auth_provider.dart';
import 'dashboard_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final user = context.read<AuthProvider>().currentUser;
    final provider = context.read<DashboardProvider>();
    if (user != null) {
      if (user.role == UserRole.dosen) {
        provider.fetchDosenSchedules();
        provider.fetchAdminSessions(); // Dosen can see sessions they belong to
      } else if (user.role == UserRole.admin) {
        provider.fetchAdminSessions();
        provider.fetchAdminAttendanceRecords();
        provider.fetchMataKuliahs();
        provider.fetchKelasList();
        provider.fetchUsers('mahasiswa');
        provider.fetchUsers('dosen'); // For assigning lecturers to class
        provider.fetchProgramStudis();
        provider.fetchAdminSchedules();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final dashProvider = context.watch<DashboardProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userName = user.nama;
    final userRoleName = user.role == UserRole.admin ? 'Administrator' : 'Dosen Pengajar';
    final isAdmin = user.role == UserRole.admin;

    // Build sidebar destinations dynamically
    final destinations = isAdmin
        ? const [
            NavigationRailDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: Text('Dashboard'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.history_toggle_off),
              selectedIcon: Icon(Icons.history),
              label: Text('Sesi Absensi'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.book_outlined),
              selectedIcon: Icon(Icons.book),
              label: Text('Mata Kuliah'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.meeting_room_outlined),
              selectedIcon: Icon(Icons.meeting_room),
              label: Text('Kelas Kuliah'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: Text('Mahasiswa'),
            ),
          ]
        : const [
            NavigationRailDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: Text('Dashboard'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.qr_code_scanner),
              selectedIcon: Icon(Icons.qr_code),
              label: Text('Kelola Absensi'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.class_outlined),
              selectedIcon: Icon(Icons.class_),
              label: Text('Daftar Kelas'),
            ),
          ];

    return Scaffold(
      body: Row(
        children: [
          // Sidebar / Navigation Rail
          NavigationRail(
            selectedIndex: _selectedIndex >= destinations.length ? 0 : _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
              _loadData();
            },
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.white,
            selectedIconTheme: const IconThemeData(color: AppTheme.primaryColor),
            unselectedIconTheme: const IconThemeData(color: AppTheme.textSecondary),
            selectedLabelTextStyle: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelTextStyle: const TextStyle(color: AppTheme.textSecondary),
            destinations: destinations,
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.redAccent),
                    onPressed: () async {
                      await authProvider.logout();
                      if (mounted) {
                        Navigator.pushReplacementNamed(context, '/login');
                      }
                    },
                    tooltip: 'Logout',
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1, color: Color(0xFFE2E8F0)),

          // Main Screen
          Expanded(
            child: Container(
              color: const Color(0xFFF8FAFC),
              child: Column(
                children: [
                  // Top Navbar Header
                  Container(
                    height: 80,
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getAppBarTitle(isAdmin),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: _loadData,
                              tooltip: 'Refresh Data',
                            ),
                            const SizedBox(width: 16),
                            CircleAvatar(
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                              child: const Icon(Icons.person, color: AppTheme.primaryColor),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  userRoleName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Main Content View
                  Expanded(
                    child: dashProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: _buildContentView(user, dashProvider),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getAppBarTitle(bool isAdmin) {
    if (isAdmin) {
      switch (_selectedIndex) {
        case 0:
          return 'Ringkasan Akademik';
        case 1:
          return 'Daftar Sesi Absensi';
        case 2:
          return 'Master Data Mata Kuliah';
        case 3:
          return 'Master Data Kelas';
        case 4:
          return 'Master Data Mahasiswa';
        default:
          return 'Portal Akademik';
      }
    } else {
      switch (_selectedIndex) {
        case 0:
          return 'Portal Ringkasan Akademik';
        case 1:
          return 'Kelola Absensi QR';
        case 2:
          return 'Daftar Kelas Diajar';
        default:
          return 'Portal Akademik';
      }
    }
  }

  Widget _buildContentView(UserModel user, DashboardProvider provider) {
    final isAdmin = user.role == UserRole.admin;
    if (isAdmin) {
      switch (_selectedIndex) {
        case 0:
          return _buildOverviewTab(user, provider);
        case 1:
          return _buildSesiAbsensiTab(user, provider);
        case 2:
          return _buildMataKuliahCrudTab(provider);
        case 3:
          return _buildKelasCrudTab(provider);
        case 4:
          return _buildMahasiswaCrudTab(provider);
        default:
          return const Center(child: Text('Menu tidak ditemukan'));
      }
    } else {
      switch (_selectedIndex) {
        case 0:
          return _buildOverviewTab(user, provider);
        case 1:
          return _buildSesiAbsensiTab(user, provider);
        case 2:
          return _buildMahasiswaTab(user, provider);
        default:
          return const Center(child: Text('Menu tidak ditemukan'));
      }
    }
  }

  // --- TAB 1: OVERVIEW ---
  Widget _buildOverviewTab(UserModel user, DashboardProvider provider) {
    final bool isAdmin = user.role == UserRole.admin;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selamat datang kembali, ${user.nama}!',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isAdmin
                      ? 'Pantau aktivitas presensi, kelas perkuliahan, dan laporan kehadiran mahasiswa secara real-time.'
                      : 'Kelola kelas Anda, buat sesi absensi berbasis QR Code dinamis dan pantau tingkat kehadiran mahasiswa.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Statistics Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: isAdmin ? 'Total Sesi Aktif' : 'Kelas Diajar',
                  value: isAdmin ? '${provider.sessions.length}' : '${provider.schedules.length}',
                  icon: Icons.class_outlined,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildStatCard(
                  title: 'Presensi Hari Ini',
                  value: isAdmin ? '${provider.attendanceRecords.length}' : 'Aktif',
                  icon: Icons.how_to_reg_outlined,
                  color: const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildStatCard(
                  title: 'Platform Target',
                  value: 'Web Dosen',
                  icon: Icons.computer,
                  color: Colors.orangeAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Main Info List (Schedule / Active Sessions)
          Text(
            isAdmin ? 'Aktivitas Absensi Terbaru' : 'Jadwal Mengajar & Sesi Anda',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoPanel(user, provider),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInfoPanel(UserModel user, DashboardProvider provider) {
    if (user.role == UserRole.dosen) {
      if (provider.schedules.isEmpty) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                'Belum ada jadwal mengajar yang terdaftar.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          ),
        );
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: provider.schedules.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final item = provider.schedules[index];
          final kelas = item['kelas'] ?? {};
          final matakuliah = kelas['mata_kuliah'] ?? {};

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      matakuliah['nama_mk'] ?? 'Mata Kuliah',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.class_, size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          'Kelas: ${kelas['nama_kelas'] ?? '-'} (${kelas['kode_kelas'] ?? '-'})',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.access_time, size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          'Hari: ${_getHariName(kelas['hari'])} | ${item['start_time']} - ${item['end_time']}',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                  icon: const Icon(Icons.qr_code, size: 18),
                  label: const Text('Kelola Absensi'),
                ),
              ],
            ),
          );
        },
      );
    } else {
      // Admin Panel Overview
      if (provider.sessions.isEmpty) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: Text(
                'Belum ada aktivitas absensi saat ini.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          ),
        );
      }

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Mata Kuliah')),
            DataColumn(label: Text('Tanggal')),
            DataColumn(label: Text('Pertemuan')),
            DataColumn(label: Text('Status')),
          ],
          rows: provider.sessions.map<DataRow>((sess) {
            final kelas = sess['kelas'] ?? {};
            final mk = kelas['mata_kuliah'] ?? {};
            return DataRow(cells: [
              DataCell(Text(mk['nama_mk'] ?? '-')),
              DataCell(Text(sess['session_date'] ?? '-')),
              DataCell(Text('Ke-${sess['pertemuan_ke']}')),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: sess['status'] == 'open'
                        ? const Color(0xFF10B981).withOpacity(0.1)
                        : Colors.redAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    sess['status']?.toString().toUpperCase() ?? 'CLOSED',
                    style: TextStyle(
                      color: sess['status'] == 'open' ? const Color(0xFF10B981) : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ]);
          }).toList(),
        ),
      );
    }
  }

  // --- TAB 2: SESI ABSENSI & QR CODE ---
  Widget _buildSesiAbsensiTab(UserModel user, DashboardProvider provider) {
    if (user.role == UserRole.admin) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daftar Semua Sesi Absensi (Admin)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Kelas')),
                    DataColumn(label: Text('Pertemuan')),
                    DataColumn(label: Text('Waktu Mulai')),
                    DataColumn(label: Text('Waktu Selesai')),
                    DataColumn(label: Text('Status')),
                  ],
                  rows: provider.sessions.map<DataRow>((sess) {
                    final kelas = sess['kelas'] ?? {};
                    return DataRow(cells: [
                      DataCell(Text(kelas['nama_kelas'] ?? '-')),
                      DataCell(Text('Pertemuan ${sess['pertemuan_ke']}')),
                      DataCell(Text(sess['start_at'] ?? '-')),
                      DataCell(Text(sess['end_at'] ?? '-')),
                      DataCell(
                        Text(
                          sess['status']?.toString().toUpperCase() ?? 'CLOSED',
                          style: TextStyle(
                            color: sess['status'] == 'open' ? const Color(0xFF10B981) : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ]);
                  }).toList(),
                ),
              ),
            ),
          )
        ],
      );
    }

    // Dosen flow
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Jadwal Kuliah & Pembuatan Sesi QR',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.sync),
              label: const Text('Sync Schedules'),
            )
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.separated(
            itemCount: provider.schedules.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final sched = provider.schedules[index];
              final kelas = sched['kelas'] ?? {};
              final mk = kelas['mata_kuliah'] ?? {};

              // Check if there is an active session
              final activeSession = provider.sessions.firstWhere(
                (s) => s['kelas_id'] == kelas['id'] && s['status'] == 'open',
                orElse: () => null,
              );

              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mk['nama_mk'] ?? 'Mata Kuliah',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('Kelas: ${kelas['nama_kelas'] ?? '-'}'),
                          Text('Waktu: ${_getHariName(kelas['hari'])} | ${sched['start_time']} - ${sched['end_time']}'),
                        ],
                      ),
                    ),
                    if (activeSession != null) ...[
                      Column(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () => _showQrDialog(activeSession),
                            icon: const Icon(Icons.qr_code),
                            label: const Text('Tampilkan QR'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                            ),
                            onPressed: () async {
                              final success = await provider.closeSession(activeSession['id']);
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Sesi Absensi berhasil ditutup')),
                                );
                                _loadData();
                              }
                            },
                            child: const Text('Tutup Sesi'),
                          ),
                        ],
                      ),
                    ] else ...[
                      ElevatedButton.icon(
                        onPressed: () => _showCreateSessionDialog(sched, kelas),
                        icon: const Icon(Icons.add),
                        label: const Text('Buat Sesi Absensi'),
                      )
                    ],
                  ],
                ),
              );
            },
          ),
        )
      ],
    );
  }

  // --- TAB 3: Dosen - Mahasiswa ---
  Widget _buildMahasiswaTab(UserModel user, DashboardProvider provider) {
    // Dosen Flow - Show Class List
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daftar Kelas Diajar & Data Mahasiswa',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
            ),
            itemCount: provider.schedules.length,
            itemBuilder: (context, index) {
              final sched = provider.schedules[index];
              final kelas = sched['kelas'] ?? {};
              final mk = kelas['mata_kuliah'] ?? {};

              return Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mk['nama_mk'] ?? 'Mata Kuliah',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text('Kelas: ${kelas['nama_kelas'] ?? '-'}'),
                      const SizedBox(height: 8),
                      Text(
                        'Hari: ${_getHariName(kelas['hari'])}',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- CRUD TABS FOR ADMIN ---

  // --- MATA KULIAH CRUD ---
  Widget _buildMataKuliahCrudTab(DashboardProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Kelola Data Mata Kuliah',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: () => _showMataKuliahFormDialog(null),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Mata Kuliah'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Kode MK')),
                  DataColumn(label: Text('Nama Mata Kuliah')),
                  DataColumn(label: Text('SKS')),
                  DataColumn(label: Text('Program Studi')),
                  DataColumn(label: Text('Aksi')),
                ],
                rows: provider.mataKuliahs.map<DataRow>((mk) {
                  return DataRow(cells: [
                    DataCell(Text(mk['kode_mk'] ?? '-')),
                    DataCell(Text(mk['nama_mk'] ?? '-')),
                    DataCell(Text('${mk['sks']}')),
                    DataCell(Text(mk['program_studi']?['nama_prodi'] ?? '-')),
                    DataCell(Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showMataKuliahFormDialog(mk),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeleteMataKuliah(mk['id']),
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
        )
      ],
    );
  }

  // --- KELAS CRUD ---
  Widget _buildKelasCrudTab(DashboardProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Kelola Data Kelas & Jadwal',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showTimetableDialog(),
                  icon: const Icon(Icons.calendar_month, color: AppTheme.primaryColor),
                  label: const Text('Lihat Timetable Dosen'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showKelasFormDialog(null),
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Kelas'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Kode Kelas')),
                  DataColumn(label: Text('Nama Kelas')),
                  DataColumn(label: Text('Mata Kuliah')),
                  DataColumn(label: Text('Dosen Pengajar')),
                  DataColumn(label: Text('Jadwal')),
                  DataColumn(label: Text('Aksi')),
                ],
                rows: provider.kelasList.map<DataRow>((k) {
                  return DataRow(cells: [
                    DataCell(Text(k['kode_kelas'] ?? '-')),
                    DataCell(Text(k['nama_kelas'] ?? '-')),
                    DataCell(Text(k['mata_kuliah']?['nama_mk'] ?? '-')),
                    DataCell(Text(k['dosen']?['user']?['nama'] ?? '-')),
                    DataCell(Text('${_getHariName(k['hari'])} (${k['jam_mulai']} - ${k['jam_selesai']})')),
                    DataCell(Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showKelasFormDialog(k),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeleteKelas(k['id']),
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
        )
      ],
    );
  }

  // --- MAHASISWA CRUD ---
  Widget _buildMahasiswaCrudTab(DashboardProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Kelola Data Mahasiswa',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: () => _showUserFormDialog(null, 'mahasiswa'),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Mahasiswa'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Nama')),
                  DataColumn(label: Text('Username')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Role')),
                  DataColumn(label: Text('Aksi')),
                ],
                rows: provider.users.map<DataRow>((u) {
                  return DataRow(cells: [
                    DataCell(Text(u['nama'] ?? '-')),
                    DataCell(Text(u['username'] ?? '-')),
                    DataCell(Text(u['email'] ?? '-')),
                    DataCell(Text(u['role']?.toString().toUpperCase() ?? '-')),
                    DataCell(Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showUserFormDialog(u, 'mahasiswa'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeleteUser(u['id'], 'mahasiswa'),
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
        )
      ],
    );
  }

  // --- DIALOGS FOR CRUD FORM INPUTS ---

  void _showMataKuliahFormDialog(Map<String, dynamic>? item) {
    final provider = context.read<DashboardProvider>();
    final isEdit = item != null;

    final kodeController = TextEditingController(text: item?['kode_mk'] ?? '');
    final namaController = TextEditingController(text: item?['nama_mk'] ?? '');
    final sksController = TextEditingController(text: item != null ? '${item['sks']}' : '3');
    int? selectedProdiId = item?['prodi_id'];

    if (selectedProdiId == null && provider.prodis.isNotEmpty) {
      selectedProdiId = provider.prodis.first['id'];
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEdit ? 'Ubah Mata Kuliah' : 'Tambah Mata Kuliah'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: kodeController,
                    decoration: const InputDecoration(labelText: 'Kode MK'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: namaController,
                    decoration: const InputDecoration(labelText: 'Nama Mata Kuliah'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: sksController,
                    decoration: const InputDecoration(labelText: 'SKS'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: selectedProdiId,
                    decoration: const InputDecoration(labelText: 'Program Studi'),
                    items: provider.prodis.map<DropdownMenuItem<int>>((p) {
                      return DropdownMenuItem<int>(
                        value: p['id'],
                        child: Text(p['nama_prodi'] ?? ''),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setStateDialog(() {
                        selectedProdiId = val;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    bool success;
                    if (isEdit) {
                      success = await provider.updateMataKuliah(
                        id: item['id'],
                        kodeMk: kodeController.text.trim(),
                        namaMk: namaController.text.trim(),
                        sks: int.tryParse(sksController.text) ?? 3,
                        prodiId: selectedProdiId ?? 1,
                      );
                    } else {
                      success = await provider.createMataKuliah(
                        kodeMk: kodeController.text.trim(),
                        namaMk: namaController.text.trim(),
                        sks: int.tryParse(sksController.text) ?? 3,
                        prodiId: selectedProdiId ?? 1,
                      );
                    }

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? 'Mata Kuliah berhasil disimpan'
                              : provider.errorMessage ?? 'Gagal menyimpan data'),
                        ),
                      );
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showKelasFormDialog(Map<String, dynamic>? item) {
    final provider = context.read<DashboardProvider>();
    final isEdit = item != null;

    final kodeController = TextEditingController(text: item?['kode_kelas'] ?? '');
    final namaController = TextEditingController(text: item?['nama_kelas'] ?? '');

    int? selectedMkId = item?['mk_id'];
    int? selectedDosenUserId = item?['dosen']?['user']?['id'];
    int selectedHari = item?['hari'] ?? 1;
    String selectedStart = _parseTimeOnly(item?['jam_mulai'] ?? '07:00');
    String selectedEnd = _parseTimeOnly(item?['jam_selesai'] ?? '08:40');

    // Load fallbacks
    if (selectedMkId == null && provider.mataKuliahs.isNotEmpty) {
      selectedMkId = provider.mataKuliahs.first['id'];
    }
    final dosenList = provider.users.where((u) => u['role'] == 'dosen').toList();
    if (dosenList.isEmpty) {
      provider.fetchUsers('dosen');
    }
    if (selectedDosenUserId == null && dosenList.isNotEmpty) {
      selectedDosenUserId = dosenList.first['id'];
    }

    final days = [
      {'label': 'Senin', 'val': 1},
      {'label': 'Selasa', 'val': 2},
      {'label': 'Rabu', 'val': 3},
      {'label': 'Kamis', 'val': 4},
      {'label': 'Jumat', 'val': 5},
      {'label': 'Sabtu', 'val': 6},
    ];

    final timeSlots = [
      {'label': 'Sesi 1 (07:00 - 08:40)', 'start': '07:00', 'end': '08:40'},
      {'label': 'Sesi 2 (09:00 - 10:40)', 'start': '09:00', 'end': '10:40'},
      {'label': 'Sesi 3 (11:00 - 12:40)', 'start': '11:00', 'end': '12:40'},
      {'label': 'Sesi 4 (17:00 - 18:40)', 'start': '17:00', 'end': '18:40'},
      {'label': 'Sesi 5 (19:00 - 20:40)', 'start': '19:00', 'end': '20:40'},
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final activeDosenList = provider.users.where((u) => u['role'] == 'dosen').toList();

            bool isDosenBusy(int dayNum, String start, String end) {
              for (var s in provider.adminSchedules) {
                final dosenUser = s['dosen']?['user'];
                if (dosenUser != null && dosenUser['id'] == selectedDosenUserId) {
                  int sHari = 1;
                  if (s['hari'] is int) {
                    sHari = s['hari'];
                  } else if (s['hari'] is String) {
                    sHari = int.tryParse(s['hari']) ?? 1;
                  }

                  if (sHari == dayNum) {
                    final sStart = _parseTimeOnly(s['jam_mulai']);
                    final sEnd = _parseTimeOnly(s['jam_selesai']);

                    if (start.compareTo(sEnd) < 0 && end.compareTo(sStart) > 0) {
                      if (isEdit && s['kelas_id'] == item['id']) {
                        continue;
                      }
                      return true;
                    }
                  }
                }
              }
              return false;
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Text(isEdit ? 'Ubah Kelas' : 'Tambah Kelas', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 550,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<int>(
                        value: selectedMkId,
                        decoration: const InputDecoration(labelText: 'Mata Kuliah'),
                        items: provider.mataKuliahs.map<DropdownMenuItem<int>>((mk) {
                          return DropdownMenuItem<int>(
                            value: mk['id'],
                            child: Text(mk['nama_mk'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setStateDialog(() {
                            selectedMkId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: selectedDosenUserId,
                        decoration: const InputDecoration(labelText: 'Dosen Pengajar'),
                        items: activeDosenList.map<DropdownMenuItem<int>>((d) {
                          return DropdownMenuItem<int>(
                            value: d['id'],
                            child: Text(d['nama'] ?? ''),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setStateDialog(() {
                            selectedDosenUserId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: kodeController,
                        decoration: const InputDecoration(labelText: 'Kode Kelas'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: namaController,
                        decoration: const InputDecoration(labelText: 'Nama Kelas'),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Pilih Hari & Sesi Kuliah (Timetable)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      // Day Selector
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: days.map((d) {
                            final isSelected = selectedHari == d['val'];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(d['label'] as String),
                                selected: isSelected,
                                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                                labelStyle: TextStyle(
                                  color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setStateDialog(() {
                                      selectedHari = d['val'] as int;
                                    });
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Slots List
                      Column(
                        children: timeSlots.map((slot) {
                          final start = slot['start']!;
                          final end = slot['end']!;
                          final isSelected = selectedStart == start && selectedEnd == end;
                          final isBusy = isDosenBusy(selectedHari, start, end);

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              dense: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : (isBusy ? Colors.red.withOpacity(0.3) : const Color(0xFFE2E8F0)),
                                ),
                              ),
                              tileColor: isSelected
                                  ? AppTheme.primaryColor.withOpacity(0.05)
                                  : (isBusy ? Colors.red.withOpacity(0.02) : Colors.white),
                              leading: Radio<String>(
                                value: start,
                                groupValue: isSelected ? start : null,
                                activeColor: AppTheme.primaryColor,
                                onChanged: isBusy
                                    ? null
                                    : (val) {
                                        setStateDialog(() {
                                          selectedStart = start;
                                          selectedEnd = end;
                                        });
                                      },
                              ),
                              title: Text(
                                slot['label']!,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isBusy ? AppTheme.textSecondary : AppTheme.textPrimary,
                                ),
                              ),
                              trailing: isBusy
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Bentrok',
                                        style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    )
                                  : const Icon(Icons.check_circle_outline, color: Color(0xFF10B981), size: 16),
                              onTap: isBusy
                                  ? null
                                  : () {
                                      setStateDialog(() {
                                        selectedStart = start;
                                        selectedEnd = end;
                                      });
                                    },
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedMkId == null || selectedDosenUserId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mata Kuliah dan Dosen harus diisi.')),
                      );
                      return;
                    }

                    bool success;
                    if (isEdit) {
                      success = await provider.updateKelas(
                        id: item['id'],
                        mkId: selectedMkId!,
                        dosenUserId: selectedDosenUserId!,
                        kodeKelas: kodeController.text.trim(),
                        namaKelas: namaController.text.trim(),
                        hari: selectedHari,
                        jamMulai: selectedStart,
                        jamSelesai: selectedEnd,
                      );
                    } else {
                      success = await provider.createKelas(
                        mkId: selectedMkId!,
                        dosenUserId: selectedDosenUserId!,
                        kodeKelas: kodeController.text.trim(),
                        namaKelas: namaController.text.trim(),
                        hari: selectedHari,
                        jamMulai: selectedStart,
                        jamSelesai: selectedEnd,
                      );
                    }

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? 'Kelas berhasil disimpan'
                              : provider.errorMessage ?? 'Gagal menyimpan data'),
                        ),
                      );
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showUserFormDialog(Map<String, dynamic>? item, String role) {
    final provider = context.read<DashboardProvider>();
    final isEdit = item != null;

    final namaController = TextEditingController(text: item?['nama'] ?? '');
    final usernameController = TextEditingController(text: item?['username'] ?? '');
    final emailController = TextEditingController(text: item?['email'] ?? '');
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEdit ? 'Ubah Data Mahasiswa' : 'Tambah Mahasiswa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: isEdit ? 'Password Baru (Kosongkan jika tidak diubah)' : 'Password',
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                bool success;
                if (isEdit) {
                  success = await provider.updateUser(
                    id: item['id'],
                    nama: namaController.text.trim(),
                    username: usernameController.text.trim(),
                    email: emailController.text.trim(),
                    password: passwordController.text,
                    role: role,
                  );
                } else {
                  success = await provider.createUser(
                    nama: namaController.text.trim(),
                    username: usernameController.text.trim(),
                    email: emailController.text.trim(),
                    password: passwordController.text,
                    role: role,
                  );
                }

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Data Mahasiswa berhasil disimpan'
                          : provider.errorMessage ?? 'Gagal menyimpan data'),
                    ),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  // --- DELETE CONFIRMATION ---

  void _confirmDeleteMataKuliah(int id) {
    final provider = context.read<DashboardProvider>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Mata Kuliah?'),
        content: const Text('Apakah Anda yakin ingin menghapus data mata kuliah ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final success = await provider.deleteMataKuliah(id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Berhasil dihapus' : 'Gagal menghapus')),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteKelas(int id) {
    final provider = context.read<DashboardProvider>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kelas?'),
        content: const Text('Apakah Anda yakin ingin menghapus kelas kuliah beserta jadwalnya?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final success = await provider.deleteKelas(id);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Berhasil dihapus' : 'Gagal menghapus')),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(int id, String role) {
    final provider = context.read<DashboardProvider>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Mahasiswa?'),
        content: const Text('Apakah Anda yakin ingin menghapus data mahasiswa ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final success = await provider.deleteUser(id, role);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Berhasil dihapus' : 'Gagal menghapus')),
                );
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // --- UTILS ---

  void _showQrDialog(Map<String, dynamic> session) {
    final qrContent = session['qr_code'] ?? 'PORTAL_AKADEMIK_SESSION_${session['id']}';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Center(
            child: Text(
              'Scan QR Code Presensi\nPertemuan Ke-${session['pertemuan_ke']}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Minta mahasiswa memindai kode QR ini menggunakan aplikasi Portal Akademik Mahasiswa.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: QrImageView(
                  data: qrContent,
                  version: QrVersions.auto,
                  size: 250.0,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Kode QR: $qrContent',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  void _showCreateSessionDialog(Map<String, dynamic> sched, Map<String, dynamic> kelas) {
    final pertemuanController = TextEditingController(text: '1');
    final latController = TextEditingController(text: '-6.20000000');
    final longController = TextEditingController(text: '106.81666600');
    final radiusController = TextEditingController(text: '80');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Buat Sesi Absensi Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: pertemuanController,
                  decoration: const InputDecoration(labelText: 'Pertemuan Ke'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: latController,
                  decoration: const InputDecoration(labelText: 'Latitude Kelas'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: longController,
                  decoration: const InputDecoration(labelText: 'Longitude Kelas'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: radiusController,
                  decoration: const InputDecoration(labelText: 'Radius Validasi (Meter)'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final provider = context.read<DashboardProvider>();
                final success = await provider.createSession(
                  kelasId: kelas['id'],
                  scheduleId: sched['id'],
                  tanggal: DateTime.now().toIso8601String().substring(0, 10),
                  pertemuanKe: int.tryParse(pertemuanController.text) ?? 1,
                  startAt: DateTime.now().toIso8601String(),
                  endAt: DateTime.now().add(const Duration(minutes: 90)).toIso8601String(),
                  latKelas: double.tryParse(latController.text) ?? -6.2,
                  longKelas: double.tryParse(longController.text) ?? 106.816666,
                  radiusKelas: double.tryParse(radiusController.text) ?? 80,
                );

                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sesi Absensi berhasil dibuat!')),
                    );
                    _loadData();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(provider.errorMessage ?? 'Gagal membuat sesi')),
                    );
                  }
                }
              },
              child: const Text('Buat Sesi'),
            ),
          ],
        );
      },
    );
  }

  String _getHariName(dynamic hari) {
    int h = 1;
    if (hari is int) {
      h = hari;
    } else if (hari is String) {
      h = int.tryParse(hari) ?? 1;
    }
    switch (h) {
      case 1:
        return 'Senin';
      case 2:
        return 'Selasa';
      case 3:
        return 'Rabu';
      case 4:
        return 'Kamis';
      case 5:
        return 'Jumat';
      case 6:
        return 'Sabtu';
      case 7:
        return 'Minggu';
      default:
        return 'Senin';
    }
  }

  String _parseTimeOnly(dynamic timeStr) {
    if (timeStr == null) return '';
    final str = timeStr.toString().trim();
    if (str.isEmpty) return '';

    // If it's a full ISO or Datetime string containing 'T' or a space
    String timePart = str;
    if (str.contains('T')) {
      final parts = str.split('T');
      if (parts.length > 1) {
        timePart = parts[1];
      }
    } else if (str.contains(' ')) {
      final parts = str.split(' ');
      if (parts.length > 1) {
        timePart = parts[1];
      }
    }

    // Extract HH:MM
    if (timePart.contains(':')) {
      final parts = timePart.split(':');
      if (parts.length >= 2) {
        final hh = parts[0].padLeft(2, '0');
        final mm = parts[1].padLeft(2, '0');
        return '$hh:$mm';
      }
    }

    if (timePart.length >= 5) {
      return timePart.substring(0, 5);
    }

    return timePart;
  }

  void _showTimetableDialog() {
    final provider = context.read<DashboardProvider>();
    final dosenList = provider.users.where((u) => u['role'] == 'dosen').toList();
    int? selectedDosenId;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Filter schedules based on lecturer
            final filteredSchedules = provider.adminSchedules.where((sched) {
              if (selectedDosenId == null) return true;
              final dosenUser = sched['dosen']?['user'];
              return dosenUser != null && dosenUser['id'] == selectedDosenId;
            }).toList();

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Timetable Jadwal Mengajar Dosen', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                height: MediaQuery.of(context).size.height * 0.75,
                child: Column(
                  children: [
                    // Filtering Dropdown
                    Row(
                      children: [
                        const Text('Filter Dosen: ', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int?>(
                            value: selectedDosenId,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('Semua Dosen'),
                              ),
                              ...dosenList.map<DropdownMenuItem<int?>>((d) {
                                return DropdownMenuItem<int?>(
                                  value: d['id'],
                                  child: Text(d['nama'] ?? 'Dosen'),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              setStateDialog(() {
                                selectedDosenId = val;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Schedule Grid View
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6, // 6 days: Senin to Sabtu
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.65,
                        ),
                        itemCount: 6,
                        itemBuilder: (context, dayIndex) {
                          final dayNum = dayIndex + 1; // 1 = Senin, ..., 6 = Sabtu
                          final daySchedules = filteredSchedules.where((s) {
                            int sHari = 1;
                            if (s['hari'] is int) {
                              sHari = s['hari'];
                            } else if (s['hari'] is String) {
                              sHari = int.tryParse(s['hari']) ?? 1;
                            }
                            return sHari == dayNum;
                          }).toList();

                          // Sort schedules by time
                          daySchedules.sort((a, b) => _parseTimeOnly(a['jam_mulai']).compareTo(_parseTimeOnly(b['jam_mulai'])));

                          return Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Day Header
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      _getHariName(dayNum),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Class Card List
                                Expanded(
                                  child: daySchedules.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'Kosong',
                                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                          ),
                                        )
                                      : ListView.separated(
                                          itemCount: daySchedules.length,
                                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                                          itemBuilder: (context, sIndex) {
                                            final s = daySchedules[sIndex];
                                            final kelas = s['kelas'] ?? {};
                                            final mk = kelas['mata_kuliah'] ?? {};
                                            final dName = s['dosen']?['user']?['nama'] ?? 'Dosen';

                                            return Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.02),
                                                    blurRadius: 4,
                                                  )
                                                ]
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    mk['nama_mk'] ?? 'Mata Kuliah',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Kelas: ${kelas['nama_kelas'] ?? '-'}',
                                                    style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Dosen: $dName',
                                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.blueGrey),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    children: [
                                                      const Icon(Icons.access_time, size: 10, color: Colors.orangeAccent),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${_parseTimeOnly(s['jam_mulai'])} - ${_parseTimeOnly(s['jam_selesai'])}',
                                                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../survey/survey.dart';
import 'profile.dart';

const Color primaryColor = Color(0xFF1E4BAF);
const Color backgroundColor = Color(0xFFF8FAFC);
const Color textDark = Color(0xFF1E293B);
const Color textMuted = Color(0xFF64748B);
const Color borderColor = Color(0xFFE2E8F0);

// ================= MODEL =================
class DashboardStats {
  final int totalSurvey;
  final int totalKategori;

  const DashboardStats({
    required this.totalSurvey,
    required this.totalKategori,
  });
}

class SessionExpiredException implements Exception {
  const SessionExpiredException();

  @override
  String toString() => 'Sesi login berakhir. Silakan login kembali.';
}

// ================= SERVICE =================
class DashboardService {
  static const String baseUrl = 'https://sijala.biz.id/api/v1';

  // Mengambil list dari endpoint yang sama dengan halaman Daftar Survey
  static Future<List> _getList(String path, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 401) {
      throw const SessionExpiredException();
    }
    if (response.statusCode != 200) {
      throw Exception('Gagal memuat $path (${response.statusCode}).');
    }

    final decoded = jsonDecode(response.body);
    final data = decoded is Map ? decoded['data'] : decoded;
    return data is List ? data : [];
  }

  static Future<DashboardStats> fetchStats() async {
    final prefs = await SharedPreferences.getInstance();
    final token =
        prefs.getString('token') ?? prefs.getString('auth_token') ?? '';

    if (token.isEmpty) {
      throw const SessionExpiredException();
    }

    try {
      final results = await Future.wait([
        _getList('/surveys', token),
        _getList('/categories', token),
      ]);
      return DashboardStats(
        totalSurvey: results[0].length,
        totalKategori: results[1].length,
      );
    } on SessionExpiredException {
      await prefs.remove('token');
      await prefs.remove('auth_token');
      rethrow;
    }
  }
}

// ================= HALAMAN UTAMA =================
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;
  final _homeKey = GlobalKey<HomeTabState>();
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeTab(key: _homeKey),
      SurveyPage(),
      ProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    if (index == 0) _homeKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          elevation: 0,
          backgroundColor: Colors.white,
          selectedItemColor: primaryColor,
          unselectedItemColor: textMuted,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment_rounded),
              label: 'Assessment',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// ================= TAB HOME =================
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => HomeTabState();
}

class HomeTabState extends State<HomeTab> {
  late Future<DashboardStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = DashboardService.fetchStats();
  }

  Future<void> refresh() async {
    final future = DashboardService.fetchStats();
    setState(() => _statsFuture = future);
    try {
      await future;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: textDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Row(
          children: [
            Icon(
              Icons.location_on_rounded,
              color: primaryColor,
              size: 28,
            ),
            SizedBox(width: 8),
            Text(
              'Field Survey',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: textDark,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: refresh,
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selamat Datang!',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Siap melakukan pengisian survey hari ini?',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(
                        Icons.assessment_rounded,
                        color: Colors.white30,
                        size: 52,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Ringkasan Aktivitas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pantau progres survey kamu di sini.',
                  style: TextStyle(
                    fontSize: 13,
                    color: textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<DashboardStats>(
                  future: _statsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: primaryColor,
                          ),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return _buildError(snapshot.error!);
                    }

                    final stats = snapshot.data;
                    if (stats == null) {
                      return _buildError(
                        Exception('Data dashboard kosong.'),
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            title: 'Total Survey',
                            value: stats.totalSurvey.toString(),
                            icon: Icons.assignment_turned_in_rounded,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            title: 'Total Kategori',
                            value: stats.totalKategori.toString(),
                            icon: Icons.category_rounded,
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: borderColor),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates_outlined,
                        color: primaryColor,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tetap Semangat!',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Pastikan data survey diisi dengan benar '
                              'sebelum disimpan.',
                              style: TextStyle(
                                color: textMuted,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError(Object error) {
    final expired = error is SessionExpiredException;
    final message = error.toString().replaceFirst('Exception: ', '');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(
            expired ? Icons.lock_outline : Icons.cloud_off_outlined,
            color: primaryColor,
            size: 38,
          ),
          const SizedBox(height: 12),
          Text(
            expired ? 'Sesi Login Berakhir' : 'Data Belum Bisa Dimuat',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          if (expired)
            ElevatedButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.login_rounded),
              label: const Text('Login Ulang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryColor,
              ),
            ),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
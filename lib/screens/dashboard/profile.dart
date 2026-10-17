import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../routes/app_routes.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // ============================================================
  // WARNA (samakan dengan halaman Daftar Survey)
  // ============================================================

  static const Color _primary = Color(0xFF1E47B0);
  static const Color _background = Color(0xFFF8FAFC);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textGrey = Color(0xFF64748B);
  static const Color _iconGrey = Color(0xFF94A3B8);

  // ============================================================
  // API
  // ============================================================

  static const String baseUrl = 'https://sijala.biz.id';
  static const String profileUrl = '$baseUrl/api/v1/profile';

  late Future<Map<String, dynamic>> _userProfileFuture;

  @override
  void initState() {
    super.initState();
    _refreshProfile();
  }

  void _refreshProfile() {
    _userProfileFuture = _fetchUserProfile();
  }

  // ============================================================
  // TOKEN
  // ============================================================

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? prefs.getString('auth_token');
    debugPrint('TOKEN ADA: ${token != null && token.isNotEmpty}');
    return token;
  }

  // ============================================================
  // AMBIL PROFILE
  // ============================================================

  Future<Map<String, dynamic>> _fetchUserProfile() async {
    final prefs = await SharedPreferences.getInstance();

    final result = <String, dynamic>{
      'name': prefs.getString('user_name') ?? 'Pengguna',
      'email': prefs.getString('user_email') ?? '-',
      'phone': prefs.getString('user_phone') ?? 'Belum Diisi',
      'gender': prefs.getString('user_gender') ?? 'Belum Diisi',
      'role': prefs.getString('user_role') ?? 'Surveyor',
      'photo': prefs.getString('user_avatar') ?? '',
    };

    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) return result;

      final response = await http.get(
        Uri.parse(profileUrl),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 20));

      debugPrint('GET PROFILE STATUS: ${response.statusCode}');
      debugPrint('BODY: ${response.body}');

      if (response.statusCode == 401) {
        await prefs.clear();
        throw Exception('401');
      }

      if (response.body.isEmpty) return result;

      final decoded = jsonDecode(response.body);

      dynamic profile;
      if (decoded is Map && decoded['data'] is Map) {
        profile = decoded['data'];
      } else {
        profile = decoded;
      }

      if (profile is! Map) return result;

      result['name'] = profile['name'] ??
          profile['nama'] ??
          profile['nama_lengkap'] ??
          result['name'];

      result['email'] = profile['email'] ?? result['email'];

      result['phone'] = profile['phone'] ??
          profile['no_hp'] ??
          profile['telepon'] ??
          result['phone'];

      final gender = profile['gender']?.toString().trim() ?? '';
      if (gender.toUpperCase() == 'L') {
        result['gender'] = 'Laki Laki';
      } else if (gender.toUpperCase() == 'P') {
        result['gender'] = 'Perempuan';
      } else if (gender.isNotEmpty) {
        result['gender'] = gender;
      }

      result['role'] =
          profile['role'] ?? profile['user_role'] ?? result['role'];

      final photo = profile['photo']?.toString().trim() ?? '';
      debugPrint('NAMA FOTO DARI API: $photo');

      if (photo.isNotEmpty) {
        result['photo'] = photo;
        await prefs.setString('user_avatar', photo);
      }

      return result;
    } catch (e) {
      debugPrint('PROFILE ERROR: $e');
      if (e.toString().contains('401')) rethrow;
      return result;
    }
  }

  // ============================================================
  // FOTO
  // ============================================================

  String _getPhotoUrl(String fileName) {
    String name = fileName.trim();

    if (name.startsWith('http://') || name.startsWith('https://')) {
      return name;
    }

    while (name.startsWith('/')) {
      name = name.substring(1);
    }

    final url = '$baseUrl/api/image/$name';
    debugPrint('URL FOTO FINAL: $url');
    return url;
  }

  Widget _buildAvatar(String photoName) {
    final photo = photoName.trim();

    if (photo.isEmpty || photo == 'null' || photo == 'undefined') {
      return _defaultAvatar();
    }

    // BASE64
    if (photo.startsWith('data:image') ||
        (!photo.startsWith('http') && photo.length > 200)) {
      try {
        String base64Data = photo;
        if (base64Data.contains(',')) {
          base64Data = base64Data.split(',').last;
        }

        return Image.memory(
          base64Decode(base64Data),
          width: 96,
          height: 96,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _defaultAvatar(),
        );
      } catch (e) {
        debugPrint('BASE64 ERROR: $e');
        return _defaultAvatar();
      }
    }

    // URL
    final url = _getPhotoUrl(photo);

    return Image.network(
      url,
      width: 96,
      height: 96,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: CircularProgressIndicator(
            color: _primary,
            strokeWidth: 2,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        debugPrint('FOTO GAGAL DITAMPILKAN: $error');
        debugPrint('URL FOTO: $url');
        return _defaultAvatar();
      },
    );
  }

  Widget _defaultAvatar() {
    return const Center(
      child: Icon(
        Icons.person,
        size: 52,
        color: _iconGrey,
      ),
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    context.go(AppRoutes.login);
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Konfirmasi Keluar'),
          content: const Text(
            'Apakah Anda yakin ingin keluar dari akun ini?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                'Batal',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'Keluar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'Profil Saya',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: _primary,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _userProfileFuture,
        builder: (context, snapshot) {
          // LOADING
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: _primary),
            );
          }

          // TOKEN EXPIRED
          if (snapshot.hasError && snapshot.error.toString().contains('401')) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.go(AppRoutes.login);
            });

            return const Center(
              child: CircularProgressIndicator(color: _primary),
            );
          }

          final userData = snapshot.data ?? {};
          final photo = userData['photo']?.toString() ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    const SizedBox(height: 8),

                    // FOTO
                    ClipOval(
                      child: Container(
                        width: 96,
                        height: 96,
                        color: const Color(0xFFE2E8F0),
                        child: _buildAvatar(photo),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // NAMA
                    Text(
                      userData['name']?.toString() ?? 'Pengguna',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _textDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // EMAIL
                    Text(
                      userData['email']?.toString() ?? '-',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _textGrey,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ROLE
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        userData['role']?.toString() ?? 'Surveyor',
                        style: const TextStyle(
                          color: _primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // INFORMASI PRIBADI
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildTile(
                            Icons.person_outline_rounded,
                            'Nama Lengkap',
                            userData['name']?.toString() ?? 'Pengguna',
                          ),
                          _divider(),
                          _buildTile(
                            Icons.email_outlined,
                            'Email',
                            userData['email']?.toString() ?? '-',
                          ),
                          _divider(),
                          _buildTile(
                            Icons.phone_android_outlined,
                            'Nomor Telepon',
                            userData['phone']?.toString() ?? 'Belum Diisi',
                          ),
                          _divider(),
                          _buildTile(
                            Icons.wc_outlined,
                            'Jenis Kelamin',
                            userData['gender']?.toString() ?? 'Belum Diisi',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // TOMBOL
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final result = await context.push(
                                  AppRoutes.edit,
                                  extra: userData,
                                );

                                if (result == true && mounted) {
                                  setState(() {
                                    _refreshProfile();
                                  });
                                }
                              },
                              icon: const Icon(
                                Icons.edit_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Edit',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary,
                                elevation: 0,
                                shape: const StadiumBorder(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: OutlinedButton.icon(
                              onPressed: _showLogoutDialog,
                              icon: const Icon(
                                Icons.logout_rounded,
                                size: 18,
                                color: Colors.red,
                              ),
                              label: const Text(
                                'Keluar',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                shape: const StadiumBorder(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // KOMPONEN
  // ============================================================

  Widget _divider() {
    return const Divider(
      color: Color(0xFFE2E8F0),
      height: 1,
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: _primary, size: 22),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: _textGrey,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: _textDark,
        ),
      ),
    );
  }
}
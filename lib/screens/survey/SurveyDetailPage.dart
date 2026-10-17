import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../routes/app_routes.dart';

class SurveyScreen extends StatefulWidget {
  final int surveyId;

  const SurveyScreen({
    super.key,
    required this.surveyId,
  });

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  bool isLoading = true;
  Map<String, dynamic>? surveyData;
  String userToken = '';

  @override
  void initState() {
    super.initState();
    getSurveyDetail();
  }

  // Ambil detail survey
  Future<void> getSurveyDetail() async {
    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? prefs.getString('auth_token') ?? '';
      userToken = token;

      final response = await http.get(
        Uri.parse('https://sijala.biz.id/api/v1/surveys/${widget.surveyId}'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (data is Map && data.containsKey('data')) {
            surveyData = Map<String, dynamic>.from(data['data']);
          } else if (data is Map) {
            surveyData = Map<String, dynamic>.from(data);
          }
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        showMessage('Gagal memuat detail survey (Kode: ${response.statusCode})');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showMessage('Terjadi kesalahan koneksi.');
    }
  }

  // Buka Halaman Edit
  Future<void> openEditSurvey() async {
    final result = await context.push<bool>(
      AppRoutes.add_survey,
      extra: surveyData,
    );

    if (result == true && mounted) {
      getSurveyDetail();
    }
  }

  // FUNGSI HAPUS SURVEY
  Future<void> deleteSurvey() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Survey'),
        content: const Text('Apakah Anda yakin ingin menghapus survey ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final response = await http.post(
        Uri.parse('https://sijala.biz.id/api/v1/surveys/${widget.surveyId}/delete'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 204) {
        showMessage('Survey berhasil dihapus');
        context.pop(true);
      } else {
        String serverMessage = 'Gagal menghapus survey';
        try {
          final resData = jsonDecode(response.body);
          if (resData['message'] != null) {
            serverMessage = resData['message'];
          }
        } catch (_) {}

        setState(() => isLoading = false);
        showMessage('$serverMessage (Kode HTTP: ${response.statusCode})');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showMessage('Terjadi kesalahan koneksi.');
    }
  }

  // Fungsi Helper untuk membersihkan dan membuat URL foto penuh
  String? getImageUrl(dynamic rawPath) {
  if (rawPath == null) return null;

  String photoPath = rawPath.toString().trim();

  if (photoPath.isEmpty) return null;

  // Kalau sudah URL lengkap
  if (photoPath.startsWith('http://') ||
      photoPath.startsWith('https://')) {
    return photoPath;
  }

  // Bersihkan slash di awal
  photoPath = photoPath.replaceFirst(RegExp(r'^/+'), '');

  // Kalau dari API tersimpan seperti storage/nama.jpg
  if (photoPath.startsWith('storage/')) {
    photoPath = photoPath.substring('storage/'.length);
  }

  // Kalau tersimpan seperti api/image/nama.jpg
  if (photoPath.startsWith('api/image/')) {
    photoPath = photoPath.substring('api/image/'.length);
  }

  return 'https://sijala.biz.id/api/image/$photoPath';
}

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Memeriksa berbagai kunci JSON yang mungkin digunakan oleh API backend Anda
    final rawPhoto = surveyData?['photo'] ?? 
                     surveyData?['image'] ?? 
                     surveyData?['photo_url'] ?? 
                     surveyData?['image_url'];
                     
    final photoUrl = getImageUrl(rawPhoto);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E48AF),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('Detail Survey #${widget.surveyId}'),
        actions: [
          if (!isLoading && surveyData != null) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Survey',
              onPressed: openEditSurvey,
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Hapus Survey',
              onPressed: deleteSurvey,
            ),
          ],
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E48AF)),
            )
          : surveyData == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Data survey tidak ditemukan.'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: getSurveyDetail,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- MENAMPILKAN FOTO SURVEY ---
                          if (photoUrl != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                photoUrl,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                                headers: userToken.isNotEmpty
                                    ? {'Authorization': 'Bearer $userToken'}
                                    : null,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 150,
                                    width: double.infinity,
                                    color: Colors.grey[200],
                                    child: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image, color: Colors.grey, size: 40),
                                        SizedBox(height: 8),
                                        Text(
                                          'Gagal memuat gambar',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    height: 200,
                                    width: double.infinity,
                                    color: Colors.grey[100],
                                    child: const Center(
                                      child: CircularProgressIndicator(color: Color(0xFF1E48AF)),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          // ---------------------------------

                          Text(
                            surveyData!['title']?.toString() ?? '-',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF263238),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                          const Text(
                            'Deskripsi:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF546E7A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            surveyData!['description']?.toString() ?? '-',
                            style: const TextStyle(color: Color(0xFF78909C)),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Color(0xFF1E48AF)),
                              const SizedBox(width: 6),
                              Text(
                                'Lat: ${surveyData!['latitude'] ?? '-'}, Lng: ${surveyData!['longitude'] ?? '-'}',
                                style: const TextStyle(color: Color(0xFF78909C)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }
}
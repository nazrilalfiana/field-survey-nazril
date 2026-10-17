import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../routes/app_routes.dart'; // Sesuaikan path jika perlu

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Warna (samakan dengan halaman Daftar Survey & Profil)
  static const Color _primary = Color(0xFF1E47B0);
  static const Color _background = Color(0xFFF8FAFC);
  static const Color _textGrey = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _checkInitialRoute();
  }

  Future<void> _checkInitialRoute() async {
    // 1. Beri jeda 3 detik agar splash screen sempat tampil di layar
    await Future.delayed(const Duration(seconds: 3));

    // 2. Cek apakah widget masih terpasang di pohon widget
    if (!mounted) return;

    // 3. Jika sudah punya token/login, langsung ke dashboard
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('auth_token');

    if (!mounted) return;

    if (token != null && token.isNotEmpty) {
      context.go(AppRoutes.dashboard);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Logo
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: _primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.landscape_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'SIJALA',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _primary,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Aplikasi Survey Field Mobile',
                style: TextStyle(
                  fontSize: 13,
                  color: _textGrey,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 32),

              // Loading Indicator
              const SizedBox(
                width: 26,
                height: 26,
                child: CircularProgressIndicator(
                  color: _primary,
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
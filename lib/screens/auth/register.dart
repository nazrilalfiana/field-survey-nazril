import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../routes/app_routes.dart'; // Sesuaikan path jika perlu

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _noHpController = TextEditingController();

  String? _jenisKelamin;
  bool _isLoading = false;

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _noHpController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Endpoint API untuk registrasi
    final Uri url = Uri.parse("https://sijala.biz.id/api/v1/register");

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          "name": _namaController.text.trim(),
          "email": _emailController.text.trim(),
          "gender": _jenisKelamin,
          "phone": _noHpController.text.trim(),
        }),
      );

      if (!mounted) return;

      // Log response untuk debug di console
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();

        // Menyimpan data login/user jika backend mengembalikan token
        final userData = data["data"] ?? data["user"] ?? {};
        final token = data["token"] ?? data["access_token"] ?? userData["token"];

        if (token != null) {
          await prefs.setString("auth_token", token.toString());
        }

        await prefs.setString("user_name", _namaController.text.trim());
        await prefs.setString("user_email", _emailController.text.trim());
        await prefs.setString("user_phone", _noHpController.text.trim());
        if (_jenisKelamin != null) {
          await prefs.setString("user_gender", _jenisKelamin!);
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"] ?? "Registrasi berhasil!"),
            backgroundColor: Colors.green.shade700,
          ),
        );

        // Jika ada token, langsung ke Home. Jika tidak, ke Login.
        if (token != null && token.toString().isNotEmpty) {
          context.go(AppRoutes.dashboard);
        } else {
          context.go(AppRoutes.login);
        }
      } else {
        // MENANGANI JIKA VALIDASI BACKEND GAGAL
        String errorMessage = data["message"] ?? "Registrasi gagal";

        // Jika backend mengirim detail error per field (misal status 422)
        if (data["errors"] != null && data["errors"] is Map) {
          final Map<String, dynamic> errors = data["errors"];
          List<String> messages = [];
          
          errors.forEach((key, value) {
            if (value is List) {
              messages.add(value.join(", "));
            } else {
              messages.add(value.toString());
            }
          });

          if (messages.isNotEmpty) {
            errorMessage = messages.join("\n");
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Terjadi kesalahan koneksi/server: $e"),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            color: Colors.black,
          ),

          // 2. FORM GLASSMORPHISM
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Icon(
                              Icons.person_add_rounded,
                              size: 70,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "REGISTRASI",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Silakan lengkapi data diri Anda",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 28),

                            // Nama Lengkap
                            TextFormField(
                              controller: _namaController,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration(
                                label: "Nama Lengkap",
                                icon: Icons.person_outline,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Nama lengkap tidak boleh kosong";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Email
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration(
                                label: "Email",
                                icon: Icons.email_outlined,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "Email tidak boleh kosong";
                                }
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                                  return "Format email tidak valid";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Jenis Kelamin
                            DropdownButtonFormField<String>(
                              value: _jenisKelamin,
                              dropdownColor: Colors.blueGrey.shade900.withOpacity(0.95),
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration(
                                label: "Jenis Kelamin",
                                icon: Icons.wc_outlined,
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: "L",
                                  child: Text("L", style: TextStyle(color: Colors.white)),
                                ),
                                DropdownMenuItem(
                                  value: "P",
                                  child: Text("P", style: TextStyle(color: Colors.white)),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _jenisKelamin = value;
                                });
                              },
                              validator: (value) {
                                if (value == null) {
                                  return "Pilih jenis kelamin";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // No HP
                            TextFormField(
                              controller: _noHpController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration(
                                label: "No. HP",
                                icon: Icons.phone_android_outlined,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return "No. HP tidak boleh kosong";
                                }
                                if (value.trim().length < 10) {
                                  return "No. HP tidak valid (min. 10 digit)";
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 28),

                            // Tombol Register
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.blue.shade900,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 2,
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.blue.shade900,
                                        ),
                                      )
                                    : const Text(
                                        "DAFTAR",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          letterSpacing: 1,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Navigasi ke Login
                            TextButton(
                              onPressed: () => context.go(AppRoutes.login),
                              child: Text(
                                "Sudah punya akun? Login di sini",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
      prefixIcon: Icon(icon, color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white, width: 1.5),
      ),
      errorStyle: const TextStyle(color: Colors.yellowAccent),
    );
  }
}
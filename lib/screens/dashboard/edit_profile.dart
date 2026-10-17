import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfilePage({super.key, required this.userData});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  String _selectedGender = 'Laki Laki';

  File? _imageFile; // Menyimpan foto lokal yang baru dipilih di HP
  Uint8List? _webImageBytes; // Menyimpan bytes foto jika di Flutter Web
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.userData['name'] ?? '');
    _phoneController = TextEditingController(text: widget.userData['phone'] ?? '');

    final gender = widget.userData['gender']?.toString() ?? '';
    if (gender == 'Perempuan' || gender == 'P') {
      _selectedGender = 'Perempuan';
    } else {
      _selectedGender = 'Laki Laki';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // ============================================================
  // PILIH FOTO (DARI GALERI ATAU KAMERA)
  // ============================================================
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80, // Kompresi gambar agar tidak terlalu besar
        maxWidth: 800,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImageBytes = bytes;
            _imageFile = null;
          });
        } else {
          setState(() {
            _imageFile = File(pickedFile.path);
            _webImageBytes = null;
          });
        }
      }
    } catch (e) {
      debugPrint('Error pick image: $e');
    }
  }

  // DIALOG PILIHAN KAMERA / GALERI
  void _showImagePickerBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // UPDATE PROFILE (KIRIM KE API)
  // ============================================================
  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? prefs.getString('auth_token');

      // 1. Buat Multipart Request
      final uri = Uri.parse('https://sijala.biz.id/api/v1/profile/update'); // Sesuaikan endpoint update API milikmu
      final request = http.MultipartRequest('POST', uri);

      // Header Authorization
      request.headers.addAll({
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      });

      // Form Text Fields
      request.fields['name'] = _nameController.text.trim();
      request.fields['phone'] = _phoneController.text.trim();
      request.fields['gender'] = _selectedGender == 'Laki Laki' ? 'L' : 'P';

      // Attach Foto jika user memilih foto baru
      if (_imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'photo', // Nama key di field API (sesuaikan jika backend minta 'avatar' / 'image')
            _imageFile!.path,
          ),
        );
      } else if (kIsWeb && _webImageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            _webImageBytes!,
            filename: 'profile_update.jpg',
          ),
        );
      }

      // 2. Send Request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('UPDATE RESPONSE STATUS: ${response.statusCode}');
      debugPrint('UPDATE RESPONSE BODY: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        
        // Simpan data lokal baru ke SharedPreferences
        await prefs.setString('user_name', _nameController.text.trim());
        await prefs.setString('user_phone', _phoneController.text.trim());
        await prefs.setString('user_gender', _selectedGender);

        // Jika API mengembalikan nama foto baru
        if (decoded is Map && decoded['data'] != null && decoded['data']['photo'] != null) {
          await prefs.setString('user_avatar', decoded['data']['photo']);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui!')),
        );

        // Pop halaman dengan mengirim nilai `true` untuk memicu refresh di ProfilePage
        Navigator.pop(context, true);
      } else {
        throw Exception('Gagal memperbarui profil (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('UPDATE ERROR: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ============================================================
  // UI BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profil'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // --- AVATAR / FOTO EDIT ---
                    Center(
                      child: Stack(
                        children: [
                          ClipOval(
                            child: SizedBox(
                              width: 120,
                              height: 120,
                              child: _buildAvatarImage(),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              backgroundColor: Colors.blue,
                              radius: 18,
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                                onPressed: _showImagePickerBottomSheet,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- FIELD NAMA ---
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (val) => val == null || val.isEmpty ? 'Nama tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 16),

                    // --- FIELD TELEPON ---
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Telepon',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- FIELD GENDER ---
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: const InputDecoration(
                        labelText: 'Jenis Kelamin',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.wc),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Laki Laki', child: Text('Laki Laki')),
                        DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedGender = val);
                      },
                    ),
                    const SizedBox(height: 30),

                    // --- BUTTON SIMPAN ---
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'SIMPAN PERUBAHAN',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // TAMPILAN IMAGE AVATAR
  Widget _buildAvatarImage() {
    if (_imageFile != null) {
      return Image.file(_imageFile!, fit: BoxFit.cover);
    }
    if (kIsWeb && _webImageBytes != null) {
      return Image.memory(_webImageBytes!, fit: BoxFit.cover);
    }
    
    // Default gambar lama dari network
    final oldPhoto = widget.userData['photo']?.toString() ?? '';
    if (oldPhoto.isNotEmpty && oldPhoto != 'null') {
      final url = oldPhoto.startsWith('http')
          ? oldPhoto
          : 'https://sijala.biz.id/api/image/${oldPhoto.replaceFirst(RegExp(r'^/'), '')}';
      return Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _defaultIcon());
    }

    return _defaultIcon();
  }

  Widget _defaultIcon() {
    return Container(
      color: Colors.grey.shade300,
      child: const Icon(Icons.person, size: 60, color: Colors.grey),
    );
  }
}
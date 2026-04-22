import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:nexaflow_mobile/features/auth/providers/auth_provider.dart';
import 'package:nexaflow_mobile/core/api/api_client.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;

  bool _isLoading = false;
  File? _imageFile;
  String? _currentProfilePicture;

  @override
  void initState() {
    super.initState();
    final customer = ref.read(authProvider).customer!;
    _firstNameController = TextEditingController(text: customer.firstName);
    _lastNameController = TextEditingController(text: customer.lastName);
    _phoneController = TextEditingController(text: customer.phone ?? '');
    _addressController = TextEditingController(text: customer.address ?? '');
    _cityController = TextEditingController(text: customer.city ?? '');
    _currentProfilePicture = customer.profilePicture;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final customer = ref.read(authProvider).customer!;

    setState(() => _isLoading = true);

    try {
      final api = ref.read(apiClientProvider);
      String? newPicUrl = _currentProfilePicture;

      // 1. Upload image if selected
      if (_imageFile != null) {
        String fileName = _imageFile!.path.split('/').last;
        FormData formData = FormData.fromMap({
          "files": await MultipartFile.fromFile(_imageFile!.path, filename: fileName),
        });

        final uploadRes = await api.post('/upload/images', data: formData);
        // Le backend utilise un TransformInterceptor qui enveloppe la réponse dans { statusCode, data: ... }
        final responseData = uploadRes.data as Map<String, dynamic>;
        final actualData = responseData.containsKey('data') ? responseData['data'] : responseData;

        if (actualData != null && actualData['urls'] != null && (actualData['urls'] as List).isNotEmpty) {
          newPicUrl = actualData['urls'][0];
        }
      }

      // 2. Update DB
      final updateData = {
        "firstName": _firstNameController.text.trim(),
        "lastName": _lastNameController.text.trim(),
        "phone": _phoneController.text.trim(),
        "address": _addressController.text.trim(),
        "city": _cityController.text.trim(),
        "profilePicture": newPicUrl,
      };

      await api.patch('/customers/me', data: updateData);

      // 3. Reload profile
      await ref.read(authProvider.notifier).checkAuth();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil mis à jour avec succès', style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar picker
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF6366F1), width: 2),
                      ),
                      child: ClipOval(
                        child: _imageFile != null
                            ? Image.file(_imageFile!, fit: BoxFit.cover)
                            : (_currentProfilePicture != null && _currentProfilePicture!.isNotEmpty)
                                ? CachedNetworkImage(
                                    imageUrl: _currentProfilePicture!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => const CircularProgressIndicator(),
                                    errorWidget: (context, url, error) => const Icon(Icons.person, size: 50, color: Colors.grey),
                                  )
                                : const Icon(Icons.person, size: 50, color: Colors.grey),
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF6366F1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _buildTextField(_firstNameController, 'Prénom', Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField(_lastNameController, 'Nom', Icons.person_outline),
              const SizedBox(height: 16),
              _buildTextField(_phoneController, 'Téléphone', Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField(_addressController, 'Adresse', Icons.location_on_outlined),
              const SizedBox(height: 16),
              _buildTextField(_cityController, 'Ville', Icons.location_city_outlined),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Enregistrer les modifications', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF6366F1))),
      ),
      validator: (value) {
        if (label == 'Prénom' || label == 'Nom') {
          if (value == null || value.isEmpty) return 'Ce champ est requis';
        }
        return null;
      },
    );
  }
}

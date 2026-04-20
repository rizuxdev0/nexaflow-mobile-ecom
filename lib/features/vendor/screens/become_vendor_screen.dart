import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nexaflow_mobile/core/api/vendor_providers.dart';
import 'package:nexaflow_mobile/core/models/vendor.dart';
import 'package:nexaflow_mobile/features/auth/providers/auth_provider.dart';

class BecomeVendorScreen extends ConsumerStatefulWidget {
  const BecomeVendorScreen({super.key});

  @override
  ConsumerState<BecomeVendorScreen> createState() => _BecomeVendorScreenState();
}

class _BecomeVendorScreenState extends ConsumerState<BecomeVendorScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Form Controllers
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  
  // Legal Docs
  XFile? _idCard;
  XFile? _commerceRegister;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final customer = ref.read(authProvider).customer;
    if (customer != null) {
      _contactController.text = customer.fullName;
      _emailController.text = customer.email;
      _phoneController.text = customer.phone ?? '';
      _cityController.text = customer.city ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isIdCard) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isIdCard) {
          _idCard = image;
        } else {
          _commerceRegister = image;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idCard == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez uploader votre pièce d\'identité')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(vendorServiceProvider).createVendor({
        'name': _nameController.text,
        'contactPerson': _contactController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'description': _descriptionController.text,
        'city': _cityController.text,
        'country': 'Sénégal',
        // In a real app, we would upload files first and get URLs or use multipart
        // For this demo, we simulate the submission
        'legalDocs': ['id_card_simulated.jpg', if (_commerceRegister != null) 'register_simulated.jpg'],
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Candidature envoyée !'),
            content: const Text('Votre demande est en cours de révision. Nous vous contacterons sous 48h.'),
            actions: [
              TextButton(
                onPressed: () {
                  context.pop(); // Close dialog
                  context.pop(); // Return to account
                  ref.invalidate(myVendorRequestsProvider);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final requestsAsync = ref.watch(myVendorRequestsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Devenir Vendeur')),
      body: requestsAsync.when(
        data: (requests) {
          final pending = requests.where((r) => r.status == 'pending').toList();
          if (pending.isNotEmpty) {
            return _buildPendingState(pending.first);
          }
          return _buildForm(theme, isDark);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  Widget _buildPendingState(VendorApplication request) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hourglass_empty_rounded, size: 80, color: Colors.orange),
            const SizedBox(height: 24),
            const Text('Candidature en cours', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              'Votre demande pour "${request.storeName}" est en cours d\'examen par notre équipe. Vous recevrez une notification prochainement.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Retour au compte'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(ThemeData theme, bool isDark) {
    return Stepper(
      type: StepperType.horizontal,
      currentStep: _currentStep,
      onStepContinue: () {
        if (_currentStep < 2) {
          setState(() => _currentStep++);
        } else {
          _submit();
        }
      },
      onStepCancel: () {
        if (_currentStep > 0) {
          setState(() => _currentStep--);
        }
      },
      controlsBuilder: (context, details) {
        return Padding(
          padding: const EdgeInsets.only(top: 32),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : details.onStepContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_currentStep == 2 ? 'Soumettre' : 'Continuer'),
                ),
              ),
              if (_currentStep > 0) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: details.onStepCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Retour'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
      steps: [
        Step(
          isActive: _currentStep >= 0,
          state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          title: const Text('Boutique'),
          content: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(_nameController, 'Nom de la boutique', Icons.store_rounded),
                _buildTextField(_descriptionController, 'Description de votre activité', Icons.description_rounded, maxLines: 3),
                _buildTextField(_cityController, 'Ville', Icons.location_city_rounded),
              ],
            ),
          ),
        ),
        Step(
          isActive: _currentStep >= 1,
          state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          title: const Text('Contact'),
          content: Column(
            children: [
              _buildTextField(_contactController, 'Personne de contact', Icons.person_rounded),
              _buildTextField(_emailController, 'Email professionnel', Icons.email_rounded, keyboardType: TextInputType.emailAddress),
              _buildTextField(_phoneController, 'Téléphone', Icons.phone_rounded, keyboardType: TextInputType.phone),
            ],
          ),
        ),
        Step(
          isActive: _currentStep >= 2,
          state: _currentStep > 2 ? StepState.complete : StepState.indexed,
          title: const Text('Documents'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Documents légaux', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Veuillez fournir des photos claires de vos documents pour validation.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 20),
              
              _buildDocPicker('Pièce d\'identité (Recto/Verso) *', _idCard, () => _pickImage(true)),
              const SizedBox(height: 16),
              _buildDocPicker('Registre du Commerce (Optionnel)', _commerceRegister, () => _pickImage(false)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (val) => val == null || val.isEmpty ? 'Ce champ est requis' : null,
      ),
    );
  }

  Widget _buildDocPicker(String label, XFile? file, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 2),
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: file != null 
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(File(file.path), fit: BoxFit.cover),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, color: Colors.grey.shade400, size: 32),
                    const SizedBox(height: 8),
                    Text('Cliquez pour choisir', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                  ],
                ),
          ),
        ),
      ],
    );
  }
}

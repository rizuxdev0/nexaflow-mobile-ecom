import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:nexaflow_mobile/core/api/api_client.dart';
import 'package:nexaflow_mobile/features/cart/providers/cart_provider.dart';
import 'package:nexaflow_mobile/features/auth/providers/auth_provider.dart';
import 'package:nexaflow_mobile/core/api/shop_providers.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _paymentMethod = 'mobile_money';
  bool _isLoading = false;
  bool _isLocating = false;
  int _step = 0; 

  @override
  void initState() {
    super.initState();
    // Pre-fill phone if customer exists
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final customer = ref.read(authProvider).customer;
      if (customer?.phone != null) _phoneCtrl.text = customer!.phone!;
    });
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    setState(() => _isLocating = true);
    
    try {
      // Test if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Le service de localisation est désactivé.'))
          );
        }
        return;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Les permissions de localisation sont refusées.'))
            );
          }
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Les permissions sont définitivement refusées. Veuillez les activer dans les paramètres.'))
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks[0];
        final parts = [p.street, p.subLocality, p.locality].where((s) => s != null && s.isNotEmpty).toList();
        setState(() => _addressCtrl.text = parts.join(', '));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de récupérer la position : $e'))
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    _promoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final theme = Theme.of(context);
    final primaryColor = const Color(0xFF6366F1);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Step Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Row(
              children: [
                _buildStepCircle(0, Icons.location_on_rounded, isActive: _step >= 0),
                Expanded(child: Container(height: 2, color: _step >= 1 ? primaryColor : Colors.grey.shade200)),
                _buildStepCircle(1, Icons.payment_rounded, isActive: _step >= 1),
                Expanded(child: Container(height: 2, color: _step >= 2 ? primaryColor : Colors.grey.shade200)),
                _buildStepCircle(2, Icons.fact_check_rounded, isActive: _step >= 2),
              ],
            ),
          ),

          Expanded(
            child: Form(
              key: _formKey,
              child: PageView(
                physics: const NeverScrollableScrollPhysics(),
                controller: _pageController,
                onPageChanged: (i) => setState(() => _step = i),
                children: [
                  _buildAddressStep(theme, primaryColor, isDark),
                  _buildPaymentStep(theme, primaryColor, isDark),
                  _buildSummaryStep(cart, primaryColor, isDark),
                ].map((w) => SingleChildScrollView(padding: const EdgeInsets.all(24), child: w)).toList(),
              ),
            ),
          ),

          // Bottom Bar
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -10))],
            ),
            child: Row(
              children: [
                if (_step > 0)
                  IconButton(
                    onPressed: () {
                      setState(() => _step--);
                      _pageController.animateToPage(_step, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100, padding: const EdgeInsets.all(16)),
                  ),
                if (_step > 0) const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(_step == 2 ? 'Confirmer Payement' : 'Continuer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int index, IconData icon, {required bool isActive}) {
    final primaryColor = const Color(0xFF6366F1);
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: isActive ? primaryColor : Colors.grey.shade100,
        shape: BoxShape.circle,
        boxShadow: isActive ? [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
      ),
      child: Icon(icon, color: isActive ? Colors.white : Colors.grey, size: 20),
    );
  }

  Widget _buildAddressStep(ThemeData theme, Color primary, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Où livrer ? 📍', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text('Renseignez vos coordonnées pour la livraison.', style: TextStyle(color: Colors.grey.shade500)),
        const SizedBox(height: 32),
        TextFormField(
          controller: _addressCtrl,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Adresse de livraison',
            prefixIcon: const Icon(Icons.map_outlined),
            suffixIcon: _isLocating 
              ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(icon: const Icon(Icons.my_location_rounded), onPressed: _getCurrentLocation),
          ),
          validator: (v) => v!.isEmpty ? 'Requis' : null,
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(labelText: 'Téléphone', prefixIcon: Icon(Icons.phone_outlined)),
          validator: (v) => v!.isEmpty ? 'Requis' : null,
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _notesCtrl,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Instructions (optionnel)', prefixIcon: Icon(Icons.notes_rounded)),
        ),
      ],
    );
  }

  IconData _iconForMethod(String id) {
    switch (id) {
      case 'mobile_money': return Icons.phone_android_rounded;
      case 'card': return Icons.credit_card_rounded;
      case 'bank_transfer': return Icons.account_balance_rounded;
      case 'cash_on_delivery': return Icons.local_atm_rounded;
      default: return Icons.payment_rounded;
    }
  }

  Color _colorForMethod(String id) {
    switch (id) {
      case 'mobile_money': return const Color(0xFFF59E0B);
      case 'card': return const Color(0xFF10B981);
      case 'bank_transfer': return const Color(0xFF3B82F6);
      case 'cash_on_delivery': return const Color(0xFF6B7280);
      default: return const Color(0xFF6366F1);
    }
  }

  Widget _buildPaymentStep(ThemeData theme, Color primary, bool isDark) {
    final configAsync = ref.watch(storeConfigProvider);

    // Default fallback methods if config is unavailable
    final fallbackMethods = [
      {'id': 'mobile_money', 'name': 'Mobile Money', 'description': 'TMoney ou Moov Money'},
      {'id': 'card', 'name': 'Carte Bancaire', 'description': 'Visa, Mastercard (Sécurisée)'},
      {'id': 'bank_transfer', 'name': 'Virement Bancaire', 'description': 'Traitement sous 24-48h'},
      {'id': 'cash_on_delivery', 'name': 'Espèces', 'description': 'Paiement à la livraison'},
    ];

    final List<Map<String, dynamic>> methods = configAsync.maybeWhen(
      data: (config) {
        if (config == null || config.paymentMethods.isEmpty) return fallbackMethods;
        final enabled = config.paymentMethods
            .where((m) => m['enabled'] == true)
            .toList();
        if (enabled.isEmpty) return fallbackMethods;
        return enabled.map((m) => {
          'id': m['id'] as String,
          'name': m['name'] as String? ?? m['id'],
          'description': m['description'] as String? ?? m['instructions'] as String? ?? '',
          'details': m['details'] as Map<String, dynamic>?,
          'instructions': m['instructions'] as String?,
        }).toList();
      },
      orElse: () => fallbackMethods,
    );

    // Auto-select first method when methods load
    if (_paymentMethod.isEmpty && methods.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _paymentMethod = methods.first['id'] as String);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Mode de paiement 💳', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const Spacer(),
            if (configAsync.isLoading) 
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
        const SizedBox(height: 8),
        Text('Choisissez votre mode de règlement préféré.', style: TextStyle(color: Colors.grey.shade500)),
        const SizedBox(height: 32),
        ...methods.map((m) {
          final id = m['id'] as String;
          final isSelected = _paymentMethod == id;
          final color = _colorForMethod(id);
          final icon = _iconForMethod(id);
          final name = m['name'] as String;
          final desc = m['description'] as String? ?? '';

          return Column(
            children: [
              GestureDetector(
                onTap: () => setState(() => _paymentMethod = id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.05) : (isDark ? Colors.white.withOpacity(0.02) : Colors.white),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? color : (isDark ? Colors.white10 : Colors.grey.shade200), 
                      width: 2
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? color : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50), 
                          borderRadius: BorderRadius.circular(14)
                        ),
                        child: Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isSelected ? color : null)),
                            if (desc.isNotEmpty)
                              Text(desc, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                          ],
                        ),
                      ),
                      if (isSelected) 
                        Icon(Icons.check_circle_rounded, color: color, size: 24)
                      else 
                        Icon(Icons.radio_button_off_rounded, color: Colors.grey.shade300, size: 24),
                    ],
                  ),
                ),
              ),

              // Method Details (Conditional)
              if (isSelected)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                  child: _buildMethodDetails(id, theme, color, isDark, m),
                ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildMethodDetails(String id, ThemeData theme, Color color, bool isDark, Map<String, dynamic> methodData) {
    final instructions = methodData['instructions'] as String?;
    final details = methodData['details'] as Map<String, dynamic>?;

    if (id == 'mobile_money') {
      return Column(
        children: [
          TextFormField(
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Numéro Mobile Money',
              hintText: 'Ex: 90 00 00 00',
              prefixIcon: Icon(Icons.phone_iphone_rounded, color: color),
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            instructions ?? 'Vous recevrez une demande de confirmation sur votre téléphone.', 
            style: const TextStyle(fontSize: 10, fontStyle: FontStyle.italic, color: Colors.grey)
          ),
        ],
      );
    }
    if (id == 'bank_transfer') {
      // Use details from config or show placeholder
      final bankDetails = details ?? {};
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Coordonnées Bancaires', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 12),
            if (bankDetails.isNotEmpty)
              ...bankDetails.entries.map((e) => _buildBankInfo(e.key, e.value.toString()))
            else ...[
              _buildBankInfo('Banque', 'ECOBANK TOGO'),
              _buildBankInfo('IBAN', 'TG010 0123 4567 8901 2345'),
              _buildBankInfo('Bénéficiaire', 'NEXAFLOW SARL'),
            ],
            const SizedBox(height: 8),
            Text(
              instructions ?? 'Veuillez mettre votre numéro de commande en référence.',
              style: const TextStyle(fontSize: 10, color: Colors.grey)
            ),
          ],
        ),
      );
    }
    if (id == 'card') {
      return Column(
        children: [
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Numéro de carte',
              prefixIcon: Icon(Icons.credit_card_rounded, color: color),
              filled: true,
              fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(labelText: 'MM/YY'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(labelText: 'CVV'),
                ),
              ),
            ],
          ),
        ],
      );
    }
    // Generic instructions display for any other method
    if (instructions != null && instructions.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Text(instructions, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      );
    }
    return const SizedBox();
  }

  Widget _buildBankInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'Monospace')),
        ],
      ),
    );
  }

  final _promoCtrl = TextEditingController();
  double _promoDiscount = 0;
  bool _isPromoApplied = false;
  bool _isValidatingPromo = false;

  Future<void> _applyPromoCode() async {
    if (_promoCtrl.text.isEmpty) return;
    setState(() => _isValidatingPromo = true);
    try {
      final cart = ref.read(cartProvider);
      final response = await ref.read(apiClientProvider).post('/promos/validate', data: {
        'code': _promoCtrl.text,
        'orderAmount': cart.subtotal,
      });
      
      final data = response.data;
      if (data['valid'] == true) {
        setState(() {
          _promoDiscount = (data['discount'] as num).toDouble();
          _isPromoApplied = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Code promo appliqué : -${_promoDiscount.toStringAsFixed(0)} F'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Code invalide'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la validation du code'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isValidatingPromo = false);
    }
  }

  Widget _buildSummaryStep(dynamic cart, Color primary, bool isDark) {
    final finalTotal = cart.subtotal - _promoDiscount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dernière étape ✨', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 24),
        
        // Promo Code Section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _isPromoApplied ? Colors.green : (isDark ? Colors.white10 : Colors.grey.shade200)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                   const Icon(Icons.confirmation_num_outlined, size: 20, color: Colors.grey),
                   const SizedBox(width: 8),
                   const Text('Code Promo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                   const Spacer(),
                   if (_isPromoApplied)
                    GestureDetector(
                      onTap: () => setState(() { _isPromoApplied = false; _promoDiscount = 0; _promoCtrl.clear(); }),
                      child: const Text('Retirer', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _promoCtrl,
                      enabled: !_isPromoApplied,
                      decoration: InputDecoration(
                        hintText: 'Entrez un code...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        filled: true,
                        fillColor: isDark ? Colors.white.withOpacity(0.02) : Colors.grey.shade50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isPromoApplied || _isValidatingPromo ? null : _applyPromoCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isValidatingPromo 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('OK'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              ...cart.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Text('${item.quantity}x', style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(item.product.name, style: const TextStyle(fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    Text('${item.total.toStringAsFixed(0)} F', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
              const Divider(height: 32),
              
              if (_isPromoApplied)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Réduction Promo', style: TextStyle(color: Colors.green)),
                      Text('-${_promoDiscount.toStringAsFixed(0)} F', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Final', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text('${finalTotal.toStringAsFixed(0)} FCFA', style: TextStyle(color: primary, fontWeight: FontWeight.w900, fontSize: 22)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleNext() {
    if (_step == 0) {
      if (_formKey.currentState!.validate()) {
        setState(() => _step = 1);
        _pageController.animateToPage(1, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
      }
    } else if (_step == 1) {
      setState(() => _step = 2);
      _pageController.animateToPage(2, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _placeOrder();
    }
  }

  Future<void> _placeOrder() async {
    setState(() => _isLoading = true);

    try {
      final cart = ref.read(cartProvider);
      final customer = ref.read(authProvider).customer;

      // Normalize any legacy or short IDs → backend ShopPaymentMethod enum values
      const normalize = {
        'mobile': 'mobile_money',
        'transfer': 'bank_transfer',
        'cash': 'cash_on_delivery',
        // passthrough (already correct)
        'mobile_money': 'mobile_money',
        'card': 'card',
        'bank_transfer': 'bank_transfer',
        'cash_on_delivery': 'cash_on_delivery',
      };
      final backendMethod = normalize[_paymentMethod] ?? 'cash_on_delivery';

      await ref.read(apiClientProvider).post('/shop/orders', data: {
        'customerId': customer?.id,
        'customerName': customer?.fullName ?? 'Client',
        'customerPhone': _phoneCtrl.text,
        'shippingAddress': _addressCtrl.text,
        'paymentMethod': backendMethod,
        'notes': _notesCtrl.text,
        'promoCode': _isPromoApplied ? _promoCtrl.text : null,
        'discountTotal': _promoDiscount,
        'items': cart.items.map((i) => {'productId': i.product.id, 'quantity': i.quantity}).toList(),
      });
      ref.read(cartProvider.notifier).clear();
      if (mounted) _showSuccess();
    } on DioException catch (e) {
      // Parse actual backend error message
      String errorMessage = 'Erreur lors de la commande';
      try {
        final data = e.response?.data;
        if (data is Map) {
          final msg = data['message'];
          final errors = data['errors'];
          if (errors is List && errors.isNotEmpty) {
            errorMessage = errors.join('\n');
          } else if (msg is String && msg.isNotEmpty) {
            errorMessage = msg;
          }
        }
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMessage, style: const TextStyle(fontSize: 13))),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur inattendue : $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccess() {
    showModalBottomSheet(
      context: context, isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
            const SizedBox(height: 24),
            const Text('Super ! 🎉', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            const Text('Votre commande a été reçue. Nous préparons vos articles avec soin.', textAlign: TextAlign.center),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, 
              height: 56, 
              child: ElevatedButton(
                onPressed: () {
                  context.pop(); // close modal
                  context.go('/commandes');
                }, 
                child: const Text('Voir mes commandes')
              )
            ),
          ],
        ),
      )
    );
  }
}

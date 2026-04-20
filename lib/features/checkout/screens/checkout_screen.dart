import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:nexaflow_mobile/core/api/api_client.dart';
import 'package:nexaflow_mobile/features/cart/providers/cart_provider.dart';
import 'package:nexaflow_mobile/features/auth/providers/auth_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _paymentMethod = 'mobile_money';
  bool _isLoading = false;
  bool _isLocating = false;
  int _step = 0; // 0 = address, 1 = payment, 2 = summary

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Les services de localisation sont désactivés.';
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Permissions de localisation refusées.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Permissions de localisation refusées à jamais.';
      }

      final position = await Geolocator.getCurrentPosition();
      
      // Get address from coordinates
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks[0];
        final address = "${p.street}, ${p.subLocality}, ${p.locality}, ${p.country}";
        setState(() => _addressCtrl.text = address);
      } else {
        setState(() => _addressCtrl.text = "Lat: ${position.latitude}, Long: ${position.longitude}");
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Position récupérée avec succès !'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  final _paymentMethods = [
    {'id': 'mobile_money', 'label': 'Mobile Money (TMoney/Moov)', 'icon': Icons.phone_android},
    {'id': 'cash_on_delivery', 'label': 'Paiement à la livraison', 'icon': Icons.money},
    {'id': 'card', 'label': 'Carte / Stripe', 'icon': Icons.credit_card},
  ];

  @override
  void dispose() {
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    setState(() => _isLoading = true);
    try {
      final cart = ref.read(cartProvider);
      final customer = ref.read(authProvider).customer;

      await ApiClient().post('/shop/orders', data: {
        'customerId': customer?.id,
        'customerName': customer?.fullName ?? (customer?.email ?? 'Client'),
        'customerEmail': customer?.email ?? '',
        'customerPhone': _phoneCtrl.text,
        'shippingAddress': _addressCtrl.text,
        'paymentMethod': _paymentMethod,
        'notes': _notesCtrl.text,
        'items': cart.items.map((i) => {
          'productId': i.product.id,
          'quantity': i.quantity,
        }).toList(),
      });

      ref.read(cartProvider.notifier).clear();

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 50),
                ),
                const SizedBox(height: 16),
                const Text('Commande passée !', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                const Text('Votre commande a été enregistrée avec succès. Nous vous contacterons bientôt.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () { Navigator.pop(context); context.go('/'); },
                    child: const Text('Retour à l\'accueil'),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMsg = 'Une erreur est survenue';
        if (e is DioException && e.response?.data != null) {
          final data = e.response!.data;
          if (data is Map) {
            errorMsg = data['message']?.toString() ?? e.toString();
          } else {
            errorMsg = e.toString();
          }
        } else {
          errorMsg = e.toString();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(['Livraison', 'Paiement', 'Récapitulatif'][_step]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: (_step + 1) / 3, backgroundColor: Colors.grey.shade200, color: const Color(0xFF6366F1)),
        ),
      ),
      body: Form(
        key: _formKey,
        child: IndexedStack(
          index: _step,
          children: [
            // Step 0: Address
            ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text('Adresse de livraison', style: theme.textTheme.titleLarge),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _addressCtrl,
                  decoration: InputDecoration(
                    labelText: 'Adresse complète', 
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    suffixIcon: _isLocating 
                      ? const SizedBox(width: 24, height: 24, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2)))
                      : IconButton(
                          icon: const Icon(Icons.my_location_rounded, color: Color(0xFF6366F1)),
                          onPressed: _getCurrentLocation,
                          tooltip: 'Me localiser',
                        ),
                  ),
                  maxLines: 2,
                  validator: (v) => v == null || v.isEmpty ? 'Adresse requise' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Numéro de téléphone', prefixIcon: Icon(Icons.phone_outlined)),
                  validator: (v) => v == null || v.isEmpty ? 'Téléphone requis' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(labelText: 'Notes (optionnel)', prefixIcon: Icon(Icons.note_outlined)),
                  maxLines: 2,
                ),
              ],
            ),

            // Step 1: Payment
            ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text('Méthode de paiement', style: theme.textTheme.titleLarge),
                const SizedBox(height: 24),
                ..._paymentMethods.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => setState(() => _paymentMethod = m['id'] as String),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _paymentMethod == m['id'] ? const Color(0xFF6366F1) : Colors.grey.shade300,
                          width: _paymentMethod == m['id'] ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        color: _paymentMethod == m['id'] ? const Color(0xFFF5F3FF) : null,
                      ),
                      child: Row(
                        children: [
                          Icon(m['icon'] as IconData, color: _paymentMethod == m['id'] ? const Color(0xFF6366F1) : Colors.grey),
                          const SizedBox(width: 12),
                          Text(m['label'] as String, style: theme.textTheme.bodyLarge),
                          const Spacer(),
                          if (_paymentMethod == m['id'])
                            const Icon(Icons.check_circle_rounded, color: Color(0xFF6366F1)),
                        ],
                      ),
                    ),
                  ),
                )),
              ],
            ),

            // Step 2: Summary
            ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text('Récapitulatif', style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ...cart.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Text('${item.quantity}x', style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w700)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(item.product.name, overflow: TextOverflow.ellipsis)),
                              Text('${item.total.toStringAsFixed(0)} F'),
                            ],
                          ),
                        )),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w700)),
                            Text('${cart.subtotal.toStringAsFixed(0)} FCFA', style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w700, fontSize: 18)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Livraison', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(_addressCtrl.text.isEmpty ? 'Non renseigné' : _addressCtrl.text, style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: Row(
          children: [
            if (_step > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _step--),
                  child: const Text('Retour'),
                ),
              ),
            if (_step > 0) const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () {
                    if (_step == 0) {
                      if (_formKey.currentState!.validate()) setState(() => _step = 1);
                    } else if (_step == 1) {
                      setState(() => _step = 2);
                    } else {
                      _placeOrder();
                    }
                  },
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_step < 2 ? 'Continuer →' : 'Confirmer la commande', style: const TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

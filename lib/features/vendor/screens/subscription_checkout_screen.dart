import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexaflow_mobile/core/api/subscription_providers.dart';
import 'package:nexaflow_mobile/core/models/subscription.dart';

class SubscriptionCheckoutScreen extends ConsumerStatefulWidget {
  final SubscriptionPlan plan;
  const SubscriptionCheckoutScreen({super.key, required this.plan});

  @override
  ConsumerState<SubscriptionCheckoutScreen> createState() => _SubscriptionCheckoutScreenState();
}

class _SubscriptionCheckoutScreenState extends ConsumerState<SubscriptionCheckoutScreen> {
  String _selectedPaymentMethod = 'mobile';
  bool _isSubmitting = false;

  Future<void> _handlePayment() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(subscriptionServiceProvider).subscribe(widget.plan.id, _selectedPaymentMethod);
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 80),
                const SizedBox(height: 24),
                const Text('Félicitations !', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(
                  'Vous êtes désormais abonné au plan ${widget.plan.name}. Retrouvez vos avantages dans votre espace vendeur.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.pop(); // Close dialog
                      context.pop(); // Return to pricing
                      context.pop(); // Return to account
                      ref.invalidate(mySubscriptionProvider);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Génial !'),
                  ),
                ),
              ],
            ),
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

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Récapitulatif de l\'abonnement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildPlanSummary(isDark),
            const SizedBox(height: 32),
            const Text('Méthode de paiement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildPaymentMethod(
              id: 'mobile',
              title: 'Mobile Money',
              subtitle: 'Orange Money, Wave, Free Money',
              icon: Icons.smartphone_rounded,
            ),
            _buildPaymentMethod(
              id: 'card',
              title: 'Carte Bancaire',
              subtitle: 'Visa, Mastercard',
              icon: Icons.credit_card_rounded,
            ),
            _buildPaymentMethod(
              id: 'transfer',
              title: 'Virement Bancaire',
              subtitle: 'Validation sous 24h',
              icon: Icons.account_balance_rounded,
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _handlePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
                ),
                child: _isSubmitting 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Confirmer le paiement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Paiement sécurisé par cryptage SSL',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanSummary(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.plan.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('${widget.plan.price.toStringAsFixed(0)} FCFA', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Période', style: TextStyle(color: Colors.grey.shade600)),
              Text(widget.plan.period == 'monthly' ? 'Mensuel' : 'Annuel', style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          const Divider(height: 32),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total à payer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text('Total...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF6366F1))), // Simplified
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod({required String id, required String title, required String subtitle, required IconData icon}) {
    final isSelected = _selectedPaymentMethod == id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => _selectedPaymentMethod = id),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1).withOpacity(0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF6366F1) : (isDark ? Colors.white10 : Colors.grey.shade200),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF6366F1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: isSelected ? Colors.white : Colors.grey, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle_rounded, color: Color(0xFF6366F1)),
            ],
          ),
        ),
      ),
    );
  }
}

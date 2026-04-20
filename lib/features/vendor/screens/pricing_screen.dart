import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexaflow_mobile/core/api/subscription_providers.dart';
import 'package:nexaflow_mobile/core/models/subscription.dart';

class PricingScreen extends ConsumerWidget {
  const PricingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(publicPlansProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plans & Abonnements'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: plansAsync.when(
        data: (plans) => _buildBody(context, plans, isDark, theme),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<SubscriptionPlan> plans, bool isDark, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choisissez le plan idéal pour votre croissance',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.1),
          ),
          const SizedBox(height: 12),
          Text(
            'Des solutions flexibles adaptées à chaque étape de votre entreprise.',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
          const SizedBox(height: 32),
          
          ...plans.map((plan) => _PlanCard(plan: plan)).toList(),
          
          const SizedBox(height: 40),
          _buildWhyUs(isDark),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildWhyUs(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pourquoi nous choisir ?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _whyItem(Icons.security_rounded, 'Paiements sécurisés', 'Vos transactions sont protégées par les meilleurs standards.'),
          _whyItem(Icons.trending_up_rounded, 'Visibilité accrue', 'Boostez vos ventes grâce à nos outils marketing intégrés.'),
          _whyItem(Icons.support_agent_rounded, 'Support 24/7', 'Une équipe dédiée pour vous accompagner au quotidien.'),
        ],
      ),
    );
  }

  Widget _whyItem(IconData icon, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.indigo, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(desc, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  const _PlanCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = plan.isPopular ? const Color(0xFF6366F1) : (isDark ? Colors.white70 : Colors.black87);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: plan.isPopular ? const Color(0xFF6366F1) : (isDark ? Colors.white10 : Colors.grey.shade200),
          width: plan.isPopular ? 2 : 1,
        ),
        boxShadow: [
          if (plan.isPopular)
            BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))
          else
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Stack(
        children: [
          if (plan.isPopular)
            Positioned(
              top: 12, right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(50)),
                child: const Text('RECOMMANDÉ', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: plan.isPopular ? const Color(0xFF6366F1).withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        plan.name.toLowerCase().contains('kiosque') ? Icons.shopping_bag_rounded : 
                        plan.name.toLowerCase().contains('boutique') ? Icons.rocket_launch_rounded :
                        Icons.business_center_rounded,
                        color: plan.isPopular ? const Color(0xFF6366F1) : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(plan.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('${plan.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 4),
                    Text('FCFA / ${plan.period == 'monthly' ? 'mois' : 'an'}', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(plan.description, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontStyle: FontStyle.italic)),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                ...plan.features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Text(f, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
                    ],
                  ),
                )).toList(),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => context.push('/subscription/checkout', extra: plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: plan.isPopular ? const Color(0xFF6366F1) : (isDark ? Colors.white10 : Colors.black87),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Choisir ce plan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexaflow_mobile/core/api/shop_providers.dart';
import 'package:nexaflow_mobile/features/auth/providers/auth_provider.dart';
import 'package:nexaflow_mobile/core/theme/theme_provider.dart';
import 'package:nexaflow_mobile/core/widgets/brand_logo.dart';
import 'package:nexaflow_mobile/features/settings/settings_provider.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!auth.isAuthenticated) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark 
                ? [const Color(0xFF1E1E2E), const Color(0xFF11111B)]
                : [const Color(0xFFF8FAFC), Colors.white],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const BrandLogo(size: 80),
              const SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Explorez Nexaflow et gérez vos commandes en un clin d\'œil',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => context.push('/connexion'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                    elevation: 4,
                  ),
                  child: const Text('Se connecter', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final customer = auth.customer!;
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header with Avatar
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            stretch: true,
            backgroundColor: const Color(0xFF6366F1),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5), Color(0xFF4338CA)],
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Decorative circles
                    Positioned(top: -50, right: -50, child: CircleAvatar(radius: 100, backgroundColor: Colors.white.withOpacity(0.05))),
                    Positioned(bottom: -30, left: -20, child: CircleAvatar(radius: 60, backgroundColor: Colors.white.withOpacity(0.05))),
                    
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: CircleAvatar(
                            radius: 42,
                            backgroundColor: Colors.indigo.shade100,
                            child: Text(
                              customer.fullName.isNotEmpty ? customer.fullName[0].toUpperCase() : '?',
                              style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 32, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          customer.fullName,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          customer.email,
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: () => _showLogoutDialog(context, ref),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Loyalty Card
                      _buildLoyaltyCard(customer, isDark),
                      const SizedBox(height: 24),

                      // Quick Actions Row
                      _buildQuickActions(context),
                      const SizedBox(height: 32),

                      // Sections
                      _buildSectionHeader(theme, 'Mon Expérience'),
                      const SizedBox(height: 12),
                      _buildMenuCard(isDark, [
                        _buildMenuItem(
                          icon: Icons.favorite_rounded,
                          color: Colors.pink,
                          title: 'Ma liste d\'envies',
                          onTap: () => context.push('/favoris'),
                        ),
                        _buildMenuItem(
                          icon: Icons.compare_arrows_rounded,
                          color: Colors.teal,
                          title: 'Comparateur de produits',
                          onTap: () => context.push('/compare'),
                        ),
                        _buildMenuItem(
                          icon: Icons.inventory_2_rounded,
                          color: Colors.orange,
                          title: 'Créer un Pack sur-mesure',
                          onTap: () => context.push('/custom-pack'),
                        ),
                        _buildMenuItem(
                          icon: Icons.history_edu_rounded,
                          color: Colors.brown,
                          title: 'Historique de mes Packs',
                          onTap: () => context.push('/pack-history'),
                        ),
                      ]),

                      const SizedBox(height: 24),
                      _buildSectionHeader(theme, 'Devenir Partenaire'),
                      const SizedBox(height: 12),
                      _buildMenuCard(isDark, [
                        _buildMenuItem(
                          icon: Icons.store_rounded,
                          color: Colors.indigo,
                          title: 'Candidature Vendeur',
                          onTap: () => context.push('/become-vendor'),
                        ),
                        _buildMenuItem(
                          icon: Icons.card_membership_rounded,
                          color: Colors.amber.shade700,
                          title: 'Plans & Abonnements',
                          onTap: () => context.push('/pricing'),
                        ),
                      ]),

                      const SizedBox(height: 24),
                      _buildSectionHeader(theme, 'Support & Commandes'),
                      const SizedBox(height: 12),
                      _buildMenuCard(isDark, [
                        _buildMenuItem(
                          icon: Icons.receipt_long_rounded,
                          color: Colors.purple,
                          title: 'Mes commandes',
                          onTap: () => context.push('/commandes'),
                        ),
                        _buildMenuItem(
                          icon: Icons.assignment_return_rounded,
                          color: Colors.indigo,
                          title: 'Mes retours',
                          onTap: () => context.push('/returns'),
                        ),
                        _buildMenuItem(
                          icon: Icons.help_outline_rounded,
                          color: Colors.blue,
                          title: 'Centre d\'aide',
                          onTap: () => context.pushNamed('help'),
                        ),
                        _buildMenuItem(
                          icon: Icons.chat_bubble_rounded,
                          color: Colors.blue,
                          title: 'Chat de support',
                          onTap: () => context.push('/chat'),
                        ),
                      ]),

                      const SizedBox(height: 24),
                      _buildSectionHeader(theme, 'Paramètres App'),
                      const SizedBox(height: 12),
                      _buildMenuCard(isDark, [
                        _buildSwitchItem(
                          icon: Icons.notifications_active_rounded,
                          color: Colors.green,
                          title: 'Notifications Chat',
                          value: ref.watch(settingsProvider).notificationsEnabled,
                          onChanged: (val) => ref.read(settingsProvider.notifier).toggleNotifications(val),
                        ),
                        _buildSwitchItem(
                          icon: Icons.dark_mode_rounded,
                          color: Colors.amber,
                          title: 'Thème sombre',
                          value: ref.watch(themeProvider) == ThemeMode.dark,
                          onChanged: (val) => ref.read(themeProvider.notifier).state = val ? ThemeMode.dark : ThemeMode.light,
                        ),
                      ]),
                      
                      const SizedBox(height: 40),
                      Center(
                        child: Text(
                          'Nexaflow v1.2.0 • Créé avec ❤️',
                          style: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoyaltyCard(customer, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Text('👑', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nexaflow ${customer.loyaltyTier.toUpperCase()}',
                  style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5, color: Color(0xFFD97706), fontSize: 13),
                ),
                Text(
                  '${customer.loyaltyPoints} points',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {},
                child: const Text('Avantages', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _QuickAction(icon: Icons.receipt_long_outlined, label: 'Commandes', count: '12', onTap: () => context.push('/commandes')),
        _QuickAction(icon: Icons.favorite_outline_rounded, label: 'Wishlist', count: '5', onTap: () => context.push('/favoris')),
        _QuickAction(icon: Icons.redeem_outlined, label: 'Coupons', count: '3', onTap: () {}),
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.5, color: Colors.grey.shade500),
      ),
    );
  }

  Widget _buildMenuCard(bool isDark, List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final idx = entry.key;
          final widget = entry.value;
          return Column(
            children: [
              widget,
              if (idx < items.length - 1)
                Divider(
                  height: 1,
                  indent: 52,
                  endIndent: 16,
                  color: isDark ? Colors.white10 : Colors.grey.shade100,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItem({required IconData icon, required Color color, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildSwitchItem({required IconData icon, required Color color, required String title, required bool value, required Function(bool) onChanged}) {
    return SwitchListTile.adaptive(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      activeColor: const Color(0xFF6366F1),
      value: value,
      onChanged: onChanged,
    );
  }

  Future<void> _showLogoutDialog(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter de Nexaflow ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Rester')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Déconnecter', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(authProvider.notifier).logout();
    }
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String count;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 28, color: isDark ? Colors.white70 : Colors.black87),
                Positioned(
                  top: -5, right: -10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle),
                    child: Text(count, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

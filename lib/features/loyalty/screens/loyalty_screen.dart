import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/shop_providers.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/models/loyalty.dart';

class LoyaltyScreen extends ConsumerWidget {
  const LoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final storeConfigAsync = ref.watch(storeConfigProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
        title: const Text('Privilèges & Fidélité', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: storeConfigAsync.when(
        data: (config) {
          // You can check if loyalty is enabled in config.features if needed
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!auth.isAuthenticated) _buildGuestHero(context, isDark) else _buildMemberSummary(context, auth.customer!, isDark),
                      const SizedBox(height: 32),
                      _buildTiersSection(context, auth.customer?.loyaltyPoints ?? 0, auth.isAuthenticated, isDark),
                      if (auth.isAuthenticated) ...[
                        const SizedBox(height: 32),
                        _buildRewardsSection(context, ref, isDark),
                        const SizedBox(height: 32),
                        _buildTransactionsSection(context, ref, isDark),
                      ],
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text("Erreur de chargement")),
      ),
    );
  }

  Widget _buildGuestHero(BuildContext context, bool isDark) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Center(
            child: Icon(Icons.workspace_premium_rounded, size: 50, color: Color(0xFF6366F1)),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Devenez un Membre Privilégié',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.2),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'Rejoignez le programme de fidélité NexaFlow. Gagnez des points à chaque achat, débloquez des avantages VIP et accédez à des récompenses exclusives.',
          style: TextStyle(fontSize: 15, color: Colors.grey, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => context.push('/connexion'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("S'inscrire Maintenant", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMemberSummary(BuildContext context, dynamic customer, bool isDark) {
    final points = customer.loyaltyPoints ?? 0;
    final currentTier = LoyaltyConfigData.getTier(points);
    final nextTier = LoyaltyConfigData.getNextTier(points);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bonjour, ${customer.firstName} !',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      'Membre ${currentTier.tier.toUpperCase()}',
                      style: const TextStyle(color: Color(0xFF6366F1), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(currentTier.icon, style: const TextStyle(fontSize: 28)),
                ),
              )
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Points disponibles'.toUpperCase(),
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.bold),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                points.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, height: 1),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Icon(Icons.star_rounded, color: Color(0xFFFBBF24), size: 28),
              ),
            ],
          ),
          if (nextTier != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Prochain palier : ${nextTier.tier.toUpperCase()} ${nextTier.icon}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        '$points / ${nextTier.minPoints} pts',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: points / nextTier.minPoints,
                    backgroundColor: Colors.black.withOpacity(0.2),
                    color: Colors.white,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Plus que ${nextTier.minPoints - points} points pour y arriver !',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildTiersSection(BuildContext context, int userPoints, bool isAuth, bool isDark) {
    var tiers = LoyaltyConfigData.tiers;
    final currentTier = isAuth ? LoyaltyConfigData.getTier(userPoints) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.trending_up_rounded, color: Color(0xFF6366F1)),
            const SizedBox(width: 8),
            Text('Niveaux d\'Excellence', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: tiers.length,
            itemBuilder: (context, index) {
              final t = tiers[index];
              final isUserTier = isAuth && currentTier?.tier == t.tier;

              return Container(
                width: 200,
                margin: const EdgeInsets.only(right: 16, bottom: 10, top: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: isUserTier ? Border.all(color: const Color(0xFF6366F1), width: 2) : Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                  boxShadow: isUserTier ? [
                    BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
                  ] : [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5, offset: const Offset(0, 2))
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(
                              color: isUserTier ? const Color(0xFF6366F1) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(t.icon, style: const TextStyle(fontSize: 24)),
                            ),
                          ),
                          if (isUserTier)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                              child: const Text('ACTUEL', style: TextStyle(color: Color(0xFF6366F1), fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(t.tier.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                      Text('Dès ${t.minPoints} pts', style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 4),
                      Expanded(
                        child: ListView(
                          physics: const NeverScrollableScrollPhysics(),
                          children: t.perks.take(3).map((p) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF6366F1)),
                                const SizedBox(width: 6),
                                Expanded(child: Text(p, style: const TextStyle(fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                          )).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        )
      ],
    );
  }

  Widget _buildRewardsSection(BuildContext context, WidgetRef ref, bool isDark) {
    final rewardsAsync = ref.watch(loyaltyRewardsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.card_giftcard_rounded, color: Color(0xFF6366F1)),
            const SizedBox(width: 8),
            Text('Récompenses', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 16),
        rewardsAsync.when(
          data: (rewards) {
            if (rewards.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text('Aucune récompense disponible pour le moment.')),
              );
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: rewards.length,
              itemBuilder: (context, index) {
                final r = rewards[index];
                IconData iconData = Icons.local_offer_rounded;
                if (r.type == 'free_shipping') iconData = Icons.local_shipping_rounded;
                if (r.type == 'gift') iconData = Icons.wallet_giftcard_rounded;

                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: Icon(iconData, color: const Color(0xFF6366F1), size: 18),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('${r.pointsCost} pts', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(r.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(r.description, style: const TextStyle(fontSize: 10, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              ref.read(redeemRewardProvider(r.id));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demande d\'échange envoyée')));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: const Color(0xFF6366F1),
                              elevation: 0,
                              side: const BorderSide(color: Color(0xFF6366F1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Échanger', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text("Erreur de chargement")),
        ),
      ],
    );
  }

  Widget _buildTransactionsSection(BuildContext context, WidgetRef ref, bool isDark) {
    final transAsync = ref.watch(loyaltyTransactionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded, color: Color(0xFF6366F1)),
            const SizedBox(width: 8),
            Text('Activité récente', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          ],
        ),
        const SizedBox(height: 16),
        transAsync.when(
          data: (transactions) {
            if (transactions.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: Text('Aucune activité récente.')),
              );
            }
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: transactions.take(10).length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 60),
                itemBuilder: (context, index) {
                  final t = transactions[index];
                  final isEarn = t.type == 'earn';
                  
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isEarn ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(isEarn ? Icons.add_rounded : Icons.remove_rounded, 
                        color: isEarn ? Colors.green : Colors.orange, size: 20),
                    ),
                    title: Text(t.description, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    subtitle: Text('${t.createdAt.day}/${t.createdAt.month}/${t.createdAt.year}', style: const TextStyle(fontSize: 12)),
                    trailing: Text(
                      '${isEarn ? '+' : ''}${t.points} pts',
                      style: TextStyle(fontWeight: FontWeight.bold, color: isEarn ? Colors.green : Colors.orange),
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text("Erreur de chargement")),
        ),
      ],
    );
  }
}

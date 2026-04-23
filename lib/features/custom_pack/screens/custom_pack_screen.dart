import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../providers/custom_pack_provider.dart';
import 'package:nexaflow_mobile/features/auth/providers/auth_provider.dart';

class CustomPackScreen extends ConsumerStatefulWidget {
  const CustomPackScreen({super.key});

  @override
  ConsumerState<CustomPackScreen> createState() => _CustomPackScreenState();
}

class _CustomPackScreenState extends ConsumerState<CustomPackScreen> {
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _formatAmount(double amount) {
    return NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final draftItems = ref.watch(customPackDraftProvider);
    final theme = Theme.of(context);
    final primaryColor = const Color(0xFF6366F1);

    // Calculate totals based on real config
    final configAsync = ref.watch(customPackConfigProvider);
    double totalPrice = draftItems.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
    final totalItems = draftItems.fold<int>(0, (sum, item) => sum + item.quantity);
    
    String discountType = 'percentage';
    double discountValue = 0;
    String bannerMessage = 'Ajoutez des articles pour obtenir une réduction.';
    
    if (configAsync.hasValue) {
      final config = configAsync.value!;
      final tiers = [...config.discountTiers]..sort((a, b) => b.minProducts.compareTo(a.minProducts));
      
      for (final tier in tiers) {
        if (totalItems >= tier.minProducts) {
          discountType = tier.discountType;
          discountValue = tier.discountValue;
          break;
        }
      }
      
      final upcomingTiers = config.discountTiers.where((t) => t.minProducts > totalItems).toList()
        ..sort((a, b) => a.minProducts.compareTo(b.minProducts));
        
      if (upcomingTiers.isNotEmpty) {
        final next = upcomingTiers.first;
        final remaining = next.minProducts - totalItems;
        if (discountValue > 0) {
          bannerMessage = 'Super ! Vous avez ${discountValue.toInt()}${(discountType == 'percentage' ? '%' : ' FCFA')} de réduction. Ajoutez $remaining article(s) pour passer à ${next.discountValue.toInt()}${(next.discountType == 'percentage' ? '%' : ' FCFA')} !';
        } else {
          bannerMessage = 'Ajoutez encore $remaining article(s) pour obtenir ${next.discountValue.toInt()}${(next.discountType == 'percentage' ? '%' : ' FCFA')} de réduction !';
        }
      } else if (discountValue > 0) {
        bannerMessage = 'Félicitations ! Vous bénéficiez de la réduction maximale de ${discountValue.toInt()}${(discountType == 'percentage' ? '%' : ' FCFA')}.';
      }
    }

    double discountAmount = 0;
    if (discountType == 'percentage') {
      discountAmount = totalPrice * (discountValue / 100);
    } else {
      discountAmount = discountValue;
    }
    double finalPrice = totalPrice - discountAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un Pack', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (draftItems.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(customPackDraftProvider.notifier).clearPack(),
              child: const Text('Réinitialiser', style: TextStyle(color: Colors.redAccent)),
            ),
        ],
      ),
      body: draftItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text('Votre pack est vide', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text('Ajoutez des produits depuis le catalogue pour créer un pack sur-mesure et bénéficier de réductions.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: primaryColor.withOpacity(0.1),
                  child: Row(
                    children: [
                      Icon(Icons.local_offer, color: primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          bannerMessage,
                          style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: draftItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = draftItems[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              height: 60, width: 60,
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                              child: item.product.mainImage != null
                                  ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(item.product.mainImage!, fit: BoxFit.cover))
                                  : const Icon(Icons.shopping_bag, color: Colors.grey),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                                  const SizedBox(height: 4),
                                  Text(_formatAmount(item.product.price), style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => ref.read(customPackDraftProvider.notifier).updateQuantity(item.product.id, item.quantity - 1),
                                ),
                                Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: () => ref.read(customPackDraftProvider.notifier).updateQuantity(item.product.id, item.quantity + 1),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                // Note field
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Note ou Motif (Optionnel)', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _noteController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Ex: Pour un cadeau d\'anniversaire, pack spécial...',
                          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                          contentPadding: const EdgeInsets.all(12),
                          filled: true,
                          fillColor: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Checkout Bar
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Sous-total', style: TextStyle(color: Colors.grey)),
                            Text(_formatAmount(totalPrice), style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        if (discountAmount > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Réduction', style: TextStyle(color: Colors.green)),
                              Text('- ${_formatAmount(discountAmount)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                        const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total du pack', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(_formatAmount(finalPrice), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: primaryColor)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final auth = ref.read(authProvider);
                              if (!auth.isAuthenticated) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez vous connecter pour soumettre votre pack.')));
                                context.push('/connexion');
                                return;
                              }

                              if (configAsync.hasValue) {
                                final minRequired = configAsync.value!.minProducts;
                                if (totalItems < minRequired) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Votre pack doit contenir au moins $minRequired articles.'), backgroundColor: Colors.orange.shade800));
                                  return;
                                }
                              }
                              
                              final success = await ref.read(packHistoryProvider.notifier).submitRequest(draftItems, note: _noteController.text);
                              if (success) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demande de pack envoyée avec succès !')));
                                  ref.read(customPackDraftProvider.notifier).clearPack();
                                  Navigator.pop(context);
                                }
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de l\'envoi de la demande.')));
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor, foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            ),
                            child: Builder(
                              builder: (context) {
                                int minReq = 3;
                                if (configAsync.hasValue) minReq = configAsync.value!.minProducts;
                                if (totalItems < minReq) return Text('Encore ${minReq - totalItems} article${minReq - totalItems > 1 ? 's' : ''} requis', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16));
                                return const Text('Soumettre ma Demande', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16));
                              }
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

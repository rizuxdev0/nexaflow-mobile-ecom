import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/custom_pack_provider.dart';

class CustomPackScreen extends ConsumerWidget {
  const CustomPackScreen({super.key});

  String _formatAmount(double amount) {
    return NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftItems = ref.watch(customPackDraftProvider);
    final theme = Theme.of(context);
    final primaryColor = const Color(0xFF6366F1);

    // Calculate totals directly just for display purposes
    double totalPrice = draftItems.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
    final totalItems = draftItems.fold<int>(0, (sum, item) => sum + item.quantity);
    double discountAmount = 0;
    if (totalItems >= 4) {
      discountAmount = totalPrice * 0.10;
    } else if (totalItems >= 2) {
      discountAmount = totalPrice * 0.05;
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
                // Top Banner
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
                          totalItems >= 4 ? 'Super ! Vous bénéficiez de 10% de réduction.' :
                          totalItems >= 2 ? 'Ajoutez ${4 - totalItems} article(s) pour avoir 10% de réduction. Vous avez 5% !' :
                          'Ajoutez encore 1 article pour obtenir 5% de réduction.',
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
                              height: 60,
                              width: 60,
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
                              final success = await ref.read(packHistoryProvider.notifier).submitRequest(draftItems);
                              if (success) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demande de pack envoyée avec succès !')));
                                  ref.read(customPackDraftProvider.notifier).clearPack();
                                  Navigator.pop(context); // Go back after success
                                }
                              } else {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de l\'envoi de la demande.')));
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            ),
                            child: const Text('Soumettre ma Demande', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

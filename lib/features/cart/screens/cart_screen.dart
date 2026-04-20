import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexaflow_mobile/features/cart/providers/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final theme = Theme.of(context);

    if (cart.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mon Panier')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('Votre panier est vide', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('Ajoutez des produits pour démarrer', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.go('/catalogue'),
                icon: const Icon(Icons.shopping_bag_outlined),
                label: const Text('Voir le catalogue'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Panier (${cart.itemCount})'),
        actions: [
          TextButton(
            onPressed: () => ref.read(cartProvider.notifier).clear(),
            child: const Text('Vider', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cart.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final item = cart.items[idx];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Product image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: item.product.mainImage != null
                              ? Image.network(
                                  item.product.mainImage!,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _placeholder(),
                                )
                              : _placeholder(),
                        ),
                        const SizedBox(width: 12),
                        // Name & price
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.product.name, style: theme.textTheme.titleMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(
                                '${item.product.price.toStringAsFixed(0)} FCFA',
                                style: TextStyle(color: const Color(0xFF6366F1), fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        // Quantity controls
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => ref.read(cartProvider.notifier).decrement(item.product.id),
                              icon: const Icon(Icons.remove_circle_outline),
                              color: const Color(0xFF6366F1),
                            ),
                            Text('${item.quantity}', style: theme.textTheme.titleMedium),
                            IconButton(
                              onPressed: () => ref.read(cartProvider.notifier).increment(item.product.id),
                              icon: const Icon(Icons.add_circle_outline),
                              color: const Color(0xFF6366F1),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Checkout bar
          Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: const Offset(0, -4))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Sous-total', style: theme.textTheme.bodyLarge),
                    Text('${cart.subtotal.toStringAsFixed(0)} FCFA', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/checkout'),
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Passer la commande', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 60,
    height: 60,
    color: const Color(0xFFF1F5F9),
    child: const Icon(Icons.image_outlined, color: Colors.grey),
  );
}

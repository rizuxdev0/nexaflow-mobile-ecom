import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nexaflow_mobile/features/wishlist/providers/wishlist_provider.dart';
import 'package:nexaflow_mobile/core/api/shop_providers.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlistIds = ref.watch(wishlistProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ma Liste d\'envies'),
      ),
      body: wishlistIds.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border_rounded, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Votre liste est vide', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Ajoutez des produits que vous adorez !', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/catalogue'),
                    child: const Text('Découvrir des produits'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: wishlistIds.length,
              itemBuilder: (context, index) {
                final idsList = wishlistIds.toList();
                final productId = idsList[index];
                final productAsync = ref.watch(productDetailProvider(productId));

                return productAsync.when(
                  data: (product) {
                    if (product == null) return const SizedBox();
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: product.mainImage != null
                              ? CachedNetworkImage(
                                  imageUrl: product.mainImage!,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                )
                              : Container(width: 60, height: 60, color: Colors.grey.shade100),
                        ),
                        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${product.price.toStringAsFixed(0)} FCFA',
                            style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
                        trailing: IconButton(
                          icon: const Icon(Icons.favorite, color: Colors.red),
                          onPressed: () => ref.read(wishlistProvider.notifier).toggleFavorite(product.id),
                        ),
                        onTap: () => context.push('/product/${product.id}'),
                      ),
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: LinearProgressIndicator()),
                  ),
                  error: (_, __) => const SizedBox(),
                );
              },
            ),
    );
  }
}

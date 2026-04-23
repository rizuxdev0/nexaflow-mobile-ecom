import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:nexaflow_mobile/core/api/shop_providers.dart';
import 'package:nexaflow_mobile/features/cart/providers/cart_provider.dart';
import 'package:nexaflow_mobile/features/wishlist/providers/wishlist_provider.dart';
import 'package:nexaflow_mobile/features/auth/providers/auth_provider.dart';
import 'package:nexaflow_mobile/features/custom_pack/providers/custom_pack_provider.dart';
import 'package:nexaflow_mobile/core/models/models.dart';
import 'package:nexaflow_mobile/core/widgets/product_card_premium.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFF6366F1);

    return productAsync.when(
      data: (product) {
        if (product == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('Produit introuvable')));
        }
        return Scaffold(
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Immersive Image Header
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                backgroundColor: theme.scaffoldBackgroundColor,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.9),
                    child: const BackButton(color: Color(0xFF1E293B)),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.9),
                      child: Consumer(
                        builder: (context, ref, child) {
                          final isFav = ref.watch(wishlistProvider).contains(product.id);
                          return IconButton(
                            icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border_rounded,
                              color: isFav ? Colors.red : const Color(0xFF1E293B),
                              size: 20,
                            ),
                            onPressed: () => ref.read(wishlistProvider.notifier).toggleFavorite(product.id),
                          );
                        },
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      Positioned.fill(
                        child: product.images.length > 1
                            ? PageView.builder(
                                itemCount: product.images.length,
                                itemBuilder: (context, idx) => CachedNetworkImage(
                                  imageUrl: product.images[idx],
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) => Container(color: Colors.grey.shade100),
                                ),
                              )
                            : product.mainImage != null
                                ? CachedNetworkImage(
                                    imageUrl: product.mainImage!, 
                                    fit: BoxFit.cover,
                                  )
                                : Container(color: Colors.grey.shade100),
                      ),
                      // Gradient overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter, end: Alignment.bottomCenter,
                              colors: [Colors.black.withOpacity(0.1), Colors.transparent, Colors.black.withOpacity(0.2)],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  transform: Matrix4.translationValues(0, -30, 0),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tags & Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: product.stock > 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(50),
                              ),
                              child: Text(
                                product.stock > 0 ? 'EN STOCK' : 'RUPTURE',
                                style: TextStyle(color: product.stock > 0 ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                              ),
                            ),
                            if (product.reviewCount > 0)
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                                  const SizedBox(width: 4),
                                  Text(product.averageRating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(' (${product.reviewCount})', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Title & Price
                        Text(product.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, height: 1.2)),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${product.price.toStringAsFixed(0)} FCFA',
                              style: TextStyle(color: primaryColor, fontSize: 24, fontWeight: FontWeight.w900),
                            ),
                            if (product.hasDiscount) ...[
                              const SizedBox(width: 12),
                              Text(
                                '${product.compareAtPrice!.toStringAsFixed(0)}',
                                style: const TextStyle(color: Colors.grey, fontSize: 16, decoration: TextDecoration.lineThrough),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Description
                        const Text('À propos du produit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),
                        Text(
                          product.description,
                          style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF475569), fontSize: 15, height: 1.6),
                        ),
                        const SizedBox(height: 40),

                        // Ratings Section
                        _buildSectionHeader('Avis de nos clients', () {}),
                        const SizedBox(height: 16),
                        Consumer(
                          builder: (context, ref, child) {
                            final reviewsAsync = ref.watch(productReviewsProvider(product.id));
                            return reviewsAsync.when(
                              data: (reviews) {
                                if (reviews.isEmpty) return _buildEmptyReviews(context, ref, product.id);
                                return Column(
                                  children: [
                                    _buildDetailedSummary(theme, product, reviews.length),
                                    const SizedBox(height: 24),
                                    ...reviews.take(3).map((r) => Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: _buildReviewCard(theme, r),
                                    )),
                                    if (reviews.length > 3)
                                      SizedBox(
                                        width: double.infinity,
                                        child: TextButton(onPressed: () {}, child: const Text('Voir tous les avis')),
                                      ),
                                  ],
                                );
                              },
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (_, __) => const SizedBox(),
                            );
                          },
                        ),
                        const SizedBox(height: 40),

                        // Related
                        _buildSectionHeader('Vous aimerez aussi', () {}),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 280,
                          child: Consumer(builder: (context, ref, child) {
                            // Logic: Try category first, then tags, otherwise generic fallback is handled by results
                            final filter = product.categoryId != null 
                              ? 'categoryId=${product.categoryId}' 
                              : (product.tags.isNotEmpty ? 'search=${product.tags.first}' : 'pageSize=10');
                            
                            final relatedAsync = ref.watch(productsProvider(filter));
                            
                            return relatedAsync.when(
                              data: (list) {
                                final filtered = list.where((p) => p.id != product.id).toList();
                                if (filtered.isEmpty) {
                                  return _buildNoRelatedProducts(theme);
                                }
                                return ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                                  itemBuilder: (_, idx) => ProductCardPremium(product: filtered[idx]),
                                );
                              },
                              loading: () => const Center(child: CircularProgressIndicator()),
                              error: (e, __) => _buildNoRelatedProducts(theme),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Floating Bottom Navigation
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
            ),
            child: Row(
              children: [
                // Pack Shortcut
                GestureDetector(
                  onTap: product.stock > 0 ? () {
                    ref.read(customPackDraftProvider.notifier).addProduct(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Ajouté au Pack sur-mesure !'),
                        action: SnackBarAction(label: 'VOIR', onPressed: () => context.push('/custom-pack')),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  } : null,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.inventory_2_outlined, color: primaryColor),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: product.stock > 0 ? () {
                        ref.read(cartProvider.notifier).addProduct(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Produit ajouté au panier ✓'), duration: Duration(seconds: 1)),
                        );
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('Ajouter au panier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(appBar: AppBar(), body: Center(child: Text('Erreur: $e'))),
    );
  }

  Widget _buildNoRelatedProducts(ThemeData theme) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 40, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            'Aucun produit similaire trouvé',
            style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ],
    );
  }

  Widget _buildEmptyReviews(BuildContext context, WidgetRef ref, String productId) {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05), borderRadius: BorderRadius.circular(24)),
      child: Column(children: [
        const Icon(Icons.rate_review_outlined, size: 40, color: Colors.grey),
        const SizedBox(height: 12),
        const Text('Aucun avis pour le moment', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
      ]),
    );
  }

  Widget _buildDetailedSummary(ThemeData theme, Product product, int reviewCount) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Column(
            children: [
              Text(product.averageRating.toStringAsFixed(1), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900)),
              Row(children: List.generate(5, (index) => Icon(Icons.star_rounded, size: 14, color: index < product.averageRating.floor() ? Colors.amber : Colors.grey.shade300))),
              const SizedBox(height: 4),
              Text('$reviewCount avis', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              children: List.generate(5, (index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Text('${5 - index}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: const LinearProgressIndicator(value: 0.8, minHeight: 4, backgroundColor: Colors.white, valueColor: AlwaysStoppedAnimation(Color(0xFF6366F1))))),
                  ],
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ThemeData theme, Review review) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 12, child: Text(review.customerName[0].toUpperCase(), style: const TextStyle(fontSize: 10))),
              const SizedBox(width: 8),
              Text(review.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const Spacer(),
              Row(children: List.generate(5, (index) => Icon(Icons.star_rounded, size: 12, color: index < review.rating ? Colors.amber : Colors.grey.shade300))),
            ],
          ),
          const SizedBox(height: 12),
          Text(review.comment, style: const TextStyle(fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }
}

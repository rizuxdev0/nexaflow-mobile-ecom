import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:nexaflow_mobile/core/api/shop_providers.dart';
import 'package:nexaflow_mobile/features/cart/providers/cart_provider.dart';
import 'package:nexaflow_mobile/features/wishlist/providers/wishlist_provider.dart';
import 'package:nexaflow_mobile/features/auth/providers/auth_provider.dart';
import 'package:nexaflow_mobile/core/models/models.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));
    final theme = Theme.of(context);

    return productAsync.when(
      data: (product) {
        if (product == null) {
          return Scaffold(appBar: AppBar(), body: const Center(child: Text('Produit introuvable')));
        }
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 350,
                pinned: true,
                actions: [
                  Consumer(
                    builder: (context, ref, child) {
                      final isFav = ref.watch(wishlistProvider).contains(product.id);
                      return IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.red : Colors.grey.shade600,
                        ),
                        onPressed: () {
                          ref.read(wishlistProvider.notifier).toggleFavorite(product.id);
                        },
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: product.images.length > 1
                      ? PageView.builder(
                          itemCount: product.images.length,
                          itemBuilder: (context, idx) {
                            return CachedNetworkImage(
                              imageUrl: product.images[idx],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: Colors.grey.shade100, child: const Center(child: CircularProgressIndicator())),
                              errorWidget: (context, url, error) => Container(
                                color: const Color(0xFFF1F5F9),
                                child: const Icon(Icons.image_outlined, size: 80, color: Colors.grey),
                              ),
                            );
                          },
                        )
                      : product.mainImage != null
                          ? CachedNetworkImage(
                              imageUrl: product.mainImage!, 
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: Colors.grey.shade100, child: const Center(child: CircularProgressIndicator())),
                              errorWidget: (context, url, error) => Container(
                                color: const Color(0xFFF1F5F9),
                                child: const Icon(Icons.image_outlined, size: 80, color: Colors.grey),
                              ),
                            )
                          : Container(
                              color: const Color(0xFFF1F5F9),
                              child: const Icon(Icons.image_outlined, size: 80, color: Colors.grey),
                            ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + price + rating
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product.name, style: theme.textTheme.displayMedium),
                                const SizedBox(height: 4),
                                if (product.reviewCount > 0)
                                  Row(
                                    children: [
                                      Row(
                                        children: List.generate(5, (index) {
                                          return Icon(
                                            index < product.averageRating.floor()
                                                ? Icons.star_rounded
                                                : Icons.star_outline_rounded,
                                            color: Colors.amber,
                                            size: 18,
                                          );
                                        }),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${product.averageRating.toStringAsFixed(1)} (${product.reviewCount} avis)',
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${product.price.toStringAsFixed(0)} FCFA',
                                style: const TextStyle(
                                  color: Color(0xFF6366F1),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (product.hasDiscount)
                                Text(
                                  '${product.compareAtPrice!.toStringAsFixed(0)} FCFA',
                                  style: const TextStyle(
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Stock badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: product.stock > 0 ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          product.stock > 0 ? '${product.stock} en stock' : 'Rupture de stock',
                          style: TextStyle(
                            color: product.stock > 0 ? Colors.green : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Description
                      Text('Description', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(product.description, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600, height: 1.6)),

                      // Tags
                      if (product.tags.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text('Tags', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: product.tags.map((tag) => Chip(
                            label: Text(tag, style: const TextStyle(fontSize: 12)),
                            padding: EdgeInsets.zero,
                          )).toList(),
                        ),
                      ],
                      const SizedBox(height: 32),

                      // Avis Clients Header
                      _buildAvisHeader(context, theme, product),
                      const SizedBox(height: 16),

                      Consumer(
                        builder: (context, ref, child) {
                          final reviewsAsync = ref.watch(productReviewsProvider(product.id));
                          return reviewsAsync.when(
                            data: (reviews) {
                              if (reviews.isEmpty) {
                                return _buildEmptyReviews(context, ref, product.id);
                              }

                              // Calculate real distribution
                              final distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
                              for (var r in reviews) {
                                if (r.rating >= 1 && r.rating <= 5) {
                                  distribution[r.rating] = distribution[r.rating]! + 1;
                                }
                              }

                              return Column(
                                children: [
                                  // Big Rating Box & Distribution Card
                                  _buildDetailedSummary(theme, product, reviews.length, distribution),
                                  const SizedBox(height: 24),
                                  
                                  // Reviews List
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: reviews.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 20),
                                    itemBuilder: (_, idx) {
                                      final review = reviews[idx];
                                      return _buildReviewCard(theme, review);
                                    },
                                  ),
                                ],
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (e, __) => Text('Erreur chargement avis: $e'),
                          );
                        },
                      ),
                      const SizedBox(height: 32),

                      // Related Products
                      if (product.categoryId != null) ...[
                        Text('Vous aimerez aussi', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 220,
                          child: Consumer(
                            builder: (context, ref, child) {
                              final categoryRelatedAsync = ref.watch(productsProvider('categoryId=${product.categoryId}'));
                              final generalRelatedAsync = ref.watch(productsProvider('')); // Fetch top products from the whole shop

                              return categoryRelatedAsync.when(
                                data: (categoryRelated) => generalRelatedAsync.when(
                                  data: (generalRelated) {
                                    final filteredCategory = categoryRelated.where((p) => p.id != product.id).toList();
                                    final filteredGeneral = generalRelated.where((p) => p.id != product.id && p.categoryId != product.categoryId).toList();
                                    final combined = [...filteredCategory, ...filteredGeneral].take(6).toList();
                                    
                                    if (combined.isEmpty) return const Center(child: Text('Aucun produit similaire'));

                                    return ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: combined.length,
                                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                                      itemBuilder: (_, idx) {
                                        final rel = combined[idx];
                                        return SizedBox(
                                          width: 140,
                                          child: GestureDetector(
                                            onTap: () => context.pushReplacement('/product/${rel.id}'),
                                            child: Card(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: ClipRRect(
                                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                                      child: rel.mainImage != null
                                                          ? CachedNetworkImage(
                                                              imageUrl: rel.mainImage!, 
                                                              fit: BoxFit.cover, 
                                                              width: double.infinity,
                                                              errorWidget: (_, __, ___) => Container(color: Colors.grey.shade100, child: const Icon(Icons.image_outlined, color: Colors.grey)),
                                                            )
                                                          : Container(color: Colors.grey.shade100, child: const Icon(Icons.image_outlined, color: Colors.grey)),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.all(8),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(rel.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                        Text('${rel.price.toStringAsFixed(0)} FCFA', style: const TextStyle(color: Color(0xFF6366F1), fontSize: 13, fontWeight: FontWeight.w700)),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  loading: () => const Center(child: CircularProgressIndicator()),
                                  error: (_, __) => const SizedBox(),
                                ),
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (_, __) => const SizedBox(),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 100), // Space for bottom bar
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            decoration: BoxDecoration(
              color: theme.cardColor,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: const Offset(0, -4))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: product.stock > 0
                        ? () {
                            ref.read(cartProvider.notifier).addProduct(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Ajouté au panier ✓')),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: const Text('Panier'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: product.stock > 0
                        ? () {
                            ref.read(cartProvider.notifier).addProduct(product);
                            context.push('/checkout');
                          }
                        : null,
                    icon: const Icon(Icons.flash_on_rounded),
                    label: const Text('Acheter'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Erreur: $e')),
      ),
    );
  }
  Widget _buildAvisHeader(BuildContext context, ThemeData theme, Product product) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Avis Clients', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              Text(
                'Découvrez ce que nos clients pensent de ce produit.', 
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Consumer(
          builder: (context, ref, child) {
            final auth = ref.watch(authProvider);
            if (!auth.isAuthenticated) {
              return OutlinedButton(
                onPressed: () => context.push('/connexion'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  side: const BorderSide(color: Color(0xFF6366F1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Se connecter', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              );
            }
            return ElevatedButton(
              onPressed: () => _showAddReviewDialog(context, ref, product.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Donner mon avis', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyReviews(BuildContext context, WidgetRef ref, String productId) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(Icons.rate_review_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('Aucun avis pour le moment', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(
            'Soyez le premier à donner votre avis sur ce produit !',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedSummary(ThemeData theme, Product product, int reviewCount, Map<int, int> distribution) {
    return Column(
      children: [
        // Average Rating Card
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Large Watermark Star
              Positioned(
                right: -20,
                top: 0,
                bottom: 0,
                child: Icon(Icons.star_rounded, size: 180, color: Colors.grey.shade50),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.averageRating.toStringAsFixed(0).replaceAll('.0', ''),
                      style: const TextStyle(fontSize: 80, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return Icon(
                          index < product.averageRating.floor() ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: Colors.amber,
                          size: 24,
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Basé sur $reviewCount avis',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Distribution Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RÉPARTITION DES NOTES',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey.shade400, letterSpacing: 1),
              ),
              const SizedBox(height: 20),
              ...List.generate(5, (index) {
                final star = 5 - index;
                final count = distribution[star] ?? 0;
                final percentage = reviewCount > 0 ? count / reviewCount : 0.0;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 25,
                        child: Row(
                          children: [
                            Text('$star', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 2),
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: percentage,
                            backgroundColor: Colors.grey.shade100,
                            valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)),
                            minHeight: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 20,
                        child: Text(
                          '$count',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(ThemeData theme, Review review) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    review.customerName.isNotEmpty ? review.customerName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.customerName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    Text(
                      _formatDate(review.createdAt),
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            review.title ?? '', // Use title if available
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
          Text(
            review.comment,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.thumb_up_alt_outlined, size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 6),
              Text(
                'Cet avis est utile (0)',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (review.adminReply != null || review.reply != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.reply_rounded, size: 14, color: Color(0xFF6366F1)),
                      const SizedBox(width: 4),
                      Text('Réponse du vendeur', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF6366F1))),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    review.adminReply ?? review.reply!, 
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d MMMM yyyy', 'fr_FR').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  void _showAddReviewDialog(BuildContext context, WidgetRef ref, String productId) {
    int rating = 5;
    final titleController = TextEditingController();
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Donner votre avis'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () => setState(() => rating = index + 1),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    hintText: 'Titre (ex: Super produit !)',
                    labelText: 'Titre',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    hintText: 'Votre commentaire...',
                    labelText: 'Commentaire',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || commentController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Veuillez remplir tous les champs')),
                  );
                  return;
                }
                final success = await ref.read(createReviewProvider)(
                  productId,
                  rating,
                  commentController.text,
                  titleController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Merci pour votre avis !' : 'Erreur lors de l\'envoi'),
                      backgroundColor: success ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Envoyer'),
            ),
          ],
        ),
      ),
    );
  }
}

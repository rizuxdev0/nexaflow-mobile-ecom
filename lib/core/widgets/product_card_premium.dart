import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nexaflow_mobile/core/models/models.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexaflow_mobile/features/cart/providers/cart_provider.dart';
import 'package:nexaflow_mobile/features/compare/providers/compare_provider.dart';

class ProductCardPremium extends ConsumerWidget {
  final Product product;
  final double width;
  final bool showCompare;
  final bool isFullWidth;
  
  const ProductCardPremium({
    super.key, 
    required this.product,
    this.width = 160,
    this.showCompare = true,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = const Color(0xFF6366F1);
    final inCompare = ref.watch(compareProvider.notifier).isSelected(product.id);
    
    return Container(
      width: isFullWidth ? double.infinity : width,
      margin: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () => context.push('/product/${product.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Container
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: product.mainImage != null
                          ? CachedNetworkImage(
                              imageUrl: product.mainImage!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(color: isDark ? Colors.white.withOpacity(0.03) : Colors.grey.shade100),
                              errorWidget: (context, url, error) => Container(
                                color: isDark ? Colors.white10 : Colors.grey.shade100,
                                child: const Icon(Icons.image_outlined, color: Colors.grey),
                              ),
                            )
                          : Container(
                              color: isDark ? Colors.white10 : Colors.grey.shade100,
                              child: const Icon(Icons.image_outlined, color: Colors.grey),
                            ),
                    ),
                  ),
                  
                  // Promo Badge
                  if (product.compareAtPrice != null && product.compareAtPrice! > product.price)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                        ),
                        child: Text(
                          '-${(((product.compareAtPrice! - product.price) / product.compareAtPrice!) * 100).toInt()}%',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  
                  // Compare Toggle
                  if (showCompare)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => ref.read(compareProvider.notifier).toggleProduct(product),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                          ),
                          child: Icon(
                            Icons.compare_arrows_rounded,
                            size: 18,
                            color: inCompare ? primaryColor : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${product.price.toStringAsFixed(0)} F',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          if (product.compareAtPrice != null && product.compareAtPrice! > product.price)
                            Text(
                              '${product.compareAtPrice!.toInt()} F',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 10,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                      // Add to Cart Fab Icon
                      GestureDetector(
                        onTap: () {
                          ref.read(cartProvider.notifier).addProduct(product);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product.name} ajouté au panier'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
                          ),
                          child: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

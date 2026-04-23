import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexaflow_mobile/core/api/shop_providers.dart';
import 'package:nexaflow_mobile/core/models/models.dart';
import 'package:nexaflow_mobile/features/auth/providers/auth_provider.dart';
import 'package:nexaflow_mobile/features/cart/providers/cart_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nexaflow_mobile/core/widgets/brand_logo.dart';
import 'package:nexaflow_mobile/core/widgets/shop_footer.dart';
import 'package:nexaflow_mobile/core/api/notification_providers.dart';
import 'package:nexaflow_mobile/core/widgets/product_card_premium.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuredAsync = ref.watch(productsProvider('pageSize=10'));
    final bestSellersAsync = ref.watch(productsProvider('pageSize=10'));
    final newArrivalsAsync = ref.watch(productsProvider('pageSize=10'));
    final categoriesAsync = ref.watch(categoriesProvider);
    final theme = Theme.of(context);
    final primaryColor = const Color(0xFF6366F1);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(productsProvider);
          ref.invalidate(categoriesProvider);
          ref.invalidate(bannersProvider);
          ref.invalidate(testimonialsProvider);
          // Wait for first one to finish or just delay a bit to show indicator
          await Future.delayed(const Duration(milliseconds: 500));
        },
        displacement: 100,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
          // Custom App Bar
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              centerTitle: false,
              title: const BrandLogo(size: 24, showSlogan: false),
            ),
            actions: [
              _buildAppBarIcon(
                context, 
                Icons.notifications_none_rounded, 
                () => context.push('/notifications'),
                count: ref.watch(unreadNotificationsCountProvider),
              ),
              _buildAppBarIcon(
                context, 
                Icons.shopping_cart_outlined, 
                () => context.go('/cart'),
                count: ref.watch(cartProvider).itemCount,
                color: primaryColor,
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: GestureDetector(
                onTap: () => context.go('/catalogue'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search_rounded, color: Colors.grey.shade500),
                      const SizedBox(width: 12),
                      Text('Que recherchez-vous ?', style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Categories horizontal
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 10),
              child: categoriesAsync.when(
                data: (categories) => SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 20),
                    itemBuilder: (_, idx) {
                      final cat = categories[idx];
                      return GestureDetector(
                        onTap: () => context.go('/catalogue?categoryId=${cat.id}'),
                        child: Column(
                          children: [
                            Container(
                              height: 64, width: 64,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [primaryColor.withOpacity(0.1), primaryColor.withOpacity(0.05)],
                                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(color: primaryColor.withOpacity(0.1)),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(50),
                                child: cat.image != null
                                  ? CachedNetworkImage(
                                      imageUrl: cat.image!,
                                      fit: BoxFit.cover,
                                      errorWidget: (context, url, error) => Center(
                                        child: Text(cat.name.substring(0, 1).toUpperCase(), 
                                          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 20)),
                                      ),
                                    )
                                  : Center(
                                      child: Text(cat.name.substring(0, 1).toUpperCase(), 
                                        style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 20)),
                                    ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(cat.name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                loading: () => const SizedBox(height: 100),
                error: (_, __) => const SizedBox(),
              ),
            ),
          ),

          // Hero Carousel (Banners)
          SliverToBoxAdapter(
            child: HeroCarousel(featuredAsync: featuredAsync),
          ),

          // Custom Pack Promotion
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(50)),
                            child: const Text('PROMO PACK', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(height: 8),
                          const Text('Créez votre Pack\nSur-Mesure', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, height: 1.1)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => context.push('/custom-pack'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('Découvrir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.auto_awesome, size: 80, color: Colors.white24),
                  ],
                ),
              ),
            ),
          ),

          // Best Sellers Title
          _buildSectionHeader(context, 'Meilleures ventes 🔥', () => context.go('/catalogue')),

          // Best Sellers horizontal list
          SliverToBoxAdapter(
            child: SizedBox(
              height: 280,
              child: bestSellersAsync.when(
                data: (products) => ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (_, idx) => ProductCardPremium(product: products[idx]),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox(),
              ),
            ),
          ),

          // New Arrivals Title
          _buildSectionHeader(context, 'Nouveautés ✨', () => context.go('/catalogue')),

          // New Arrivals List
          SliverToBoxAdapter(
            child: SizedBox(
              height: 280,
              child: newArrivalsAsync.when(
                data: (products) => ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (_, idx) => ProductCardPremium(product: products[idx]),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox(),
              ),
            ),
          ),

          // Testimonials Section
          const SliverToBoxAdapter(child: _TestimonialsSlider()),

          // Footer
          // const SliverToBoxAdapter(child: ShopFooter()),
        ],
      ),
    ),
  );
}

  Widget _buildAppBarIcon(BuildContext context, IconData icon, VoidCallback onPressed, {int count = 0, Color? color}) {
    return Stack(
      children: [
        IconButton(icon: Icon(icon), onPressed: onPressed),
        if (count > 0)
          Positioned(
            right: 8, top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: color ?? Colors.red, shape: BoxShape.circle),
              child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback onSeeAll) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            TextButton(
              onPressed: onSeeAll,
              child: const Row(
                children: [
                  Text('Touts voir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final dynamic product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return ProductCardPremium(product: product);
  }
}

class _PromotionBanner extends StatelessWidget {
  final BannerModel banner;
  final double height;
  const _PromotionBanner({required this.banner, this.height = 200});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bgColor = banner.bgColor != null ? _parseColor(banner.bgColor!) : const Color(0xFF6366F1);
    final textColor = banner.textColor != null ? _parseColor(banner.textColor!) : Colors.white;

    return GestureDetector(
      onTap: () {
        if (banner.ctaLink != null && banner.ctaLink!.startsWith('/')) {
          context.push(banner.ctaLink!);
        } else if (banner.id.isNotEmpty) {
          // Default to product detail if it's a product banner
          context.push('/product/${banner.id}');
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: bgColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                if (banner.image != null)
                  Positioned.fill(
                    child: CachedNetworkImage(
                      imageUrl: banner.image!,
                      fit: BoxFit.cover,
                      color: Colors.black.withOpacity(0.2),
                      colorBlendMode: BlendMode.darken,
                      errorWidget: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (banner.subtitle != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(50)),
                          child: Text(banner.subtitle!.toUpperCase(), style: TextStyle(color: textColor, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      Flexible(
                        child: Text(
                          banner.title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: textColor, 
                            fontWeight: FontWeight.w900, 
                            fontSize: 24,
                            height: 1.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (banner.ctaText != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(50)),
                          child: Text(
                            banner.ctaText!, 
                            style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _parseColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
      return const Color(0xFF6366F1);
    } catch (_) {
      return const Color(0xFF6366F1);
    }
  }
}

class _TestimonialsSlider extends ConsumerWidget {
  const _TestimonialsSlider();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final testimonialsAsync = ref.watch(testimonialsProvider);
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);

    return testimonialsAsync.when(
      data: (testimonials) {
        if (testimonials.isEmpty && !auth.isAuthenticated) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Avis clients 💬', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  if (auth.isAuthenticated)
                    TextButton(
                      onPressed: () => showModalBottomSheet(
                        context: context, isScrollControlled: true, 
                        backgroundColor: Colors.transparent,
                        builder: (context) => const _TestimonialFormBottomSheet(),
                      ),
                      child: const Text('Donner mon avis', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
            if (testimonials.isEmpty)
              _buildEmptyTestimonialsPlaceholder(context)
            else
              SizedBox(
                height: 180,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: testimonials.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) => _TestimonialCard(testimonial: testimonials[index]),
                ),
              ),
            const SizedBox(height: 32),
          ],
        );
      },
      loading: () => const SizedBox(height: 100),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildEmptyTestimonialsPlaceholder(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: const Center(child: Text('Soyez le premier à partager votre expérience !')),
    );
  }
}

class _TestimonialFormBottomSheet extends ConsumerStatefulWidget {
  const _TestimonialFormBottomSheet();
  @override
  ConsumerState<_TestimonialFormBottomSheet> createState() => _TestimonialFormBottomSheetState();
}

class _TestimonialFormBottomSheetState extends ConsumerState<_TestimonialFormBottomSheet> {
  final _contentCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  int _rating = 5;
  bool _submitting = false;

  @override
  void dispose() {
    _contentCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Votre avis compte 🌟', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) => IconButton(
              onPressed: () => setState(() => _rating = index + 1),
              icon: Icon(_rating > index ? Icons.star_rounded : Icons.star_outline_rounded, size: 40, color: const Color(0xFFF59E0B)),
            )),
          ),
          const SizedBox(height: 24),
          TextField(controller: _cityCtrl, decoration: const InputDecoration(labelText: 'Votre ville (Optionnel)')),
          const SizedBox(height: 16),
          TextField(controller: _contentCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Votre témoignage')),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Envoyer mon avis'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_contentCtrl.text.isEmpty) return;
    setState(() => _submitting = true);
    final success = await ref.read(submitTestimonialProvider)(_rating, _contentCtrl.text, _cityCtrl.text.isEmpty ? null : _cityCtrl.text);
    if (mounted) {
      setState(() => _submitting = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Merci ! Témoignage envoyé. ✨'), backgroundColor: Colors.green));
      }
    }
  }
}

class _TestimonialCard extends StatelessWidget {
  final Testimonial testimonial;
  const _TestimonialCard({required this.testimonial});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 18, child: Text(testimonial.customerName[0].toUpperCase())),
              const SizedBox(width: 12),
              Expanded(child: Text(testimonial.customerName, style: const TextStyle(fontWeight: FontWeight.bold))),
              Row(children: List.generate(5, (index) => Icon(Icons.star_rounded, size: 14, color: index < testimonial.rating ? const Color(0xFFF59E0B) : Colors.grey.shade300))),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: Text('"${testimonial.content}"', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13), maxLines: 4, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class HeroCarousel extends ConsumerStatefulWidget {
  final AsyncValue<List<Product>> featuredAsync;
  const HeroCarousel({super.key, required this.featuredAsync});

  @override
  ConsumerState<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends ConsumerState<HeroCarousel> {
  final PageController _pageController = PageController(initialPage: 1000);
  Timer? _timer;
  int _currentPage = 1000;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        _currentPage++;
        _pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 800), curve: Curves.easeInOutCubic);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(bannersProvider('hero'));
    return bannersAsync.when(
      data: (banners) {
        if (banners.isNotEmpty) {
          return SizedBox(
            height: 220,
            child: PageView.builder(
              controller: _pageController,
              itemBuilder: (context, index) => _PromotionBanner(banner: banners[index % banners.length]),
              onPageChanged: (page) => _currentPage = page,
            ),
          );
        }

        // Fallback to featured products if no banners are active
        return widget.featuredAsync.when(
          data: (products) {
            if (products.isEmpty) return const SizedBox();
            return SizedBox(
              height: 220,
              child: PageView.builder(
                controller: _pageController,
                itemBuilder: (context, index) {
                  final product = products[index % products.length];
                  return _PromotionBanner(
                    banner: BannerModel(
                      id: product.id,
                      title: product.name,
                      subtitle: 'Découvrez nos nouveautés',
                      image: product.mainImage,
                      ctaText: 'Voir le produit',
                      bgColor: '#6366F1', // Premium Indigo
                      textColor: '#FFFFFF',
                      position: 'hero',
                    ),
                  );
                },
                onPageChanged: (page) => _currentPage = page,
              ),
            );
          },
          loading: () => const SizedBox(height: 220),
          error: (_, __) => const SizedBox(),
        );
      },
      loading: () => const SizedBox(height: 220),
      error: (_, __) => const SizedBox(),
    );
  }
}

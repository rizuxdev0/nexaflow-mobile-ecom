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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuredAsync = ref.watch(productsProvider('pageSize=10'));
    final bestSellersAsync = ref.watch(productsProvider('pageSize=10'));
    final newArrivalsAsync = ref.watch(productsProvider('pageSize=10'));
    final categoriesAsync = ref.watch(categoriesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            pinned: true,
            expandedHeight: 80,
            title: const BrandLogo(size: 28, showSlogan: true),
            actions: [
              Consumer(builder: (_, ref, __) {
                final unreadCount = ref.watch(unreadNotificationsCountProvider);
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded),
                      onPressed: () => context.push('/notifications'),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8, top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                          child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                );
              }),
              IconButton(
                icon: const Icon(Icons.favorite_outline_rounded),
                onPressed: () => context.push('/favoris'),
              ),
              Consumer(builder: (_, ref, __) {
                final cartCount = ref.watch(cartProvider).itemCount;
                return Stack(
                  children: [
                    IconButton(icon: const Icon(Icons.shopping_cart_outlined), onPressed: () => context.go('/cart')),
                    if (cartCount > 0) Positioned(
                      right: 6, top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle),
                        child: Text('$cartCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(width: 8),
            ],
          ),

          // Categories horizontal chips
          SliverToBoxAdapter(
            child: SizedBox(
              height: 60,
              child: categoriesAsync.when(
                data: (categories) => ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, idx) {
                    final cat = categories[idx];
                    return ActionChip(
                      label: Text(cat.name),
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50), side: BorderSide(color: Colors.grey.shade200)),
                      onPressed: () => context.push('/catalogue?categoryId=${cat.id}'),
                    );
                  },
                ),
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),
            ),
          ),

          // Hero Carousel (Banners with Product Fallback)
          SliverToBoxAdapter(
            child: HeroCarousel(featuredAsync: featuredAsync),
          ),

          // Best Sellers Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Meilleures ventes 🔥', style: theme.textTheme.titleLarge),
                  TextButton(onPressed: () => context.go('/catalogue'), child: const Text('Tout voir')),
                ],
              ),
            ),
          ),

          // Best Sellers horizontal list
          SliverToBoxAdapter(
            child: SizedBox(
              height: 220,
              child: bestSellersAsync.when(
                data: (products) => ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, idx) {
                    final p = products[idx];
                    return _ProductCard(product: p);
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox(),
              ),
            ),
          ),

          // New Arrivals Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Nouveautés ✨', style: theme.textTheme.titleLarge),
                  TextButton(onPressed: () => context.go('/catalogue'), child: const Text('Tout voir')),
                ],
              ),
            ),
          ),

          // New Arrivals List
          SliverToBoxAdapter(
            child: SizedBox(
              height: 220,
              child: newArrivalsAsync.when(
                data: (products) => ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, idx) {
                    final p = products[idx];
                    return _ProductCard(product: p);
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox(),
              ),
            ),
          ),

          // Secondary Banner (Middle)
          SliverToBoxAdapter(
            child: Consumer(
              builder: (context, ref, child) {
                final bannersAsync = ref.watch(bannersProvider('middle'));
                return bannersAsync.when(
                  data: (banners) {
                    if (banners.isEmpty) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: _PromotionBanner(banner: banners.first, height: 160),
                    );
                  },
                  loading: () => const SizedBox(),
                  error: (_, __) => const SizedBox(),
                );
              },
            ),
          ),


          // Testimonials Section
          const SliverToBoxAdapter(
            child: _TestimonialsSlider(),
          ),

          // Footer
          const SliverToBoxAdapter(
            child: ShopFooter(),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final dynamic product;
  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 150,
      child: GestureDetector(
        onTap: () => context.push('/product/${product.id}'),
        child: Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: product.mainImage != null
                      ? CachedNetworkImage(
                          imageUrl: product.mainImage!,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey.shade100),
                          errorWidget: (context, url, error) => Container(color: const Color(0xFFF1F5F9), child: const Icon(Icons.image_outlined, color: Colors.grey)),
                        )
                      : Container(color: const Color(0xFFF1F5F9), child: const Icon(Icons.image_outlined, color: Colors.grey)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('${product.price.toStringAsFixed(0)} FCFA', style: const TextStyle(color: Color(0xFF6366F1), fontSize: 13, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

    return Padding(
      padding: const EdgeInsets.all(16),
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (banner.subtitle != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(50)),
                        child: Text(banner.subtitle!.toUpperCase(), style: TextStyle(color: textColor, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    Flexible(
                      child: Text(
                        banner.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: textColor, 
                          fontWeight: FontWeight.w900, 
                          height: 1.1,
                          fontSize: height < 180 ? 20 : 28,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (banner.description != null && height > 150) ...[
                      const SizedBox(height: 4),
                      Text(
                        banner.description!,
                        style: TextStyle(color: textColor.withOpacity(0.8), fontSize: height < 180 ? 11 : 13),
                        maxLines: height < 180 ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (banner.ctaText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(50)),
                        child: Text(
                          banner.ctaText!, 
                          style: TextStyle(
                            color: const Color(0xFF1E293B), 
                            fontWeight: FontWeight.bold, 
                            fontSize: height < 180 ? 11 : 13
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String colorStr) {
    try {
      if (colorStr.startsWith('#')) {
        return Color(int.parse(colorStr.replaceFirst('#', '0xFF')));
      }
      return Colors.blue;
    } catch (_) {
      return Colors.blue;
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
        // We show the section if there are testimonials OR if the user is logged in (to invite them to share)
        if (testimonials.isEmpty && !auth.isAuthenticated) return const SizedBox();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ce que disent nos clients 💬', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Votre satisfaction est notre plus grande réussite', 
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  if (auth.isAuthenticated)
                    TextButton.icon(
                      onPressed: () => _showTestimonialForm(context, ref),
                      icon: const Icon(Icons.add_comment_rounded, size: 18),
                      label: const Text('Donner mon avis', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(foregroundColor: const Color(0xFF6366F1)),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text('Soyez le premier à partager votre expérience !', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  void _showTestimonialForm(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _TestimonialFormBottomSheet(),
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
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Votre avis compte 🌟', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Partagez votre expérience avec la communauté NexaFlow.', 
            style: TextStyle(color: Colors.grey.shade500)),
          const SizedBox(height: 24),
          
          // Rating
          const Text('Comment évalueriez-vous notre service ?', 
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) => IconButton(
              onPressed: () => setState(() => _rating = index + 1),
              icon: Icon(
                _rating > index ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 40,
                color: _rating > index ? const Color(0xFFF59E0B) : Colors.grey.shade300,
              ),
            )),
          ),
          const SizedBox(height: 24),

          // City (Optional)
          TextField(
            controller: _cityCtrl,
            decoration: const InputDecoration(
              labelText: 'Votre ville (Optionnel)',
              hintText: 'Ex: Paris, Abidjan...',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 16),

          // Content
          TextField(
            controller: _contentCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Votre message',
              hintText: 'Racontez-nous votre expérience...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _submitting 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Envoyer mon témoignage', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_contentCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez écrire un message.')));
      return;
    }

    setState(() => _submitting = true);
    
    final success = await ref.read(submitTestimonialProvider)(
      _rating,
      _contentCtrl.text,
      _cityCtrl.text.isEmpty ? null : _cityCtrl.text,
    );

    if (mounted) {
      setState(() => _submitting = false);
      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Merci ! Votre témoignage a été envoyé pour modération. ✨'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de l\'envoi. Réessayez.')));
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
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                backgroundImage: testimonial.avatar != null ? NetworkImage(testimonial.avatar!) : null,
                child: testimonial.avatar == null 
                  ? Text(testimonial.customerName[0].toUpperCase(), 
                      style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 12))
                  : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(testimonial.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    if (testimonial.city != null)
                      Text(testimonial.city!, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) => Icon(
                  Icons.star_rounded, 
                  size: 14, 
                  color: index < testimonial.rating ? const Color(0xFFF59E0B) : Colors.grey.shade300
                )),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Text(
              '"${testimonial.content}"',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.white70 : Colors.grey.shade700,
                height: 1.4,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
  int _currentDuration = 5;

  @override
  void initState() {
    super.initState();
    // Initial start with default, will be updated when config loads
    _startAutoScroll(_currentDuration);
  }

  void _startAutoScroll(int seconds) {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: seconds), (timer) {
      if (_pageController.hasClients) {
        _currentPage++;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
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
    final configAsync = ref.watch(storeConfigProvider);

    // Update timer if duration changed in config
    configAsync.whenData((config) {
      if (config != null && config.heroSlideDuration != _currentDuration) {
        _currentDuration = config.heroSlideDuration;
        _startAutoScroll(_currentDuration);
      }
    });

    return bannersAsync.when(
      data: (banners) {
        if (banners.isNotEmpty) {
          return SizedBox(
            height: 220,
            child: PageView.builder(
              controller: _pageController,
              itemBuilder: (context, index) {
                final banner = banners[index % banners.length];
                return _PromotionBanner(banner: banner);
              },
              onPageChanged: (page) => _currentPage = page,
            ),
          );
        }

        // Fallback to Featured Products
        return widget.featuredAsync.when(
          data: (products) {
            if (products.isEmpty) return const SizedBox();
            return SizedBox(
              height: 230,
              child: PageView.builder(
                controller: _pageController,
                itemBuilder: (context, index) {
                  final p = products[index % products.length];
                  return _buildProductHero(context, p);
                },
                onPageChanged: (page) => _currentPage = page,
              ),
            );
          },
          loading: () => _buildShimmerLoader(),
          error: (_, __) => const SizedBox(),
        );
      },
      loading: () => _buildShimmerLoader(),
      error: (_, __) => const SizedBox(),
    );
  }

  Widget _buildProductHero(BuildContext context, Product p) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () => context.push('/product/${p.id}'),
        borderRadius: BorderRadius.circular(24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Background Gradient
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                ),
              ),
              // Background Image with Error Handling
              if (p.mainImage != null)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.4,
                    child: CachedNetworkImage(
                      imageUrl: p.mainImage!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                ),
              // Content
              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(50)),
                child: const Text('PRODUIT VEDETTE', style: TextStyle(color: Color(0xFF6366F1), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              Expanded(child: Text(p.name, style: theme.textTheme.displaySmall?.copyWith(color: Colors.white, height: 1.2, fontWeight: FontWeight.w900), maxLines: 2)),
              Row(
                children: [
                  Text('${p.price.toStringAsFixed(0)} F', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(50)),
                    child: const Text('Acheter →', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  ),
),
);
}

  Widget _buildShimmerLoader() {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(24)),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

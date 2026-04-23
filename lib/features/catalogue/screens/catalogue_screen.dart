import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:nexaflow_mobile/core/api/shop_providers.dart';
import 'package:nexaflow_mobile/core/models/models.dart';
import 'package:nexaflow_mobile/core/widgets/shop_footer.dart';
import 'package:nexaflow_mobile/features/compare/providers/compare_provider.dart';
import 'package:nexaflow_mobile/core/widgets/product_card_premium.dart';

class CatalogueScreen extends ConsumerStatefulWidget {
  final String? categoryId;
  const CatalogueScreen({super.key, this.categoryId});

  @override
  ConsumerState<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends ConsumerState<CatalogueScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String _search = '';
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId;
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(CatalogueScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.categoryId != oldWidget.categoryId) {
      setState(() {
        _selectedCategoryId = widget.categoryId;
      });
    }
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      final params = _getParams();
      final queryStr = Uri(queryParameters: params).query;
      ref.read(productsNotifierProvider(queryStr).notifier).fetchNextPage();
    }
  }

  Map<String, String> _getParams() {
    return {
      if (_search.isNotEmpty) 'search': _search,
      if (_selectedCategoryId != null) 'categoryId': _selectedCategoryId!,
    };
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final params = _getParams();
    final queryStr = Uri(queryParameters: params).query;
    final productsAsync = ref.watch(productsNotifierProvider(queryStr));
    final categoriesAsync = ref.watch(categoriesProvider);
    final compareList = ref.watch(compareProvider);
    final theme = Theme.of(context);
    final primaryColor = const Color(0xFF6366F1);

    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async {
              final params = _getParams();
              final queryStr = Uri(queryParameters: params).query;
              await ref.read(productsNotifierProvider(queryStr).notifier).fetchNextPage(isRefresh: true);
            },
            displacement: 100, // To avoid collision with potential top elements
            child: CustomScrollView(
              controller: _scrollCtrl,
              physics: const BouncingScrollPhysics(),
              slivers: [
              // Custom Header
              SliverAppBar(
                pinned: true,
                floating: true,
                expandedHeight: 140,
                backgroundColor: theme.scaffoldBackgroundColor,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (v) => setState(() => _search = v),
                          decoration: InputDecoration(
                            hintText: 'Rechercher un produit...',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _search.isNotEmpty
                                ? IconButton(icon: const Icon(Icons.close_rounded), onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _search = '');
                                  })
                                : null,
                            filled: true,
                            fillColor: theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                title: const Text('Catalogue', style: TextStyle(fontWeight: FontWeight.w900)),
                centerTitle: false,
              ),

              // Categories filter
              SliverToBoxAdapter(
                child: categoriesAsync.when(
                  data: (cats) => SizedBox(
                    height: 50,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: cats.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, idx) {
                        final isSelected = idx == 0 ? _selectedCategoryId == null : _selectedCategoryId == cats[idx - 1].id;
                        final label = idx == 0 ? 'Tout' : cats[idx - 1].name;
                        
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategoryId = idx == 0 ? null : cats[idx - 1].id),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? primaryColor : (theme.brightness == Brightness.dark ? Colors.white.withOpacity(0.05) : Colors.white),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(color: isSelected ? primaryColor : Colors.grey.shade200),
                              boxShadow: isSelected ? [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (idx > 0 && cats[idx - 1].image != null)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          image: NetworkImage(cats[idx - 1].image!),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  )
                                else if (idx > 0)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: Icon(Icons.category_outlined, size: 14, color: Colors.grey),
                                  ),
                                Center(
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : (theme.brightness == Brightness.dark ? Colors.white70 : Colors.grey.shade700),
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  loading: () => const SizedBox(height: 50),
                  error: (_, __) => const SizedBox(height: 50),
                ),
              ),

              // Products grid
              productsAsync.when(
                data: (paginated) {
                  final products = paginated.items;
                  if (products.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            const Text('Aucun produit trouvé', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    );
                  }
                  return SliverMainAxisGroup(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.all(20),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 24,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, idx) => ProductCardPremium(product: products[idx]),
                            childCount: products.length,
                          ),
                        ),
                      ),
                      if (paginated.hasNextPage)
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, childAspectRatio: 0.65, crossAxisSpacing: 20, mainAxisSpacing: 24,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, idx) => _buildSkeleton(),
                      childCount: 6,
                    ),
                  ),
                ),
                error: (e, _) => SliverFillRemaining(child: Center(child: Text('Erreur: $e'))),
              ),

              // Footer
              // const SliverToBoxAdapter(child: ShopFooter()),
              const SliverToBoxAdapter(child: SizedBox(height: 100)), // Space for compare bar
            ],
          ),
        ),

          // Comparison Bar
          if (compareList.isNotEmpty)
            Positioned(
              left: 20, right: 20, bottom: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [primaryColor, primaryColor.withOpacity(0.8)]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.compare_arrows_rounded, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${compareList.length} produit${compareList.length > 1 ? 's' : ''}', 
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                          const Text('à comparer', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref.read(compareProvider.notifier).clearGroup(),
                      child: const Text('Vider', style: TextStyle(color: Colors.white70)),
                    ),
                    ElevatedButton(
                      onPressed: () => context.push('/compare'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, foregroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        minimumSize: const Size(0, 40),
                      ),
                      child: const Text('Comparer', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() => Shimmer.fromColors(
    baseColor: Colors.grey.shade200,
    highlightColor: Colors.grey.shade100,
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/models.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../models/loyalty.dart';

class PaginatedProducts {
  final List<Product> items;
  final int total;
  final int totalPages;
  final int currentPage;
  final bool hasNextPage;

  PaginatedProducts({
    required this.items,
    required this.total,
    required this.totalPages,
    required this.currentPage,
    required this.hasNextPage,
  });

  factory PaginatedProducts.empty() => PaginatedProducts(
    items: [],
    total: 0,
    totalPages: 0,
    currentPage: 1,
    hasNextPage: false,
  );
}

/// Products Notifier to manage pagination state
class ProductsNotifier extends StateNotifier<AsyncValue<PaginatedProducts>> {
  final Ref ref;
  final String queryStr;
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMore = true;
  bool _isFetching = false;
  List<Product> _allProducts = [];

  ProductsNotifier(this.ref, this.queryStr) : super(const AsyncValue.loading());

  Future<void> fetchNextPage({bool isRefresh = false}) async {
    if (_isFetching || (!_hasMore && !isRefresh)) return;

    if (isRefresh) {
      _currentPage = 1;
      _hasMore = true;
      _allProducts = [];
    }

    _isFetching = true;

    if (_currentPage == 1 && !isRefresh) {
      state = const AsyncValue.loading();
    }

    final api = ref.read(apiClientProvider);
    try {
      final params = queryStr.isEmpty ? {} : Uri.splitQueryString(queryStr);
      final response = await api.get('/shop/products', params: {
        ...params,
        'page': _currentPage,
        'pageSize': params.containsKey('pageSize') ? int.tryParse(params['pageSize'].toString()) ?? _pageSize : _pageSize,
      });

      final data = response.data;
      if (data is Map) {
        final content = data['data']; 
        if (content is Map && content.containsKey('data')) {
          final newItems = (content['data'] as List).map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
          final total = content['total'] ?? 0;
          final totalPages = content['totalPages'] ?? 1;
          
          // Avoid duplicates by checking IDs
          final existingIds = _allProducts.map((p) => p.id).toSet();
          final uniqueNewItems = newItems.where((p) => !existingIds.contains(p.id)).toList();

          _allProducts = isRefresh ? newItems : [..._allProducts, ...uniqueNewItems];
          _hasMore = _currentPage < totalPages;
          
          if (uniqueNewItems.isNotEmpty || isRefresh) {
            _currentPage++;
          }

          state = AsyncValue.data(PaginatedProducts(
            items: _allProducts,
            total: total,
            totalPages: totalPages,
            currentPage: _currentPage - 1,
            hasNextPage: _hasMore,
          ));
        }
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    } finally {
      _isFetching = false;
    }
  }
}

final productsNotifierProvider = StateNotifierProvider.family<ProductsNotifier, AsyncValue<PaginatedProducts>, String>((ref, queryStr) {
  final notifier = ProductsNotifier(ref, queryStr);
  notifier.fetchNextPage();
  return notifier;
});

/// Standard Products provider for backward compatibility
final productsProvider = Provider.family<AsyncValue<List<Product>>, String>((ref, queryStr) {
  return ref.watch(productsNotifierProvider(queryStr)).whenData((p) => p.items);
});

/// Single product provider
final productDetailProvider = FutureProvider.family<Product?, String>((ref, id) async {
  final api = ref.watch(apiClientProvider);
  try {
    final response = await api.get('/shop/products/$id');
    final data = response.data;
    final json = data is Map ? (data['data'] ?? data) : data;
    return Product.fromJson(json as Map<String, dynamic>);
  } catch (_) {
    return null;
  }
});

/// Categories provider
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final response = await api.get('/shop/categories');
    final data = response.data;
    List<dynamic> list;
    if (data is Map) {
      list = (data['data'] ?? data['categories'] ?? []) as List<dynamic>;
    } else if (data is List) {
      list = data;
    } else {
      list = [];
    }
    return list.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();
  } catch (_) {
    return [];
  }
});


/// Orders provider
final ordersProvider = FutureProvider<List<Order>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final auth = ref.watch(authProvider);
  final customerId = auth.customer?.id;
  
  if (customerId == null) return [];

  try {
    final response = await api.get('/orders', params: {'source': 'ecommerce'});
    final rawData = response.data;
    
    List<dynamic> list = [];
    
    if (rawData is Map) {
      // Le backend enveloppe souvent dans { "data": ... }
      final data = rawData['data'];
      if (data is List) {
        list = data;
      } else if (data is Map) {
        // Cas de la pagination : { "data": { "data": [...], "meta": ... } }
        list = (data['data'] ?? data['orders'] ?? []) as List<dynamic>;
      }
    } else if (rawData is List) {
      list = rawData;
    }

    return list.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
  } catch (e) {
    debugPrint("Erreur chargement commandes detail: $e");
    return [];
  }
});


/// Reviews provider for a product
final productReviewsProvider = FutureProvider.family<List<Review>, String>((ref, productId) async {
  final api = ref.watch(apiClientProvider);
  try {
    final response = await api.get('/reviews/product/$productId');
    final data = response.data;
    List<dynamic> list = [];
    
    if (data is Map) {
      final content = data['data']; // Unwrap standard response
      if (content is Map && content.containsKey('data')) {
        // PaginatedResponse format: { data: { data: [...], total: ... } }
        list = content['data'] as List<dynamic>;
      } else if (content is List) {
        list = content;
      } else if (data['reviews'] is List) {
        list = data['reviews'] as List<dynamic>;
      } else if (content == null) {
        list = [];
      } else {
        // Maybe it's directly in 'data'
        list = (data['data'] ?? []) as List<dynamic>;
      }
    } else if (data is List) {
      list = data;
    }
    
    return list.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
  } catch (e) {
    debugPrint("Erreur chargement avis: $e");
    return [];
  }
});

/// Add review function
final createReviewProvider = Provider((ref) {
  return (String productId, int rating, String comment, String title) async {
    final api = ref.read(apiClientProvider);
    final auth = ref.read(authProvider);
    
    if (!auth.isAuthenticated) return false;

    try {
      final response = await api.post('/reviews', data: {
        'productId': productId,
        'rating': rating,
        'comment': comment,
        'title': title,
        'customerId': auth.customer!.id,
        'customerName': auth.customer!.fullName,
      });
      
      // Invalidate reviews to refresh
      ref.invalidate(productReviewsProvider(productId));
      return response.statusCode == 201;
    } catch (e) {
      debugPrint("Erreur creation avis: $e");
      return false;
    }
  };
});

/// Banners provider
final bannersProvider = FutureProvider.family<List<BannerModel>, String?>((ref, position) async {
  final api = ref.watch(apiClientProvider);
  try {
    final params = position != null ? {'position': position} : null;
    final response = await api.get('/banners/active', params: params);
    final data = response.data;
    List<dynamic> list = [];
    if (data is Map) {
      list = (data['data'] ?? []) as List<dynamic>;
    } else if (data is List) {
      list = data;
    }
    return list.map((e) => BannerModel.fromJson(e as Map<String, dynamic>)).toList();
  } catch (e) {
    debugPrint("Erreur chargement bannières: $e");
    return [];
  }
});

/// Store Config provider
final storeConfigProvider = FutureProvider<StoreConfig?>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final response = await api.get('/store-config');
    return StoreConfig.fromJson(response.data as Map<String, dynamic>);
  } catch (e) {
    debugPrint("Erreur chargement store config: $e");
    return null;
  }
});

/// Testimonials provider
final testimonialsProvider = FutureProvider<List<Testimonial>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final response = await api.get('/testimonials/active');
    final data = response.data;
    List<dynamic> list = [];
    if (data is Map && data.containsKey('data')) {
      list = data['data'] as List<dynamic>;
    } else if (data is List) {
      list = data;
    }
    return list.map((e) => Testimonial.fromJson(e as Map<String, dynamic>)).toList();
  } catch (e) {
    debugPrint("Erreur chargement testimonials: $e");
    return [];
  }
});

/// Submit testimonial function
final submitTestimonialProvider = Provider((ref) {
  return (int rating, String content, String? city) async {
    final api = ref.read(apiClientProvider);
    final auth = ref.read(authProvider);
    
    if (!auth.isAuthenticated) return false;

    try {
      final response = await api.post('/testimonials', data: {
        'customerName': auth.customer!.fullName,
        'rating': rating,
        'content': content,
        'city': city,
      });
      
      return response.statusCode == 201;
    } catch (e) {
      debugPrint("Erreur soumission témoignage: $e");
      return false;
    }
  };
});

/// Loyalty Rewards
final loyaltyRewardsProvider = FutureProvider<List<LoyaltyReward>>((ref) async {
  final api = ref.watch(apiClientProvider);
  try {
    final response = await api.get('/loyalty/rewards');
    final data = response.data;
    List<dynamic> list = [];
    if (data is Map) {
      final content = data['data'];
      if (content is Map && content.containsKey('data')) {
        list = content['data'] as List<dynamic>;
      } else if (content is List) {
        list = content;
      } else {
        list = (data['data'] ?? []) as List<dynamic>;
      }
    } else if (data is List) {
      list = data;
    }
    return list.map((e) => LoyaltyReward.fromJson(e as Map<String, dynamic>)).toList();
  } catch (e) {
    debugPrint("Erreur chargement rewards: $e");
    return [];
  }
});

/// Loyalty Transactions
final loyaltyTransactionsProvider = FutureProvider<List<LoyaltyTransaction>>((ref) async {
  final api = ref.watch(apiClientProvider);
  final auth = ref.watch(authProvider);
  final customerId = auth.customer?.id;
  if (customerId == null) return [];

  try {
    final response = await api.get('/loyalty/transactions', params: {'customerId': customerId});
    final data = response.data;
    List<dynamic> list = [];
    if (data is Map) {
      final content = data['data'];
      if (content is Map && content.containsKey('data')) {
        list = content['data'] as List<dynamic>;
      } else if (content is List) {
        list = content;
      } else {
        list = (data['data'] ?? []) as List<dynamic>;
      }
    } else if (data is List) {
      list = data;
    }
    return list.map((e) => LoyaltyTransaction.fromJson(e as Map<String, dynamic>)).toList();
  } catch (e) {
    debugPrint("Erreur chargement loyalty transactions: $e");
    return [];
  }
});

/// Redeem Loyalty Reward
final redeemRewardProvider = FutureProvider.family<bool, String>((ref, rewardId) async {
  final api = ref.watch(apiClientProvider);
  final auth = ref.watch(authProvider);
  final customerId = auth.customer?.id;
  if (customerId == null) throw Exception('Utilisateur non connecté');

  try {
    await api.post('/loyalty/redeem', data: {
      'customerId': customerId,
      'rewardId': rewardId,
    });
    ref.invalidate(loyaltyTransactionsProvider);
    ref.invalidate(authProvider); 
    return true;
  } catch (e) {
    debugPrint("Erreur redeem reward: $e");
    throw Exception('Impossible d\'échanger cette récompense');
  }
});

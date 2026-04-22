import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/models.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../models/loyalty.dart';

/// Products provider
final productsProvider = FutureProvider.family<List<Product>, String>((ref, queryStr) async {
  final api = ref.watch(apiClientProvider);
  try {
    final params = queryStr.isEmpty ? null : Uri.splitQueryString(queryStr);
    final response = await api.get('/shop/products', params: params);
    final data = response.data;
    List<dynamic> list = [];
    if (data is Map) {
      final content = data['data']; // Unwrap standard NestJS response
      if (content is Map && content.containsKey('data')) {
        // PaginatedResponse format
        list = content['data'] as List<dynamic>;
      } else if (content is List) {
        list = content;
      } else if (data['products'] is List) {
        list = data['products'] as List<dynamic>;
      }
    } else if (data is List) {
      list = data;
    }
    return list.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  } catch (e) {
    debugPrint("Erreur chargement produits: $e");
    return [];
  }
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
    if (data is Map && data.containsKey('data')) {
      list = data['data'] as List<dynamic>;
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
    if (data is Map && data.containsKey('data')) {
      list = data['data'] as List<dynamic>;
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

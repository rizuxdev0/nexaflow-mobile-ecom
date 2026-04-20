import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexaflow_mobile/core/models/subscription.dart';
import 'package:nexaflow_mobile/core/api/api_client.dart';

final subscriptionServiceProvider = Provider((ref) => SubscriptionService(ref.watch(apiClientProvider)));

final publicPlansProvider = FutureProvider<List<SubscriptionPlan>>((ref) async {
  return ref.watch(subscriptionServiceProvider).getPublicPlans();
});

final mySubscriptionProvider = FutureProvider<UserSubscription?>((ref) async {
  return ref.watch(subscriptionServiceProvider).getMySubscription();
});

class SubscriptionService {
  final ApiClient _api;
  SubscriptionService(this._api);

  Future<List<SubscriptionPlan>> getPublicPlans() async {
    try {
      final response = await _api.get('/subscriptions/plans');
      if (response.data is List) {
        return (response.data as List).map((e) => SubscriptionPlan.fromJson(e)).toList();
      }
    } catch (e) {
      print('❌ Error fetching plans: $e');
    }
    return [];
  }

  Future<UserSubscription?> getMySubscription() async {
    // Current backend stores subscription in User object
    // We could fetch current user profile here if needed
    return null;
  }

  Future<void> subscribe(String planId, String paymentMethod) async {
    await _api.post('/subscriptions/subscribe/$planId', data: {
      'paymentMethod': paymentMethod,
    });
  }
}

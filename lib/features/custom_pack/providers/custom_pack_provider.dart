import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexaflow_mobile/core/api/api_client.dart';
import 'package:nexaflow_mobile/core/models/models.dart';
import 'package:nexaflow_mobile/features/auth/providers/auth_provider.dart';

class CustomPackItem {
  final Product product;
  final int quantity;

  CustomPackItem({required this.product, this.quantity = 1});

  CustomPackItem copyWith({int? quantity}) {
    return CustomPackItem(
      product: product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CustomPackDraftNotifier extends StateNotifier<List<CustomPackItem>> {
  CustomPackDraftNotifier() : super([]);

  void addProduct(Product product) {
    final existing = state.indexWhere((p) => p.product.id == product.id);
    if (existing >= 0) {
      final newState = [...state];
      newState[existing] = newState[existing].copyWith(quantity: newState[existing].quantity + 1);
      state = newState;
    } else {
      state = [...state, CustomPackItem(product: product)];
    }
  }

  void removeProduct(String productId) {
    state = state.where((p) => p.product.id != productId).toList();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeProduct(productId);
      return;
    }
    final newState = [...state];
    final index = newState.indexWhere((p) => p.product.id == productId);
    if (index >= 0) {
      newState[index] = newState[index].copyWith(quantity: quantity);
      state = newState;
    }
  }

  void clearPack() {
    state = [];
  }
}

final customPackDraftProvider = StateNotifierProvider<CustomPackDraftNotifier, List<CustomPackItem>>((ref) {
  return CustomPackDraftNotifier();
});

class PackHistoryNotifier extends StateNotifier<AsyncValue<List<CustomPackRequest>>> {
  final ApiClient _api;
  final String? _customerId;
  final String? _customerName;
  final String? _customerEmail;

  PackHistoryNotifier(this._api, this._customerId, this._customerName, this._customerEmail) : super(const AsyncValue.loading()) {
    if (_customerId != null) {
      fetchHistory();
    }
  }

  Future<void> fetchHistory() async {
    if (_customerId == null) return;
    state = const AsyncValue.loading();
    try {
      final response = await _api.get('/custom-packs/requests', params: {'customerId': _customerId});
      final responseData = response.data as Map<String, dynamic>;
      
      // The interceptor wraps in 'data', and the controller result with pagination also has 'data'
      final outerData = responseData['data'] as Map<String, dynamic>;
      final List<dynamic> requestsRaw = outerData['data'] ?? [];
      
      final list = requestsRaw.map((e) => CustomPackRequest.fromJson(e as Map<String, dynamic>)).toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> submitRequest(List<CustomPackItem> draftItems, {String? note}) async {
    if (_customerId == null) return false;
    
    try {
      double originalTotal = draftItems.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
      int totalItems = draftItems.fold<int>(0, (sum, item) => sum + item.quantity);
      
      String discountType = 'percentage';
      double discountValue = 0;
      if (totalItems >= 4) discountValue = 10;
      else if (totalItems >= 2) discountValue = 5;

      double discountedTotal = originalTotal;
      if (discountType == 'percentage') {
        discountedTotal = originalTotal * (1 - discountValue / 100);
      }
      double savings = originalTotal - discountedTotal;

      final payload = {
        'customerId': _customerId,
        'customerName': _customerName,
        'customerEmail': _customerEmail,
        'items': draftItems.map((it) => {
          'productId': it.product.id,
          'productName': it.product.name,
          'sku': it.product.sku,
          'image': it.product.mainImage,
          'quantity': it.quantity,
          'unitPrice': it.product.price,
        }).toList(),
        'originalTotal': originalTotal,
        'discountType': discountType,
        'discountValue': discountValue,
        'discountedTotal': discountedTotal,
        'savings': savings,
        'customerNote': note,
      };

      await _api.post('/custom-packs/requests', data: payload);
      await fetchHistory();
      return true;
    } catch (e) {
      debugPrint("Error submitting pack request: $e");
      return false;
    }
  }
}

final packHistoryProvider = StateNotifierProvider<PackHistoryNotifier, AsyncValue<List<CustomPackRequest>>>((ref) {
  final api = ref.watch(apiClientProvider);
  final auth = ref.watch(authProvider);
  return PackHistoryNotifier(
    api, 
    auth.customer?.id, 
    auth.customer?.fullName, 
    auth.customer?.email
  );
});

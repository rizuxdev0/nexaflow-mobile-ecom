import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexaflow_mobile/core/models/models.dart';

class CompareNotifier extends StateNotifier<List<Product>> {
  CompareNotifier() : super([]);

  // Max 3 products to compare for readability on mobile
  static const int maxProducts = 3;

  void toggleProduct(Product product) {
    if (state.any((p) => p.id == product.id)) {
      state = state.where((p) => p.id != product.id).toList();
    } else {
      if (state.length < maxProducts) {
        state = [...state, product];
      }
    }
  }

  void removeProduct(String productId) {
    state = state.where((p) => p.id != productId).toList();
  }

  void clearGroup() {
    state = [];
  }

  bool isSelected(String productId) => state.any((p) => p.id == productId);
}

final compareProvider = StateNotifierProvider<CompareNotifier, List<Product>>((ref) {
  return CompareNotifier();
});

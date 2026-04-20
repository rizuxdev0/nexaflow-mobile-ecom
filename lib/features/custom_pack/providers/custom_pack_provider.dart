import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexaflow_mobile/core/models/models.dart';
import 'package:uuid/uuid.dart';

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

class CustomPack {
  final String id;
  final String name;
  final List<CustomPackItem> items;
  final DateTime createdAt;

  CustomPack({
    required this.id,
    required this.name,
    required this.items,
    required this.createdAt,
  });

  double get totalPrice {
    return items.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
  }

  double get discountAmount {
    // Basic discount logic: 5% for 2+ items, 10% for 4+ items
    final totalItems = items.fold<int>(0, (sum, item) => sum + item.quantity);
    if (totalItems >= 4) return totalPrice * 0.10;
    if (totalItems >= 2) return totalPrice * 0.05;
    return 0;
  }

  double get finalPrice => totalPrice - discountAmount;
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

class PackHistoryNotifier extends StateNotifier<List<CustomPack>> {
  PackHistoryNotifier() : super([]);

  void savePack(String name, List<CustomPackItem> items) {
    final pack = CustomPack(
      id: const Uuid().v4(),
      name: name,
      items: items,
      createdAt: DateTime.now(),
    );
    state = [pack, ...state];
  }
}

final packHistoryProvider = StateNotifierProvider<PackHistoryNotifier, List<CustomPack>>((ref) {
  return PackHistoryNotifier();
});

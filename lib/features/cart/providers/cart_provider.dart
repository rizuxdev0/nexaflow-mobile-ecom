import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexaflow_mobile/core/api/api_client.dart';
import 'package:nexaflow_mobile/core/models/models.dart';

/// Cart state
class CartState {
  final List<CartItem> items;

  const CartState({this.items = const []});

  double get subtotal => items.fold(0, (sum, i) => sum + i.total);
  int get itemCount => items.fold(0, (sum, i) => sum + i.quantity);

  CartState copyWith({List<CartItem>? items}) =>
      CartState(items: items ?? this.items);
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addProduct(Product product, {int quantity = 1}) {
    final existing = state.items.indexWhere((i) => i.product.id == product.id);
    if (existing >= 0) {
      final updated = List<CartItem>.from(state.items);
      updated[existing].quantity += quantity;
      state = state.copyWith(items: updated);
    } else {
      state = state.copyWith(items: [...state.items, CartItem(product: product, quantity: quantity)]);
    }
  }

  void remove(String productId) {
    state = state.copyWith(items: state.items.where((i) => i.product.id != productId).toList());
  }

  void increment(String productId) {
    final updated = List<CartItem>.from(state.items);
    final idx = updated.indexWhere((i) => i.product.id == productId);
    if (idx >= 0) updated[idx].quantity++;
    state = state.copyWith(items: updated);
  }

  void decrement(String productId) {
    final updated = List<CartItem>.from(state.items);
    final idx = updated.indexWhere((i) => i.product.id == productId);
    if (idx >= 0) {
      if (updated[idx].quantity <= 1) {
        updated.removeAt(idx);
      } else {
        updated[idx].quantity--;
      }
    }
    state = state.copyWith(items: updated);
  }

  void clear() => state = const CartState();
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) => CartNotifier());

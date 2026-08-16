import '../../domain/entities/cart_item.dart';

abstract class CartLocalDataSource {
  Future<List<CartItem>> getCartItems();
  Future<List<CartItem>> addCartItem(CartItem item);
  Future<List<CartItem>> removeCartItem(String cartItemId);
  Future<List<CartItem>> updateCartItemQuantity(String cartItemId, int quantity);
  Future<void> clearCart();
}

class CartLocalDataSourceImpl implements CartLocalDataSource {
  final List<CartItem> _cartItems = [];

  @override
  Future<List<CartItem>> getCartItems() async {
    return List.from(_cartItems);
  }

  @override
  Future<List<CartItem>> addCartItem(CartItem item) async {
    final existingIndex = _cartItems.indexWhere((element) => element.id == item.id);
    if (existingIndex >= 0) {
      final existingItem = _cartItems[existingIndex];
      _cartItems[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + item.quantity,
      );
    } else {
      _cartItems.add(item);
    }
    return List.from(_cartItems);
  }

  @override
  Future<List<CartItem>> removeCartItem(String cartItemId) async {
    _cartItems.removeWhere((element) => element.id == cartItemId);
    return List.from(_cartItems);
  }

  @override
  Future<List<CartItem>> updateCartItemQuantity(String cartItemId, int quantity) async {
    final index = _cartItems.indexWhere((element) => element.id == cartItemId);
    if (index >= 0) {
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index] = _cartItems[index].copyWith(quantity: quantity);
      }
    }
    return List.from(_cartItems);
  }

  @override
  Future<void> clearCart() async {
    _cartItems.clear();
  }
}

import '../entities/cart_item.dart';

abstract class CartRepository {
  Future<List<CartItem>> getCartItems();
  Future<List<CartItem>> addCartItem(CartItem item);
  Future<List<CartItem>> removeCartItem(String cartItemId);
  Future<List<CartItem>> updateCartItemQuantity(String cartItemId, int quantity);
  Future<void> clearCart();
}

import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_local_datasource.dart';

class CartRepositoryImpl implements CartRepository {
  final CartLocalDataSource localDataSource;

  CartRepositoryImpl({required this.localDataSource});

  @override
  Future<List<CartItem>> getCartItems() {
    return localDataSource.getCartItems();
  }

  @override
  Future<List<CartItem>> addCartItem(CartItem item) {
    return localDataSource.addCartItem(item);
  }

  @override
  Future<List<CartItem>> removeCartItem(String cartItemId) {
    return localDataSource.removeCartItem(cartItemId);
  }

  @override
  Future<List<CartItem>> updateCartItemQuantity(String cartItemId, int quantity) {
    return localDataSource.updateCartItemQuantity(cartItemId, quantity);
  }

  @override
  Future<void> clearCart() {
    return localDataSource.clearCart();
  }
}

import '../entities/cart_item.dart';
import '../repositories/cart_repository.dart';

class RemoveItemFromCartUseCase {
  final CartRepository repository;

  RemoveItemFromCartUseCase(this.repository);

  Future<List<CartItem>> execute(String cartItemId) {
    return repository.removeCartItem(cartItemId);
  }
}

import '../entities/cart_item.dart';
import '../repositories/cart_repository.dart';

class UpdateCartItemUseCase {
  final CartRepository repository;

  UpdateCartItemUseCase(this.repository);

  Future<List<CartItem>> execute(String cartItemId, int quantity) {
    return repository.updateCartItemQuantity(cartItemId, quantity);
  }
}

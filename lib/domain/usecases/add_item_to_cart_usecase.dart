import '../entities/cart_item.dart';
import '../repositories/cart_repository.dart';

class AddItemToCartUseCase {
  final CartRepository repository;

  AddItemToCartUseCase(this.repository);

  Future<List<CartItem>> execute(CartItem item) {
    return repository.addCartItem(item);
  }
}

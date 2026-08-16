import '../entities/cart_item.dart';
import '../repositories/cart_repository.dart';

class GetCartUseCase {
  final CartRepository repository;

  GetCartUseCase(this.repository);

  Future<List<CartItem>> execute() {
    return repository.getCartItems();
  }
}

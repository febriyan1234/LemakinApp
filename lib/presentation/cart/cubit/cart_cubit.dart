import 'package:flutter_bloc/flutter_bloc.dart';
import 'cart_state.dart';
import '../../../domain/entities/cart_item.dart';
import '../../../domain/usecases/get_cart_usecase.dart';
import '../../../domain/usecases/add_item_to_cart_usecase.dart';
import '../../../domain/usecases/remove_item_from_cart_usecase.dart';
import '../../../domain/usecases/update_cart_item_usecase.dart';

class CartCubit extends Cubit<CartState> {
  final GetCartUseCase getCartUseCase;
  final AddItemToCartUseCase addItemToCartUseCase;
  final RemoveItemFromCartUseCase removeItemFromCartUseCase;
  final UpdateCartItemUseCase updateCartItemUseCase;

  CartCubit({
    required this.getCartUseCase,
    required this.addItemToCartUseCase,
    required this.removeItemFromCartUseCase,
    required this.updateCartItemUseCase,
  }) : super(CartInitial());

  Future<void> loadCart() async {
    emit(CartLoading());
    try {
      final items = await getCartUseCase.execute();
      emit(CartLoaded(items: items));
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  Future<void> addToCart(CartItem item) async {
    emit(CartLoading());
    try {
      final items = await addItemToCartUseCase.execute(item);
      emit(CartLoaded(items: items));
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  Future<void> removeFromCart(String id) async {
    emit(CartLoading());
    try {
      final items = await removeItemFromCartUseCase.execute(id);
      emit(CartLoaded(items: items));
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  Future<void> updateQuantity(String id, int quantity) async {
    emit(CartLoading());
    try {
      final items = await updateCartItemUseCase.execute(id, quantity);
      emit(CartLoaded(items: items));
    } catch (e) {
      emit(CartError(e.toString()));
    }
  }

  int getItemQuantityInCart(String menuItemId) {
    if (state is CartLoaded) {
      final items = (state as CartLoaded).items;
      return items
          .where((element) => element.menuItem.id == menuItemId)
          .fold(0, (sum, element) => sum + element.quantity);
    }
    return 0;
  }

  CartItem? getCartItemByMenuId(String menuItemId) {
    if (state is CartLoaded) {
      final items = (state as CartLoaded).items;
      final matched = items.where((element) => element.menuItem.id == menuItemId);
      if (matched.isNotEmpty) {
        return matched.first;
      }
    }
    return null;
  }
  
  void incrementCartItemQuantity(String menuItemId) {
    final cartItem = getCartItemByMenuId(menuItemId);
    if (cartItem != null) {
      updateQuantity(cartItem.id, cartItem.quantity + 1);
    }
  }

  void decrementCartItemQuantity(String menuItemId) {
    final cartItem = getCartItemByMenuId(menuItemId);
    if (cartItem != null) {
      if (cartItem.quantity <= 1) {
        removeFromCart(cartItem.id);
      } else {
        updateQuantity(cartItem.id, cartItem.quantity - 1);
      }
    }
  }

  void clearCart() {
    emit(const CartLoaded(items: []));
  }
}

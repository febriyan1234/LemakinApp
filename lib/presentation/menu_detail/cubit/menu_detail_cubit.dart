import 'package:flutter_bloc/flutter_bloc.dart';
import 'menu_detail_state.dart';
import '../../../domain/entities/menu_item.dart';
import '../../../domain/entities/cart_item.dart';
import '../../../domain/usecases/get_menu_detail_usecase.dart';
import '../../../domain/usecases/add_item_to_cart_usecase.dart';
import '../../cart/cubit/cart_cubit.dart';
import '../../cart/cubit/cart_state.dart';

class MenuDetailCubit extends Cubit<MenuDetailState> {
  final GetMenuDetailUseCase getMenuDetailUseCase;
  final AddItemToCartUseCase addItemToCartUseCase;
  final CartCubit cartCubit;

  MenuDetailCubit({
    required this.getMenuDetailUseCase,
    required this.addItemToCartUseCase,
    required this.cartCubit,
  }) : super(MenuDetailInitial());

  Future<void> fetchItemDetails(String id, {String? editCartItemId}) async {
    emit(MenuDetailLoading());
    try {
      final item = await getMenuDetailUseCase.execute(id);
      if (item != null) {
        Map<String, VariantOption> selected = {};
        int qty = 1;
        
        if (editCartItemId != null) {
          final cartState = cartCubit.state;
          if (cartState is CartLoaded) {
            try {
              final existing = cartState.items.firstWhere((i) => i.id == editCartItemId);
              selected = Map<String, VariantOption>.from(existing.selectedVariants);
              qty = existing.quantity;
            } catch (_) {}
          }
        }
        
        emit(MenuDetailLoaded(
          menuItem: item,
          selectedVariants: selected,
          quantity: qty,
          editCartItemId: editCartItemId,
        ));
      } else {
        emit(const MenuDetailError('Menu item not found'));
      }
    } catch (e) {
      emit(MenuDetailError(e.toString()));
    }
  }

  void updateQuantity(int quantity) {
    final currentState = state;
    if (currentState is MenuDetailLoaded) {
      if (quantity >= 1) {
        emit(currentState.copyWith(quantity: quantity));
      }
    }
  }

  void selectVariantOption(String variantName, VariantOption? option) {
    final currentState = state;
    if (currentState is MenuDetailLoaded) {
      final newSelected = Map<String, VariantOption>.from(currentState.selectedVariants);
      if (option == null) {
        newSelected.remove(variantName);
      } else {
        newSelected[variantName] = option;
      }
      emit(currentState.copyWith(selectedVariants: newSelected, clearError: true));
    }
  }

  bool addToCart({String? notes}) {
    final currentState = state;
    if (currentState is MenuDetailLoaded) {
      final item = currentState.menuItem;
      
      for (final variant in item.variants) {
        if (variant.isRequired && !currentState.selectedVariants.containsKey(variant.name)) {
          emit(currentState.copyWith(
            validationError: 'Please select an option for "${variant.name}"',
          ));
          return false;
        }
      }

      final sortedOptionIds = currentState.selectedVariants.values.map((o) => o.id).toList()..sort();
      final notesKey = notes != null && notes.trim().isNotEmpty ? 'notes_${notes.trim().hashCode}' : '';
      final cartItemId = [item.id, ...sortedOptionIds, if (notesKey.isNotEmpty) notesKey].join('_');

      final cartItem = CartItem(
        id: cartItemId,
        menuItem: item,
        quantity: currentState.quantity,
        selectedVariants: currentState.selectedVariants,
        notes: notes?.trim().isNotEmpty == true ? notes!.trim() : null,
      );

      if (currentState.editCartItemId != null) {
        cartCubit.removeFromCart(currentState.editCartItemId!);
      }
      cartCubit.addToCart(cartItem);
      return true;
    }
    return false;
  }
}

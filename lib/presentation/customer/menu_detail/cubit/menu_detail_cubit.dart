import 'package:flutter_bloc/flutter_bloc.dart';
import 'menu_detail_state.dart';
import '../../../../domain/entities/menu_item.dart';
import '../../../../domain/entities/cart_item.dart';
import '../../../../domain/usecases/get_menu_detail_usecase.dart';
import '../../../../domain/usecases/add_item_to_cart_usecase.dart';
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
              final existing = cartState.items.firstWhere(
                (i) => i.id == editCartItemId,
              );
              selected = Map<String, VariantOption>.from(
                existing.selectedVariants,
              );
              qty = existing.quantity;
            } catch (_) {}
          }
        }

        emit(
          MenuDetailLoaded(
            menuItem: item,
            selectedVariants: selected,
            quantity: qty,
            editCartItemId: editCartItemId,
          ),
        );
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

  void selectSingleVariantOption(String variantName, VariantOption? option) {
    final currentState = state;
    if (currentState is MenuDetailLoaded) {
      final newSelected = Map<String, VariantOption>.from(
        currentState.selectedVariants,
      );
      newSelected.removeWhere(
        (k, v) => k == variantName || k.startsWith('$variantName:'),
      );
      if (option != null) {
        newSelected[variantName] = option;
      }
      emit(
        currentState.copyWith(selectedVariants: newSelected, clearError: true),
      );
    }
  }

  void toggleMultiVariantOption(
    MenuVariant variant,
    VariantOption option,
    bool isSelected,
  ) {
    final currentState = state;
    if (currentState is MenuDetailLoaded) {
      final newSelected = Map<String, VariantOption>.from(
        currentState.selectedVariants,
      );
      final key = '${variant.name}:${option.id}';

      if (isSelected) {
        final currentCount = newSelected.keys
            .where((k) => k == variant.name || k.startsWith('${variant.name}:'))
            .length;

        if (variant.maxSelections > 0 && currentCount >= variant.maxSelections) {
          emit(
            currentState.copyWith(
              validationError:
                  'Maximum ${variant.maxSelections} options allowed for "${variant.name}"',
            ),
          );
          return;
        }
        newSelected[key] = option;
      } else {
        newSelected.remove(key);
      }

      emit(
        currentState.copyWith(selectedVariants: newSelected, clearError: true),
      );
    }
  }

  void clearVariantSelection(String variantName) {
    final currentState = state;
    if (currentState is MenuDetailLoaded) {
      final newSelected = Map<String, VariantOption>.from(
        currentState.selectedVariants,
      );
      newSelected.removeWhere(
        (k, v) => k == variantName || k.startsWith('$variantName:'),
      );
      emit(
        currentState.copyWith(selectedVariants: newSelected, clearError: true),
      );
    }
  }

  bool addToCart({String? notes}) {
    final currentState = state;
    if (currentState is MenuDetailLoaded) {
      final item = currentState.menuItem;

      for (final variant in item.variants) {
        final selectedForVariant = currentState.selectedVariants.entries
            .where(
              (e) =>
                  e.key == variant.name ||
                  e.key.startsWith('${variant.name}:'),
            )
            .map((e) => e.value)
            .toList();

        final minRequired = (variant.isRequired || variant.minSelections > 0)
            ? (variant.minSelections > 0 ? variant.minSelections : 1)
            : 0;

        if (selectedForVariant.length < minRequired) {
          final minText =
              minRequired > 1 ? '$minRequired options' : 'an option';
          emit(
            currentState.copyWith(
              validationError:
                  'Please select at least $minText for "${variant.name}"',
            ),
          );
          return false;
        }

        if (variant.maxSelections > 0 &&
            selectedForVariant.length > variant.maxSelections) {
          emit(
            currentState.copyWith(
              validationError:
                  'Maximum ${variant.maxSelections} options allowed for "${variant.name}"',
            ),
          );
          return false;
        }
      }

      final sortedOptionIds =
          currentState.selectedVariants.values.map((o) => o.id).toList()
            ..sort();
      final notesKey = notes != null && notes.trim().isNotEmpty
          ? 'notes_${notes.trim().hashCode}'
          : '';
      final cartItemId = [
        item.id,
        ...sortedOptionIds,
        if (notesKey.isNotEmpty) notesKey,
      ].join('_');

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

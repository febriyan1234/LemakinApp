import 'package:equatable/equatable.dart';
import 'menu_item.dart';

class CartItem extends Equatable {
  final String id; // Composite key: menuItemId_optionId1_optionId2...
  final MenuItem menuItem;
  final int quantity;
  final Map<String, VariantOption> selectedVariants; // variantName -> chosen option
  final String? notes;

  const CartItem({
    required this.id,
    required this.menuItem,
    required this.quantity,
    required this.selectedVariants,
    this.notes,
  });

  double get unitPrice {
    double total = menuItem.price;
    selectedVariants.forEach((_, option) {
      total += option.additionalPrice;
    });
    return total;
  }

  double get subtotal => unitPrice * quantity;

  CartItem copyWith({
    int? quantity,
    String? notes,
  }) {
    return CartItem(
      id: id,
      menuItem: menuItem,
      quantity: quantity ?? this.quantity,
      selectedVariants: selectedVariants,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [id, menuItem, quantity, selectedVariants, notes];
}

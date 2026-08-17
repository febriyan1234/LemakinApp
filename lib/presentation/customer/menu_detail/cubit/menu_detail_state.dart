import 'package:equatable/equatable.dart';
import '../../../../domain/entities/menu_item.dart';

abstract class MenuDetailState extends Equatable {
  const MenuDetailState();

  @override
  List<Object?> get props => [];
}

class MenuDetailInitial extends MenuDetailState {}

class MenuDetailLoading extends MenuDetailState {}

class MenuDetailLoaded extends MenuDetailState {
  final MenuItem menuItem;
  final int quantity;
  final Map<String, VariantOption>
  selectedVariants; // variantName -> selected option
  final String? validationError;
  final String? editCartItemId;

  const MenuDetailLoaded({
    required this.menuItem,
    this.quantity = 1,
    this.selectedVariants = const {},
    this.validationError,
    this.editCartItemId,
  });

  double get totalPrice {
    double base = menuItem.price;
    selectedVariants.forEach((_, option) {
      base += option.additionalPrice;
    });
    return base * quantity;
  }

  @override
  List<Object?> get props => [
    menuItem,
    quantity,
    selectedVariants,
    validationError,
    editCartItemId,
  ];

  MenuDetailLoaded copyWith({
    MenuItem? menuItem,
    int? quantity,
    Map<String, VariantOption>? selectedVariants,
    String? validationError,
    bool clearError = false,
    String? editCartItemId,
  }) {
    return MenuDetailLoaded(
      menuItem: menuItem ?? this.menuItem,
      quantity: quantity ?? this.quantity,
      selectedVariants: selectedVariants ?? this.selectedVariants,
      validationError: clearError
          ? null
          : (validationError ?? this.validationError),
      editCartItemId: editCartItemId ?? this.editCartItemId,
    );
  }
}

class MenuDetailError extends MenuDetailState {
  final String message;

  const MenuDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

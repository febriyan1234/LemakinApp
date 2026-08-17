import 'package:equatable/equatable.dart';
import '../../../../domain/entities/cart_item.dart';

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  final List<CartItem> items;

  const CartLoaded({required this.items});

  double get totalPrice {
    return items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  int get totalQuantity {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }

  @override
  List<Object?> get props => [items];
}

class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object?> get props => [message];
}

import 'package:equatable/equatable.dart';
import '../../../../domain/entities/order.dart';

abstract class CheckoutState extends Equatable {
  const CheckoutState();

  @override
  List<Object?> get props => [];
}

class CheckoutInitial extends CheckoutState {}

class CheckoutLoading extends CheckoutState {}

class CheckoutSuccess extends CheckoutState {
  final OrderEntity order;

  const CheckoutSuccess(this.order);

  @override
  List<Object?> get props => [order];
}

class CheckoutError extends CheckoutState {
  final String message;

  const CheckoutError(this.message);

  @override
  List<Object?> get props => [message];
}

class CheckoutFormState extends CheckoutState {
  final String? addressError;
  final String? phoneError;

  const CheckoutFormState({this.addressError, this.phoneError});

  @override
  List<Object?> get props => [addressError, phoneError];
}

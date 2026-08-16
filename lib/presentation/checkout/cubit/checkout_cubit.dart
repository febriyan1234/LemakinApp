import 'package:flutter_bloc/flutter_bloc.dart';
import 'checkout_state.dart';
import '../../../domain/entities/order.dart';
import '../../../domain/usecases/create_order_usecase.dart';
import '../../cart/cubit/cart_cubit.dart';
import '../../cart/cubit/cart_state.dart';

class CheckoutCubit extends Cubit<CheckoutState> {
  final CreateOrderUseCase createOrderUseCase;
  final CartCubit cartCubit;

  CheckoutCubit({
    required this.createOrderUseCase,
    required this.cartCubit,
  }) : super(CheckoutInitial());

  Future<void> submitOrder({
    required String name,
    required String phone,
    required String address,
  }) async {
    String? addressError;
    String? phoneError;

    if (address.trim().isEmpty) {
      addressError = 'Address is required';
    }

    if (phone.trim().isNotEmpty) {
      final phoneRegex = RegExp(r'^[+0-9]{9,15}$');
      if (!phoneRegex.hasMatch(phone.trim())) {
        phoneError = 'Invalid phone number format';
      }
    }

    if (addressError != null || phoneError != null) {
      emit(CheckoutFormState(
        addressError: addressError,
        phoneError: phoneError,
      ));
      return;
    }

    final cartState = cartCubit.state;
    if (cartState is! CartLoaded || cartState.items.isEmpty) {
      emit(const CheckoutError('Cart is empty'));
      return;
    }

    emit(CheckoutLoading());

    try {
      final order = OrderEntity(
        id: 'ORD_${DateTime.now().millisecondsSinceEpoch}',
        customer: CustomerInfo(
          name: name.trim().isEmpty ? 'Customer' : name.trim(),
          phone: phone.trim(),
          address: address.trim(),
        ),
        items: cartState.items,
        total: cartState.totalPrice,
        createdAt: DateTime.now(),
      );

      await createOrderUseCase.execute(order);
      
      cartCubit.clearCart();
      
      emit(CheckoutSuccess(order));
    } catch (e) {
      emit(CheckoutError(e.toString()));
    }
  }
  
  void resetFormState() {
    emit(CheckoutInitial());
  }
}

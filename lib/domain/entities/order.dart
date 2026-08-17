import 'package:equatable/equatable.dart';
import 'cart_item.dart';

class CustomerInfo extends Equatable {
  final String name;
  final String phone;
  final String address;

  const CustomerInfo({
    required this.name,
    required this.phone,
    required this.address,
  });

  @override
  List<Object?> get props => [name, phone, address];
}

class OrderEntity extends Equatable {
  final String id;
  final CustomerInfo customer;
  final List<CartItem> items;
  final double total;
  final DateTime createdAt;
  final String paymentMethod;
  final String status;

  const OrderEntity({
    required this.id,
    required this.customer,
    required this.items,
    required this.total,
    required this.createdAt,
    this.paymentMethod = 'QRIS',
    this.status = 'Success',
  });

  OrderEntity copyWith({
    String? id,
    CustomerInfo? customer,
    List<CartItem>? items,
    double? total,
    DateTime? createdAt,
    String? paymentMethod,
    String? status,
  }) {
    return OrderEntity(
      id: id ?? this.id,
      customer: customer ?? this.customer,
      items: items ?? this.items,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        id,
        customer,
        items,
        total,
        createdAt,
        paymentMethod,
        status,
      ];
}

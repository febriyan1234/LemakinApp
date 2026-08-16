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

  const OrderEntity({
    required this.id,
    required this.customer,
    required this.items,
    required this.total,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, customer, items, total, createdAt];
}

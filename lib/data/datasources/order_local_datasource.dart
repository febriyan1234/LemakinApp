import '../../domain/entities/order.dart';

abstract class OrderLocalDataSource {
  Future<void> createOrder(OrderEntity order);
  Future<List<OrderEntity>> getOrders();
}

class OrderLocalDataSourceImpl implements OrderLocalDataSource {
  final List<OrderEntity> _orders = [];

  @override
  Future<void> createOrder(OrderEntity order) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _orders.add(order);
  }

  @override
  Future<List<OrderEntity>> getOrders() async {
    return List.from(_orders);
  }
}

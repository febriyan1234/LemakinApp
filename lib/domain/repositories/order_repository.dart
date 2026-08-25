import '../entities/order.dart';

abstract class OrderRepository {
  Future<void> createOrder(OrderEntity order);
  Future<List<OrderEntity>> getOrders();
  Future<void> updateOrder(OrderEntity order);
  Future<void> deleteOrder(String id);
}

import '../../domain/entities/order.dart';
import '../../domain/repositories/order_repository.dart';
import '../datasources/order_local_datasource.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderLocalDataSource localDataSource;

  OrderRepositoryImpl({required this.localDataSource});

  @override
  Future<void> createOrder(OrderEntity order) {
    return localDataSource.createOrder(order);
  }

  @override
  Future<List<OrderEntity>> getOrders() {
    return localDataSource.getOrders();
  }
}

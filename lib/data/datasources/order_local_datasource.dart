import '../../domain/entities/order.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/menu_item.dart';
import 'menu_local_datasource.dart';

abstract class OrderLocalDataSource {
  Future<void> createOrder(OrderEntity order);
  Future<List<OrderEntity>> getOrders();
}

class OrderLocalDataSourceImpl implements OrderLocalDataSource {
  final MenuLocalDataSource menuLocalDataSource;
  final List<OrderEntity> _orders = [];

  OrderLocalDataSourceImpl({required this.menuLocalDataSource}) {
    _populateMockOrders();
  }

  void _populateMockOrders() {
    final now = DateTime.now();

    // Reusable dummy menu items to avoid massive boilerplate
    final katsu = const MenuItem(
      id: 'item_katsu',
      name: 'Chicken Katsu',
      description: 'Crispy chicken breast with savory sauce',
      price: 35000,
      imageUrl: '',
      categoryId: 'cat_chicken',
    );
    final teriyaki = const MenuItem(
      id: 'item_teriyaki',
      name: 'Beef Teriyaki Rice Bowl',
      description: 'Stir-fried beef with teriyaki sauce',
      price: 42000,
      imageUrl: '',
      categoryId: 'cat_rice',
    );
    final ramen = const MenuItem(
      id: 'item_spicy_ramen',
      name: 'Spicy Miso Ramen',
      description: 'Noodles in spicy rich miso broth',
      price: 38000,
      imageUrl: '',
      categoryId: 'cat_noodles',
    );
    final tea = const MenuItem(
      id: 'item_iced_tea',
      name: 'Iced Sweet Jasmine Tea',
      description: 'Refreshing brewed jasmine tea',
      price: 8000,
      imageUrl: '',
      categoryId: 'cat_drink',
    );
    final matcha = const MenuItem(
      id: 'item_matcha',
      name: 'Matcha Latte Ice',
      description: 'Matcha green tea with milk',
      price: 22000,
      imageUrl: '',
      categoryId: 'cat_drink',
    );
    final pudding = const MenuItem(
      id: 'item_mango',
      name: 'Mango Pudding Dessert',
      description: 'Sweet mango pudding',
      price: 18000,
      imageUrl: '',
      categoryId: 'cat_dessert',
    );
    final nasgor = const MenuItem(
      id: 'item_nasgor',
      name: 'Special Nasi Goreng',
      description: 'Indonesian fried rice',
      price: 30000,
      imageUrl: '',
      categoryId: 'cat_rice',
    );
    final boba = const MenuItem(
      id: 'item_boba',
      name: 'Brown Sugar Bubble Tea',
      description: 'Milk tea with boba pearls',
      price: 24000,
      imageUrl: '',
      categoryId: 'cat_drink',
    );

    _orders.addAll([
      // Today (Order 1)
      OrderEntity(
        id: 'ORD_001',
        customer: const CustomerInfo(name: 'Rian', phone: '0812345678', address: 'Table 4'),
        items: [
          CartItem(id: 'item_katsu_1', menuItem: katsu, quantity: 1, selectedVariants: const {}),
          CartItem(id: 'item_iced_tea_1', menuItem: tea, quantity: 2, selectedVariants: const {}),
        ],
        total: 51000,
        createdAt: now.subtract(const Duration(hours: 2)),
        paymentMethod: 'QRIS',
        status: 'Success',
      ),
      // Today (Order 2)
      OrderEntity(
        id: 'ORD_002',
        customer: const CustomerInfo(name: 'Siti', phone: '0823456789', address: 'Table 2'),
        items: [
          CartItem(id: 'item_nasgor_1', menuItem: nasgor, quantity: 1, selectedVariants: const {}),
        ],
        total: 30000,
        createdAt: now.subtract(const Duration(minutes: 30)),
        paymentMethod: 'Cash',
        status: 'Success',
      ),
      // Yesterday (Order 3)
      OrderEntity(
        id: 'ORD_003',
        customer: const CustomerInfo(name: 'Ahmad', phone: '0834567890', address: 'Table 7'),
        items: [
          CartItem(id: 'item_teriyaki_1', menuItem: teriyaki, quantity: 1, selectedVariants: const {}),
          CartItem(id: 'item_matcha_1', menuItem: matcha, quantity: 1, selectedVariants: const {}),
          CartItem(id: 'item_mango_1', menuItem: pudding, quantity: 1, selectedVariants: const {}),
        ],
        total: 82000,
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
        paymentMethod: 'QRIS',
        status: 'Success',
      ),
      // 2 Days ago (Order 4)
      OrderEntity(
        id: 'ORD_004',
        customer: const CustomerInfo(name: 'Dewi', phone: '0845678901', address: 'Takeaway'),
        items: [
          CartItem(id: 'item_spicy_ramen_1', menuItem: ramen, quantity: 1, selectedVariants: const {}),
          CartItem(id: 'item_boba_1', menuItem: boba, quantity: 1, selectedVariants: const {}),
        ],
        total: 62000,
        createdAt: now.subtract(const Duration(days: 2, hours: 1)),
        paymentMethod: 'Cash',
        status: 'Success',
      ),
      // 4 Days ago (Order 5)
      OrderEntity(
        id: 'ORD_005',
        customer: const CustomerInfo(name: 'Budi', phone: '0856789012', address: 'Table 1'),
        items: [
          CartItem(id: 'item_katsu_2', menuItem: katsu, quantity: 2, selectedVariants: const {}),
        ],
        total: 70000,
        createdAt: now.subtract(const Duration(days: 4, hours: 5)),
        paymentMethod: 'Card',
        status: 'Success',
      ),
      // 7 Days ago (Order 6)
      OrderEntity(
        id: 'ORD_006',
        customer: const CustomerInfo(name: 'Eka', phone: '0867890123', address: 'Table 5'),
        items: [
          CartItem(id: 'item_nasgor_2', menuItem: nasgor, quantity: 2, selectedVariants: const {}),
          CartItem(id: 'item_iced_tea_2', menuItem: tea, quantity: 2, selectedVariants: const {}),
        ],
        total: 76000,
        createdAt: now.subtract(const Duration(days: 7, hours: 2)),
        paymentMethod: 'QRIS',
        status: 'Success',
      ),
      // 10 Days ago (Order 7)
      OrderEntity(
        id: 'ORD_007',
        customer: const CustomerInfo(name: 'Feri', phone: '0878901234', address: 'Table 3'),
        items: [
          CartItem(id: 'item_teriyaki_2', menuItem: teriyaki, quantity: 1, selectedVariants: const {}),
        ],
        total: 42000,
        createdAt: now.subtract(const Duration(days: 10, hours: 4)),
        paymentMethod: 'QRIS',
        status: 'Success',
      ),
      // 14 Days ago (Order 8)
      OrderEntity(
        id: 'ORD_008',
        customer: const CustomerInfo(name: 'Gita', phone: '0889012345', address: 'Table 8'),
        items: [
          CartItem(id: 'item_nasgor_3', menuItem: nasgor, quantity: 1, selectedVariants: const {}),
          CartItem(id: 'item_iced_tea_3', menuItem: tea, quantity: 1, selectedVariants: const {}),
        ],
        total: 38000,
        createdAt: now.subtract(const Duration(days: 14, hours: 6)),
        paymentMethod: 'Cash',
        status: 'Success',
      ),
      // 20 Days ago (Order 9)
      OrderEntity(
        id: 'ORD_009',
        customer: const CustomerInfo(name: 'Hadi', phone: '0890123456', address: 'Table 6'),
        items: [
          CartItem(id: 'item_spicy_ramen_2', menuItem: ramen, quantity: 2, selectedVariants: const {}),
          CartItem(id: 'item_matcha_2', menuItem: matcha, quantity: 2, selectedVariants: const {}),
        ],
        total: 120000,
        createdAt: now.subtract(const Duration(days: 20, hours: 2)),
        paymentMethod: 'Card',
        status: 'Success',
      ),
      // 25 Days ago (Order 10)
      OrderEntity(
        id: 'ORD_010',
        customer: const CustomerInfo(name: 'Indah', phone: '0801234567', address: 'Table 10'),
        items: [
          CartItem(id: 'item_katsu_3', menuItem: katsu, quantity: 1, selectedVariants: const {}),
          CartItem(id: 'item_mango_2', menuItem: pudding, quantity: 1, selectedVariants: const {}),
        ],
        total: 53000,
        createdAt: now.subtract(const Duration(days: 25, hours: 4)),
        paymentMethod: 'QRIS',
        status: 'Success',
      ),
      // 30 Days ago (Order 11)
      OrderEntity(
        id: 'ORD_011',
        customer: const CustomerInfo(name: 'Joni', phone: '0812345098', address: 'Table 9'),
        items: [
          CartItem(id: 'item_teriyaki_3', menuItem: teriyaki, quantity: 2, selectedVariants: const {}),
        ],
        total: 84000,
        createdAt: now.subtract(const Duration(days: 30, hours: 1)),
        paymentMethod: 'QRIS',
        status: 'Success',
      ),
    ]);
  }

  @override
  Future<void> createOrder(OrderEntity order) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _orders.add(order);

    // Auto-reduce stock of menu items in MenuLocalDataSource
    for (final cartItem in order.items) {
      try {
        final currentMenu = await menuLocalDataSource.getMenuItemDetail(cartItem.menuItem.id);
        if (currentMenu != null) {
          final updatedStock = (currentMenu.stock - cartItem.quantity).clamp(0, 9999);
          // If stock reaches 0, we can optionally keep it active but mark as out of stock.
          // The detail UI will check stock.
          await menuLocalDataSource.updateMenuItem(
            currentMenu.copyWith(stock: updatedStock),
          );
        }
      } catch (e) {
        // Safe fallback if update fails
      }
    }
  }

  @override
  Future<List<OrderEntity>> getOrders() async {
    return List.from(_orders);
  }
}

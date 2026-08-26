import 'package:flutter_test/flutter_test.dart';
import 'package:lemakin_app/domain/entities/menu_category.dart';
import 'package:lemakin_app/domain/entities/menu_item.dart';
import 'package:lemakin_app/domain/entities/order.dart';
import 'package:lemakin_app/domain/entities/cart_item.dart';
import 'package:lemakin_app/domain/repositories/menu_repository.dart';
import 'package:lemakin_app/domain/repositories/order_repository.dart';
import 'package:lemakin_app/domain/usecases/get_menu_usecase.dart';
import 'package:lemakin_app/presentation/customer/menu/cubit/menu_cubit.dart';
import 'package:lemakin_app/presentation/customer/menu/cubit/menu_state.dart';

class FakeMenuRepository implements MenuRepository {
  final List<MenuCategory> categories;
  final List<MenuItem> items;

  FakeMenuRepository({required this.categories, required this.items});

  @override
  Future<List<MenuCategory>> getCategories() async => categories;

  @override
  Future<List<MenuItem>> getMenuItems({
    String? categoryId,
    String? searchQuery,
    bool includeInactive = false,
  }) async {
    return items;
  }

  @override
  Future<List<MenuItem>> getRecommendedItems({bool includeInactive = false}) async {
    return items.where((item) => item.isRecommended).toList();
  }

  @override
  Future<MenuItem?> getMenuItemDetail(String id) async => null;
  @override
  Future<void> addMenuItem(MenuItem item) async {}
  @override
  Future<void> updateMenuItem(MenuItem item) async {}
  @override
  Future<void> deleteMenuItem(String id) async {}
  @override
  Future<void> addCategory(MenuCategory category) async {}
  @override
  Future<void> updateCategory(MenuCategory category) async {}
  @override
  Future<void> deleteCategory(String id) async {}
  @override
  Future<List<MenuVariant>> getVariants() async => [];
  @override
  Future<void> addVariant(MenuVariant variant) async {}
  @override
  Future<void> updateVariant(MenuVariant variant) async {}
  @override
  Future<void> deleteVariant(String id) async {}
}

class FakeOrderRepository implements OrderRepository {
  final List<OrderEntity> orders;

  FakeOrderRepository({required this.orders});

  @override
  Future<List<OrderEntity>> getOrders() async => orders;

  @override
  Future<void> createOrder(OrderEntity order) async {}
  @override
  Future<void> updateOrder(OrderEntity order) async {}
  @override
  Future<void> deleteOrder(String id) async {}
}

void main() {
  group('MenuCubit Best Seller Tests', () {
    late FakeMenuRepository menuRepository;
    late FakeOrderRepository orderRepository;
    late GetMenuUseCase getMenuUseCase;
    late MenuCubit menuCubit;

    final category = const MenuCategory(id: 'cat_rice', name: 'Rice');
    final itemA = const MenuItem(
      id: 'item_a',
      name: 'Item A',
      description: 'Desc A',
      price: 10000,
      imageUrl: '',
      categoryId: 'cat_rice',
      isActive: true,
      stock: 10,
    );
    final itemB = const MenuItem(
      id: 'item_b',
      name: 'Item B',
      description: 'Desc B',
      price: 12000,
      imageUrl: '',
      categoryId: 'cat_rice',
      isActive: true,
      stock: 10,
    );
    final itemC = const MenuItem(
      id: 'item_c',
      name: 'Item C',
      description: 'Desc C',
      price: 15000,
      imageUrl: '',
      categoryId: 'cat_rice',
      isActive: true,
      stock: 10,
    );

    setUp(() {
      menuRepository = FakeMenuRepository(
        categories: [category],
        items: [itemA, itemB, itemC],
      );
    });

    test('should fetch menus and calculate best sellers correctly based on order quantities', () async {
      final order1 = OrderEntity(
        id: 'ORD_1',
        customer: const CustomerInfo(name: 'John', phone: '', address: ''),
        items: [
          CartItem(id: 'cart_1', menuItem: itemA, quantity: 3, selectedVariants: const {}),
          CartItem(id: 'cart_2', menuItem: itemB, quantity: 1, selectedVariants: const {}),
        ],
        total: 42000,
        createdAt: DateTime.now(),
        status: 'Success',
      );

      final order2 = OrderEntity(
        id: 'ORD_2',
        customer: const CustomerInfo(name: 'Jane', phone: '', address: ''),
        items: [
          CartItem(id: 'cart_3', menuItem: itemB, quantity: 4, selectedVariants: const {}),
        ],
        total: 48000,
        createdAt: DateTime.now(),
        status: 'Success',
      );

      // Order with failed status should be ignored
      final orderFailed = OrderEntity(
        id: 'ORD_3',
        customer: const CustomerInfo(name: 'Fail', phone: '', address: ''),
        items: [
          CartItem(id: 'cart_4', menuItem: itemC, quantity: 10, selectedVariants: const {}),
        ],
        total: 150000,
        createdAt: DateTime.now(),
        status: 'Cancelled',
      );

      orderRepository = FakeOrderRepository(orders: [order1, order2, orderFailed]);
      getMenuUseCase = GetMenuUseCase(menuRepository);
      menuCubit = MenuCubit(
        getMenuUseCase: getMenuUseCase,
        orderRepository: orderRepository,
      );

      expect(menuCubit.state, isA<MenuInitial>());

      await menuCubit.fetchMenu();

      expect(menuCubit.state, isA<MenuLoaded>());
      final state = menuCubit.state as MenuLoaded;

      // Best sellers should only contain active items with successful sales.
      // Sales counts:
      // Item B: 1 (order 1) + 4 (order 2) = 5
      // Item A: 3 (order 1) = 3
      // Item C: 0 (orderFailed is ignored) = 0
      // So order should be [Item B, Item A]
      expect(state.bestSellers.length, 2);
      expect(state.bestSellers[0].id, 'item_b');
      expect(state.bestSellers[1].id, 'item_a');
    });

    test('should return empty best sellers list if there are no successful orders', () async {
      orderRepository = FakeOrderRepository(orders: []);
      getMenuUseCase = GetMenuUseCase(menuRepository);
      menuCubit = MenuCubit(
        getMenuUseCase: getMenuUseCase,
        orderRepository: orderRepository,
      );

      await menuCubit.fetchMenu();

      final state = menuCubit.state as MenuLoaded;
      expect(state.bestSellers.isEmpty, true);
    });
  });
}

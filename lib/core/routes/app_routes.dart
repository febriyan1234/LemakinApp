import 'package:go_router/go_router.dart';
import '../../domain/entities/order.dart';
import '../../presentation/menu/ui/menu_page.dart';
import '../../presentation/menu_detail/ui/menu_detail_page.dart';
import '../../presentation/checkout/ui/checkout_page.dart';
import '../../presentation/checkout/ui/order_success_page.dart';

class AppRoutes {
  static const String menu = '/menu';
  static const String menuDetail = '/menu/:id';
  static const String checkout = '/checkout';
  static const String success = '/success';

  static final GoRouter router = GoRouter(
    initialLocation: menu,
    routes: [
      GoRoute(
        path: menu,
        builder: (context, state) => const MenuPage(),
      ),
      GoRoute(
        path: '/menu/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          final editCartItemId = state.uri.queryParameters['editCartItemId'];
          return MenuDetailPage(menuItemId: id, editCartItemId: editCartItemId);
        },
      ),
      GoRoute(
        path: checkout,
        builder: (context, state) => const CheckoutPage(),
      ),
      GoRoute(
        path: success,
        builder: (context, state) {
          final order = state.extra as OrderEntity?;
          return OrderSuccessPage(order: order);
        },
      ),
    ],
  );
}

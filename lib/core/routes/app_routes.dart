import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../di/injection_container.dart' as di;
import '../../domain/entities/order.dart';
import '../../domain/entities/menu_item.dart';

// Customer pages
import '../../presentation/customer/menu/ui/menu_page.dart';
import '../../presentation/customer/menu_detail/ui/menu_detail_page.dart';
import '../../presentation/customer/checkout/ui/checkout_page.dart';
import '../../presentation/customer/checkout/ui/order_success_page.dart';
import '../../presentation/customer/qris/ui/qris_page.dart';

// Admin pages & cubits
import '../../presentation/admin/auth/ui/admin_login_page.dart';
import '../../presentation/admin/dashboard/ui/admin_dashboard_page.dart';
import '../../presentation/admin/dashboard/cubit/admin_dashboard_cubit.dart';
import '../../presentation/admin/menu/ui/admin_menu_list_page.dart';
import '../../presentation/admin/menu/ui/admin_add_edit_menu_page.dart';
import '../../presentation/admin/menu/cubit/admin_menu_cubit.dart';
import '../../presentation/admin/layout/admin_layout.dart';
import '../../presentation/admin/reports/ui/income_reports_page.dart';
import '../../presentation/admin/reports/ui/expense_reports_page.dart';
import '../../presentation/admin/reports/ui/admin_add_edit_expense_page.dart';
import '../../presentation/admin/reports/ui/admin_edit_order_page.dart';
import '../../presentation/admin/reports/cubit/admin_reports_cubit.dart';
import '../../domain/entities/expense.dart';

class AppRoutes {
  static const String menu = '/menu';
  static const String menuDetail = '/menu/:id';
  static const String checkout = '/checkout';
  static const String success = '/success';
  static const String qris = '/qris';

  // Admin routes
  static const String adminLogin = '/admin/login';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminMenu = '/admin/menu';
  static const String adminMenuAdd = '/admin/menu/add';
  static const String adminMenuEdit = '/admin/menu/edit/:id';
  static const String adminIncomeReports = '/admin/reports/income';
  static const String adminOrderEdit = '/admin/reports/income/edit';
  static const String adminExpenseReports = '/admin/reports/expense';
  static const String adminExpenseAdd = '/admin/reports/expense/add';
  static const String adminExpenseEdit = '/admin/reports/expense/edit/:id';

  static final GoRouter router = GoRouter(
    initialLocation: menu,
    routes: [
      // ----------------- Customer Routes -----------------
      GoRoute(path: menu, builder: (context, state) => const MenuPage()),
      GoRoute(
        path: menuDetail,
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
      GoRoute(
        path: qris,
        builder: (context, state) => const QrisPage(),
      ),

      // ----------------- Admin Routes -----------------
      GoRoute(
        path: adminLogin,
        builder: (context, state) => const AdminLoginPage(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          String title = 'Admin Overview';
          final path = state.uri.path;
          if (path == adminDashboard) {
            title = 'Dashboard Overview';
          } else if (path.startsWith(adminMenu)) {
            title = 'Menu Management';
          } else if (path == adminIncomeReports) {
            title = 'Income Reports';
          } else if (path == adminExpenseReports) {
            title = 'Expense Reports';
          }

          return BlocProvider<AdminReportsCubit>(
            create: (_) => di.sl<AdminReportsCubit>(),
            child: AdminLayout(navigationShell: navigationShell, title: title),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: adminDashboard,
                pageBuilder: (context, state) => NoTransitionPage(
                  child: BlocProvider<AdminDashboardCubit>(
                    create: (_) => di.sl<AdminDashboardCubit>(),
                    child: const AdminDashboardPage(),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: adminMenu,
                pageBuilder: (context, state) => NoTransitionPage(
                  child: BlocProvider<AdminMenuCubit>(
                    create: (_) => di.sl<AdminMenuCubit>(),
                    child: const AdminMenuListPage(),
                  ),
                ),
              ),
              GoRoute(
                path: adminMenuAdd,
                builder: (context, state) => BlocProvider<AdminMenuCubit>(
                  create: (_) => di.sl<AdminMenuCubit>(),
                  child: const AdminAddEditMenuPage(),
                ),
              ),
              GoRoute(
                path: '/admin/menu/edit/:id',
                builder: (context, state) {
                  final item = state.extra as MenuItem?;
                  return BlocProvider<AdminMenuCubit>(
                    create: (_) => di.sl<AdminMenuCubit>(),
                    child: AdminAddEditMenuPage(menuItem: item),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: adminIncomeReports,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: IncomeReportsPage()),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final order = state.extra as OrderEntity;
                      return AdminEditOrderPage(order: order);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: adminExpenseReports,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ExpenseReportsPage()),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (context, state) =>
                        const AdminAddEditExpensePage(),
                  ),
                  GoRoute(
                    path: 'edit/:id',
                    builder: (context, state) {
                      final item = state.extra as Expense?;
                      return AdminAddEditExpensePage(expense: item);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

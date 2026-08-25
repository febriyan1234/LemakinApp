import 'package:get_it/get_it.dart';

// Data Sources
import '../../data/datasources/cart_local_datasource.dart';
import '../../data/datasources/menu_local_datasource.dart';
import '../../data/datasources/order_local_datasource.dart';
import '../../data/datasources/expense_local_datasource.dart';
import '../../data/datasources/admin_auth_local_datasource.dart';
import '../../data/datasources/menu_firestore_datasource.dart';
import '../../data/datasources/order_firestore_datasource.dart';
import '../../data/datasources/expense_firestore_datasource.dart';
import '../../data/datasources/admin_auth_firestore_datasource.dart';
import '../config/firebase_config.dart';

// Repositories
import '../../data/repositories/cart_repository_impl.dart';
import '../../data/repositories/menu_repository_impl.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../data/repositories/expense_repository_impl.dart';
import '../../data/repositories/admin_auth_repository_impl.dart';

import '../../domain/repositories/cart_repository.dart';
import '../../domain/repositories/menu_repository.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/repositories/admin_auth_repository.dart';

// Use Cases
import '../../domain/usecases/add_item_to_cart_usecase.dart';
import '../../domain/usecases/create_order_usecase.dart';
import '../../domain/usecases/get_cart_usecase.dart';
import '../../domain/usecases/get_menu_detail_usecase.dart';
import '../../domain/usecases/get_menu_usecase.dart';
import '../../domain/usecases/remove_item_from_cart_usecase.dart';
import '../../domain/usecases/update_cart_item_usecase.dart';
import '../../domain/usecases/admin_menu_usecase.dart';
import '../../domain/usecases/clear_cart_usecase.dart';

// Cubits / Blocs
import '../../presentation/customer/cart/cubit/cart_cubit.dart';
import '../../presentation/customer/menu/cubit/menu_cubit.dart';
import '../../presentation/customer/menu_detail/cubit/menu_detail_cubit.dart';
import '../../presentation/customer/checkout/cubit/checkout_cubit.dart';
import '../../presentation/admin/auth/cubit/admin_auth_cubit.dart';
import '../../presentation/admin/dashboard/cubit/admin_dashboard_cubit.dart';
import '../../presentation/admin/menu/cubit/admin_menu_cubit.dart';
import '../../presentation/admin/reports/cubit/admin_reports_cubit.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  // ----------------- Presentation: Cubits -----------------
  sl.registerFactory(() => MenuCubit(getMenuUseCase: sl()));

  sl.registerLazySingleton(
    () => CartCubit(
      getCartUseCase: sl(),
      addItemToCartUseCase: sl(),
      removeItemFromCartUseCase: sl(),
      updateCartItemUseCase: sl(),
      clearCartUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => MenuDetailCubit(
      getMenuDetailUseCase: sl(),
      addItemToCartUseCase: sl(),
      cartCubit: sl(),
    ),
  );

  sl.registerFactory(
    () => CheckoutCubit(createOrderUseCase: sl(), cartCubit: sl()),
  );

  // Admin Cubits
  sl.registerLazySingleton(() => AdminAuthCubit(authRepository: sl()));
  sl.registerFactory(
    () => AdminDashboardCubit(
      menuRepository: sl(),
      expenseRepository: sl(),
      orderRepository: sl(),
    ),
  );
  sl.registerFactory(
    () => AdminMenuCubit(menuRepository: sl(), adminMenuUseCase: sl()),
  );
  sl.registerFactory(
    () => AdminReportsCubit(orderRepository: sl(), expenseRepository: sl()),
  );

  // ----------------- Domain: Use Cases -----------------
  sl.registerLazySingleton(() => GetMenuUseCase(sl()));
  sl.registerLazySingleton(() => GetMenuDetailUseCase(sl()));
  sl.registerLazySingleton(() => AddItemToCartUseCase(sl()));
  sl.registerLazySingleton(() => RemoveItemFromCartUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCartItemUseCase(sl()));
  sl.registerLazySingleton(() => GetCartUseCase(sl()));
  sl.registerLazySingleton(() => CreateOrderUseCase(sl()));
  sl.registerLazySingleton(() => AdminMenuUseCase(sl()));
  sl.registerLazySingleton(() => ClearCartUseCase(sl()));

  // ----------------- Data: Repositories -----------------
  sl.registerLazySingleton<MenuRepository>(
    () => MenuRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<CartRepository>(
    () => CartRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<OrderRepository>(
    () => OrderRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<AdminAuthRepository>(
    () => AdminAuthRepositoryImpl(localDataSource: sl()),
  );

  // ----------------- Data: Sources -----------------
  if (FirebaseConfig.useFirebase) {
    sl.registerLazySingleton<MenuLocalDataSource>(
      () => MenuFirestoreDataSourceImpl(),
    );
    sl.registerLazySingleton<CartLocalDataSource>(
      () => CartLocalDataSourceImpl(),
    );
    sl.registerLazySingleton<OrderLocalDataSource>(
      () => OrderFirestoreDataSourceImpl(),
    );
    sl.registerLazySingleton<ExpenseLocalDataSource>(
      () => ExpenseFirestoreDataSourceImpl(),
    );
    sl.registerLazySingleton<AdminAuthLocalDataSource>(
      () => AdminAuthFirestoreDataSourceImpl(),
    );
  } else {
    sl.registerLazySingleton<MenuLocalDataSource>(
      () => MenuLocalDataSourceImpl(),
    );
    sl.registerLazySingleton<CartLocalDataSource>(
      () => CartLocalDataSourceImpl(),
    );
    sl.registerLazySingleton<OrderLocalDataSource>(
      () => OrderLocalDataSourceImpl(menuLocalDataSource: sl()),
    );
    sl.registerLazySingleton<ExpenseLocalDataSource>(
      () => ExpenseLocalDataSourceImpl(),
    );
    sl.registerLazySingleton<AdminAuthLocalDataSource>(
      () => AdminAuthLocalDataSourceImpl(),
    );
  }
}

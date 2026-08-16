import 'package:get_it/get_it.dart';
import '../../data/datasources/cart_local_datasource.dart';
import '../../data/datasources/menu_local_datasource.dart';
import '../../data/datasources/order_local_datasource.dart';
import '../../data/repositories/cart_repository_impl.dart';
import '../../data/repositories/menu_repository_impl.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../domain/repositories/cart_repository.dart';
import '../../domain/repositories/menu_repository.dart';
import '../../domain/repositories/order_repository.dart';
import '../../domain/usecases/add_item_to_cart_usecase.dart';
import '../../domain/usecases/create_order_usecase.dart';
import '../../domain/usecases/get_cart_usecase.dart';
import '../../domain/usecases/get_menu_detail_usecase.dart';
import '../../domain/usecases/get_menu_usecase.dart';
import '../../domain/usecases/remove_item_from_cart_usecase.dart';
import '../../domain/usecases/update_cart_item_usecase.dart';
import '../../presentation/cart/cubit/cart_cubit.dart';
import '../../presentation/menu/cubit/menu_cubit.dart';
import '../../presentation/menu_detail/cubit/menu_detail_cubit.dart';
import '../../presentation/checkout/cubit/checkout_cubit.dart';

final GetIt sl = GetIt.instance;

Future<void> init() async {
  // Presentation: Cubits
  sl.registerFactory(() => MenuCubit(getMenuUseCase: sl()));
  
  // CartCubit needs to be a Singleton to keep the shopping cart state alive across pages.
  sl.registerLazySingleton(() => CartCubit(
        getCartUseCase: sl(),
        addItemToCartUseCase: sl(),
        removeItemFromCartUseCase: sl(),
        updateCartItemUseCase: sl(),
      ));
      
  sl.registerFactory(() => MenuDetailCubit(
        getMenuDetailUseCase: sl(),
        addItemToCartUseCase: sl(),
        cartCubit: sl(),
      ));
      
  sl.registerFactory(() => CheckoutCubit(
        createOrderUseCase: sl(),
        cartCubit: sl(),
      ));

  // Domain: Use cases
  sl.registerLazySingleton(() => GetMenuUseCase(sl()));
  sl.registerLazySingleton(() => GetMenuDetailUseCase(sl()));
  sl.registerLazySingleton(() => AddItemToCartUseCase(sl()));
  sl.registerLazySingleton(() => RemoveItemFromCartUseCase(sl()));
  sl.registerLazySingleton(() => UpdateCartItemUseCase(sl()));
  sl.registerLazySingleton(() => GetCartUseCase(sl()));
  sl.registerLazySingleton(() => CreateOrderUseCase(sl()));

  // Data: Repositories
  sl.registerLazySingleton<MenuRepository>(
      () => MenuRepositoryImpl(localDataSource: sl()));
  sl.registerLazySingleton<CartRepository>(
      () => CartRepositoryImpl(localDataSource: sl()));
  sl.registerLazySingleton<OrderRepository>(
      () => OrderRepositoryImpl(localDataSource: sl()));

  // Data: Sources
  sl.registerLazySingleton<MenuLocalDataSource>(() => MenuLocalDataSourceImpl());
  sl.registerLazySingleton<CartLocalDataSource>(() => CartLocalDataSourceImpl());
  sl.registerLazySingleton<OrderLocalDataSource>(() => OrderLocalDataSourceImpl());
}

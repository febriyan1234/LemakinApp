import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/di/injection_container.dart' as di;
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/mobile_layout_wrapper.dart';
import 'presentation/customer/cart/cubit/cart_cubit.dart';
import 'presentation/customer/menu/cubit/menu_cubit.dart';
import 'presentation/admin/auth/cubit/admin_auth_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  await di.init();
  await initializeDateFormatting('id', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CartCubit>(create: (_) => di.sl<CartCubit>()..loadCart()),
        BlocProvider<MenuCubit>(create: (_) => di.sl<MenuCubit>()),
        BlocProvider<AdminAuthCubit>(create: (_) => di.sl<AdminAuthCubit>()),
      ],
      child: MaterialApp.router(
        title: 'Lemakin Ordering System',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: AppRoutes.router,
        builder: (context, child) => MobileLayoutWrapper(child: child!),
      ),
    );
  }
}

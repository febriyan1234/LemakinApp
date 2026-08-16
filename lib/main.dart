import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'core/di/injection_container.dart' as di;
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/mobile_layout_wrapper.dart';
import 'presentation/cart/cubit/cart_cubit.dart';
import 'presentation/menu/cubit/menu_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CartCubit>(
          create: (_) => di.sl<CartCubit>()..loadCart(),
        ),
        BlocProvider<MenuCubit>(
          create: (_) => di.sl<MenuCubit>(),
        ),
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

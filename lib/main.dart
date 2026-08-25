import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'core/config/firebase_config.dart';
import 'firebase_options.dart';
import 'core/di/injection_container.dart' as di;
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/mobile_layout_wrapper.dart';
import 'presentation/customer/cart/cubit/cart_cubit.dart';
import 'presentation/customer/menu/cubit/menu_cubit.dart';
import 'presentation/admin/auth/cubit/admin_auth_cubit.dart';
import 'core/utils/store_status_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  GoRouter.optionURLReflectsImperativeAPIs = true;
  if (FirebaseConfig.useFirebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  await di.init();
  await initializeDateFormatting('id', null);

  // Fetch settings document from Firestore BEFORE calling runApp!
  String initialRestaurantName = 'Lemakin Restaurant';
  try {
    if (FirebaseConfig.useFirebase) {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('store').get();
      if (doc.exists) {
        final sData = doc.data();
        if (sData != null && sData['restaurantName'] != null) {
          initialRestaurantName = sData['restaurantName'] as String;
        }
      }
    }
  } catch (e) {
    // Fallback if network/permission fails
  }

  runApp(MyApp(initialRestaurantName: initialRestaurantName));
}

class LemakinScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

class MyApp extends StatelessWidget {
  final String initialRestaurantName;
  const MyApp({
    super.key,
    this.initialRestaurantName = 'Lemakin Restaurant',
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<CartCubit>(create: (_) => di.sl<CartCubit>()..loadCart()),
        BlocProvider<MenuCubit>(create: (_) => di.sl<MenuCubit>()),
        BlocProvider<AdminAuthCubit>(create: (_) => di.sl<AdminAuthCubit>()),
      ],
      child: StreamBuilder<DocumentSnapshot>(
        stream: StoreStatusHelper.stream,
        builder: (context, snapshot) {
          String restaurantName = initialRestaurantName;
          if (snapshot.hasData && snapshot.data!.exists) {
            final sData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            restaurantName = sData['restaurantName'] as String? ?? initialRestaurantName;
          }

          return Title(
            title: restaurantName,
            color: const Color(0xFFFF6500),
            child: MaterialApp.router(
              scrollBehavior: LemakinScrollBehavior(),
              title: restaurantName,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.lightTheme,
              routerConfig: AppRoutes.router,
              builder: (context, child) => MobileLayoutWrapper(child: child!),
            ),
          );
        },
      ),
    );
  }
}

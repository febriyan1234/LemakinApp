import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';

class MobileLayoutWrapper extends StatelessWidget {
  final Widget child;

  const MobileLayoutWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Check if the current route is an admin page. If so, bypass the mobile layout constraint.
    String location = '';
    try {
      location = GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
    } catch (_) {}

    if (location.startsWith('/admin')) {
      return child;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        
        if (width > 480) {
          return Container(
            color: AppColors.grey200,
            alignment: Alignment.center,
            child: Container(
              width: 450,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.white,
                child: child,
              ),
            ),
          );
        }
        
        return child;
      },
    );
  }
}

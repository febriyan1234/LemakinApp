import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_colors.dart';

class AppEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double lottieSize;
  final List<Widget>? actions;

  const AppEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.lottieSize = 150.0,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: lottieSize,
              height: lottieSize,
              child: Lottie.asset(
                'assets/lottie/empty.json',
                fit: BoxFit.contain,
                filterQuality: FilterQuality.low,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            if (actions != null) ...[
              const SizedBox(height: 16),
              ...actions!,
            ],
          ],
        ),
      ),
    );
  }
}

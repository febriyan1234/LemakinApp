import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AppLoadingIndicator extends StatelessWidget {
  final double? width;
  final double? height;

  const AppLoadingIndicator({
    super.key,
    this.width = 100.0,
    this.height = 100.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Lottie.asset(
        'assets/lottie/loading.json',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.low,
      ),
    );
  }
}

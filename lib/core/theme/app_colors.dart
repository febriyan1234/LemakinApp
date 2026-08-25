import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFFF6500);
  static const Color primarySoft = Color(0xFFFFF0E5);
  
  static const Gradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFFFF5E62),
      Color(0xFFFF9966),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  
  static const Color scaffoldBackground = Color(0xFFF8F9FA);
  static const Color cardBackground = Colors.white;
  
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textLight = Color(0xFFADB5BD);
  
  static const Color border = Color(0xFFE9ECEF);
  static const Color borderActive = Color(0xFFFF6500);
  
  static const Color error = Color(0xFFDC3545);
  static const Color success = Color(0xFF28A745);
  static const Color warning = Color(0xFFFFC107);
  
  static const Color grey100 = Color(0xFFF8F9FA);
  static const Color grey200 = Color(0xFFE9ECEF);
  static const Color grey300 = Color(0xFFDEE2E6);
  static const Color grey400 = Color(0xFFCED4DA);
  static const Color grey500 = Color(0xFFADB5BD);
  static const Color grey600 = Color(0xFF6C757D);
  static const Color grey700 = Color(0xFF495057);
  static const Color grey800 = Color(0xFF343A40);
  static const Color grey900 = Color(0xFF212529);
}

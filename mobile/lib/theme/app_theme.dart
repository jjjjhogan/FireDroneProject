import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2F6B4F);
  static const Color primaryLight = Color(0xFFE8F3ED);
  static const Color background = Color(0xFFF4F5F7);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A1D21);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);

  static const Color fwiHigh = Color(0xFFDC2626);
  static const Color fwiMed = Color(0xFFEA580C);
  static const Color fwiLow = Color(0xFF16A34A);

  static const Color chartGreen = Color(0xFF22A06B);
  static const Color chartBlue = Color(0xFF3B82F6);
  static const Color chartOrange = Color(0xFFF59E0B);
  static const Color chartRed = Color(0xFFEF4444);
  static const Color chartGrey = Color(0xFFB6BCC6);
}

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.surface,
    ),
    fontFamily: 'Segoe UI',
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: AppColors.textSecondary,
        height: 1.5,
      ),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    ),
  );
}

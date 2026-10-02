import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';

class AppTextTheme {
  AppTextTheme._();

  static TextTheme lightTextTheme = TextTheme(
    headlineLarge: TextStyle().copyWith(
      color: AppColors.textPrimaryLight,
      fontWeight: FontWeight.bold,
      fontSize: 24,
    ),
    headlineMedium: TextStyle().copyWith(
      color: AppColors.textPrimaryLight,
      fontWeight: FontWeight.w600,
      fontSize: 20,
    ),
    headlineSmall: TextStyle().copyWith(
      color: AppColors.textPrimaryLight,
      fontWeight: FontWeight.w600,
      fontSize: 18,
    ),
    titleLarge: TextStyle().copyWith(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimaryLight,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimaryLight,
    ),
    titleSmall: TextStyle().copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimaryLight,
    ),
    bodyLarge: TextStyle().copyWith(
      color: AppColors.textPrimaryLight,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    ),
    bodyMedium: TextStyle().copyWith(
      color: AppColors.textPrimaryLight,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    bodySmall: TextStyle().copyWith(
      color: AppColors.textPrimaryLight,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
  );

  static TextTheme darkTextTheme = TextTheme(
    headlineLarge: TextStyle().copyWith(
      color: AppColors.textPrimaryDark,
      fontWeight: FontWeight.bold,
      fontSize: 24,
    ),
    headlineMedium: TextStyle().copyWith(
      color: AppColors.textPrimaryDark,
      fontWeight: FontWeight.w600,
      fontSize: 20,
    ),
    headlineSmall: TextStyle().copyWith(
      color: AppColors.textPrimaryDark,
      fontWeight: FontWeight.w600,
      fontSize: 18,
    ),
    titleLarge: TextStyle().copyWith(
      fontSize: 16,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimaryDark,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimaryDark,
    ),
    titleSmall: TextStyle().copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimaryDark,
    ),
    bodyLarge: TextStyle().copyWith(
      color: AppColors.textPrimaryDark,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    ),
    bodyMedium: TextStyle().copyWith(
      color: AppColors.textPrimaryDark,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    bodySmall: TextStyle().copyWith(
      color: AppColors.textPrimaryDark,
      fontSize: 12,
      fontWeight: FontWeight.w400,
    ),
  );
}

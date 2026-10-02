import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';

class AppInputDecoration {
  AppInputDecoration._();

  static InputDecorationTheme lightInputDecoration = InputDecorationTheme(
    labelStyle: TextStyle(fontWeight: FontWeight.normal),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(Sizes.p8),
      borderSide: BorderSide(color: AppColors.dividerLight),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(Sizes.p8),
      borderSide: BorderSide(color: AppColors.dividerLight),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(Sizes.p8),
      borderSide: BorderSide(
        color: AppColors.primary.withValues(alpha: 0.5),
        width: 2,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(Sizes.p12),
      borderSide: BorderSide(color: AppColors.error, width: 2),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: Sizes.p16, vertical: 15),
    hintStyle: TextStyle(color: AppColors.textHintLight),
    filled: true,
    fillColor: AppColors.surfaceLight,
  );

  static InputDecorationTheme darkInputDecoration = InputDecorationTheme(
    labelStyle: TextStyle(fontWeight: FontWeight.normal),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(Sizes.p8),
      borderSide: BorderSide(color: AppColors.dividerDark),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(Sizes.p8),
      borderSide: BorderSide(color: AppColors.dividerDark),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(Sizes.p8),
      borderSide: BorderSide(
        color: AppColors.primaryLight.withValues(alpha: 0.5),
        width: 2,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(Sizes.p12),
      borderSide: BorderSide(color: AppColors.error, width: 2),
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: Sizes.p16, vertical: 15),
    hintStyle: TextStyle(color: AppColors.textHintDark),
    filled: true,
    fillColor: AppColors.surfaceDark,
  );
}

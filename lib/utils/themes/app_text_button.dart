import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';

class AppTextButton {
  AppTextButton._();

  static TextButtonThemeData lightTextButton = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      padding: EdgeInsets.symmetric(horizontal: Sizes.p16, vertical: Sizes.p12),
      textStyle: TextStyle(fontSize: Sizes.p16, fontWeight: FontWeight.w600),
    ),
  );

  static TextButtonThemeData darkTextButton = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryDark,
      padding: EdgeInsets.symmetric(horizontal: Sizes.p16, vertical: Sizes.p12),
      textStyle: TextStyle(fontSize: Sizes.p16, fontWeight: FontWeight.w600),
    ),
  );
}

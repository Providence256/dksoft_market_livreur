import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';

class AppElevatedButton {
  AppElevatedButton._();

  static ElevatedButtonThemeData lightElevatedButton = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      shadowColor: AppColors.shadowLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      padding: EdgeInsets.symmetric(horizontal: Sizes.p24, vertical: Sizes.p12),
      textStyle: TextStyle(fontSize: Sizes.p16, fontWeight: FontWeight.w600),
    ),
  );

  static ElevatedButtonThemeData darkElevatedButton = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryDark,
      foregroundColor: Colors.white,
      elevation: 2,
      shadowColor: AppColors.shadowDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      padding: EdgeInsets.symmetric(horizontal: Sizes.p24, vertical: Sizes.p12),
      textStyle: TextStyle(fontSize: Sizes.p16, fontWeight: FontWeight.w600),
    ),
  );
}

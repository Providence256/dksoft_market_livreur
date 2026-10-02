import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';

class AppOutlinedButton {
  AppOutlinedButton._();

  static OutlinedButtonThemeData lightOutlinedButton = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: BorderSide(color: AppColors.primary, width: 1.5),
      shape: BeveledRectangleBorder(
        borderRadius: BorderRadius.circular(Sizes.p12),
      ),
      padding: EdgeInsets.symmetric(horizontal: Sizes.p24, vertical: Sizes.p12),
      textStyle: TextStyle(fontSize: Sizes.p16, fontWeight: FontWeight.w600),
    ),
  );

  static OutlinedButtonThemeData darkOutlinedButton = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryDark,
      side: BorderSide(color: AppColors.primaryDark, width: 1.5),
      shape: BeveledRectangleBorder(
        borderRadius: BorderRadius.circular(Sizes.p12),
      ),
      padding: EdgeInsets.symmetric(horizontal: Sizes.p24, vertical: Sizes.p12),
      textStyle: TextStyle(fontSize: Sizes.p16, fontWeight: FontWeight.w600),
    ),
  );
}

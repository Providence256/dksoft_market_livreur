import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/themes/app_bottom_navigation.dart';
import 'package:dksoft_market_livreur/utils/themes/app_elevated_button.dart';
import 'package:dksoft_market_livreur/utils/themes/app_input_decoration.dart';
import 'package:dksoft_market_livreur/utils/themes/app_outlined_button.dart';
import 'package:dksoft_market_livreur/utils/themes/app_text_button.dart';
import 'package:dksoft_market_livreur/utils/themes/app_text_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  AppTheme._();

  static ThemeData lightTheme = ThemeData(
    fontFamily: 'Poppins',
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    colorScheme: ColorScheme.light(
      primary: AppColors.primary,
      primaryContainer: AppColors.primaryLight,
      onPrimaryFixed: AppColors.shadowLight,
      secondary: AppColors.secondary,
      surface: AppColors.backgroundLight,
      onPrimary: Colors.white,
      onSurface: AppColors.textPrimaryLight,
      error: AppColors.error,
      onError: Colors.white,
      outline: AppColors.dividerLight,
    ),
    scaffoldBackgroundColor: AppColors.backgroundLight,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundLight,
      foregroundColor: AppColors.textPrimaryLight,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
      elevation: 0,
    ),
    iconTheme: IconThemeData(color: AppColors.textPrimaryLight),
    textTheme: AppTextTheme.lightTextTheme,
    elevatedButtonTheme: AppElevatedButton.lightElevatedButton,
    outlinedButtonTheme: AppOutlinedButton.lightOutlinedButton,
    textButtonTheme: AppTextButton.lightTextButton,
    inputDecorationTheme: AppInputDecoration.lightInputDecoration,
    bottomNavigationBarTheme: AppBottomNavigation.lightBottomNavigation,
  );

  static ThemeData darkTheme = ThemeData(
    fontFamily: 'Poppins',
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryDark,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryDark,
      primaryContainer: AppColors.primaryDark,
      onPrimaryFixed: AppColors.shadowDark,
      secondary: AppColors.secondaryDark,
      surface: AppColors.backgroundDark,
      onPrimary: Colors.black,
      onSurface: AppColors.textPrimaryDark,
      error: AppColors.errorDark,
      onError: Colors.black,
      outline: AppColors.dividerDark,
    ),
    scaffoldBackgroundColor: AppColors.backgroundDark,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundDark,
      foregroundColor: AppColors.textPrimaryDark,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryDark,
      ),
      elevation: 0,
    ),
    iconTheme: IconThemeData(color: AppColors.textPrimaryDark),
    textTheme: AppTextTheme.darkTextTheme,
    elevatedButtonTheme: AppElevatedButton.darkElevatedButton,
    outlinedButtonTheme: AppOutlinedButton.darkOutlinedButton,
    textButtonTheme: AppTextButton.darkTextButton,
    inputDecorationTheme: AppInputDecoration.darkInputDecoration,
    bottomNavigationBarTheme: AppBottomNavigation.darkBottomNavigation,
  );
}

import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Thème unique de l'application (clair).
///
/// Échelle typographique, à utiliser plutôt que des `TextStyle` en dur :
/// - `displaySmall` : gros montants (gains, prix d'une course) ;
/// - `headlineMedium` / `headlineSmall` : titres d'écran ;
/// - `titleLarge` / `titleMedium` / `titleSmall` : titres de carte, noms ;
/// - `bodyLarge` / `bodyMedium` : texte courant ;
/// - `bodySmall` : texte secondaire (gris) ;
/// - `labelLarge` : boutons ; `labelMedium` / `labelSmall` : pastilles,
///   légendes.
class AppTheme {
  AppTheme._();

  static const _font = 'Poppins';

  static TextTheme _textThemeOf(AppPalette p) => TextTheme(
    displaySmall: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      height: 1.15,
      letterSpacing: -0.8,
      color: p.textPrimary,
    ),
    headlineMedium: TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.5,
      color: p.textPrimary,
    ),
    headlineSmall: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      height: 1.25,
      letterSpacing: -0.3,
      color: p.textPrimary,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: -0.2,
      color: p.textPrimary,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.35,
      color: p.textPrimary,
    ),
    titleSmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.35,
      color: p.textPrimary,
    ),
    bodyLarge: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w400,
      height: 1.5,
      color: p.textPrimary,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.45,
      color: p.textPrimary,
    ),
    bodySmall: TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w400,
      height: 1.4,
      color: p.textSecondary,
    ),
    labelLarge: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.2,
      color: p.textPrimary,
    ),
    labelMedium: TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w500,
      height: 1.3,
      color: p.textSecondary,
    ),
    labelSmall: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      height: 1.3,
      letterSpacing: 0.3,
      color: p.textSecondary,
    ),
  );

  static final _controlShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(Radii.md),
  );

  static const _controlSize = Size(64, Sizes.controlHeight);

  static OutlineInputBorder _inputBorder([
    Color color = Colors.transparent,
    double width = 1,
  ]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(Radii.md),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  static final lightTheme = _build(AppPalette.light, Brightness.light);
  static final darkTheme = _build(AppPalette.dark, Brightness.dark);

  static ThemeData _build(AppPalette p, Brightness brightness) {
    final textTheme = _textThemeOf(p);
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      extensions: [p],
      fontFamily: _font,
      brightness: brightness,
      colorScheme: (isDark ? ColorScheme.dark : ColorScheme.light)(
        primary: p.primary,
        onPrimary: isDark ? AppColors.primaryDark : Colors.white,
        primaryContainer: p.primarySoft,
        onPrimaryContainer: p.primary,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        secondaryContainer: p.secondarySoft,
        onSecondaryContainer: AppColors.secondaryDark,
        surface: p.surface,
        onSurface: p.textPrimary,
        onSurfaceVariant: p.textSecondary,
        surfaceContainerHighest: p.surfaceMuted,
        error: AppColors.error,
        onError: Colors.white,
        outline: p.border,
        outlineVariant: p.border,
      ),
      scaffoldBackgroundColor: p.background,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        toolbarHeight: 64,
        titleSpacing: Sizes.screenPadding,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.headlineSmall!.copyWith(fontFamily: _font),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: p.surfaceMuted,
          disabledForegroundColor: p.textMuted,
          elevation: 0,
          minimumSize: _controlSize,
          shape: _controlShape,
          padding: const EdgeInsets.symmetric(horizontal: Sizes.p24),
          textStyle: textTheme.labelLarge!.copyWith(fontFamily: _font),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: p.surfaceMuted,
          disabledForegroundColor: p.textMuted,
          minimumSize: _controlSize,
          shape: _controlShape,
          padding: const EdgeInsets.symmetric(horizontal: Sizes.p24),
          textStyle: textTheme.labelLarge!.copyWith(fontFamily: _font),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.textPrimary,
          side: BorderSide(color: p.border, width: 1.2),
          minimumSize: _controlSize,
          shape: _controlShape,
          padding: const EdgeInsets.symmetric(horizontal: Sizes.p24),
          textStyle: textTheme.labelLarge!.copyWith(fontFamily: _font),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          shape: _controlShape,
          padding: const EdgeInsets.symmetric(
            horizontal: Sizes.p12,
            vertical: Sizes.p8,
          ),
          textStyle: textTheme.titleSmall!.copyWith(fontFamily: _font),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: p.textPrimary),
      ),
      iconTheme: IconThemeData(color: p.textPrimary, size: 22),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceMuted,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Sizes.p16,
          vertical: 17,
        ),
        hintStyle: textTheme.bodyLarge!.copyWith(color: p.textMuted),
        labelStyle: textTheme.bodyMedium!.copyWith(color: p.textSecondary),
        errorStyle: textTheme.labelMedium!.copyWith(color: AppColors.error),
        prefixIconColor: p.textMuted,
        suffixIconColor: p.textSecondary,
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
        disabledBorder: _inputBorder(),
        focusedBorder: _inputBorder(p.primary, 1.5),
        errorBorder: _inputBorder(AppColors.error),
        focusedErrorBorder: _inputBorder(AppColors.error, 1.5),
      ),

      cardTheme: CardThemeData(
        color: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.lg),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.border, space: 1, thickness: 1),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: Sizes.p20),
        iconColor: p.textSecondary,
        titleTextStyle: textTheme.bodyLarge!.copyWith(fontFamily: _font),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: p.border,
        dragHandleSize: Size(40, 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
        ),
        titleTextStyle: textTheme.titleLarge!.copyWith(fontFamily: _font),
        contentTextStyle: textTheme.bodyMedium!.copyWith(
          fontFamily: _font,
          color: p.textSecondary,
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.xl),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.textPrimary,
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(
          Sizes.p16,
          0,
          Sizes.p16,
          Sizes.p16,
        ),
        contentTextStyle: textTheme.bodyMedium!.copyWith(
          fontFamily: _font,
          color: p.surface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.success
              : p.border,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? p.primary
              : Colors.transparent,
        ),
        side: BorderSide(color: p.textMuted, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
        linearTrackColor: p.surfaceMuted,
        circularTrackColor: Colors.transparent,
      ),
      badgeTheme: const BadgeThemeData(
        backgroundColor: AppColors.secondary,
        textColor: Colors.white,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.textPrimary,
          borderRadius: BorderRadius.circular(Radii.sm),
        ),
        textStyle: textTheme.labelMedium!.copyWith(
          fontFamily: _font,
          color: p.surface,
        ),
      ),
    );
  }
}

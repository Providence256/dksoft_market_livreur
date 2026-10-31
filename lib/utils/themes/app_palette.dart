import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Couleurs qui changent entre le thème clair et le thème sombre : fonds,
/// textes, bordures, teintes douces, et le bleu de marque utilisé pour les
/// textes / icônes (éclairci en sombre pour rester lisible).
///
/// Les couleurs fixes (orange, vert, rouge, marine des dégradés…) restent
/// dans [AppColors]. Accès : `context.palette.surface`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.primary,
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.primarySoft,
    required this.secondarySoft,
    required this.successSoft,
    required this.warningSoft,
    required this.errorSoft,
    required this.infoSoft,
    required this.amberSoft,
  });

  final Color primary;
  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color primarySoft;
  final Color secondarySoft;
  final Color successSoft;
  final Color warningSoft;
  final Color errorSoft;
  final Color infoSoft;
  final Color amberSoft;

  static const light = AppPalette(
    primary: AppColors.primary,
    background: AppColors.background,
    surface: AppColors.surface,
    surfaceMuted: AppColors.surfaceMuted,
    border: AppColors.border,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textMuted: AppColors.textMuted,
    primarySoft: AppColors.primarySoft,
    secondarySoft: AppColors.secondarySoft,
    successSoft: AppColors.successSoft,
    warningSoft: AppColors.warningSoft,
    errorSoft: AppColors.errorSoft,
    infoSoft: AppColors.infoSoft,
    amberSoft: AppColors.amberSoft,
  );

  static const dark = AppPalette(
    primary: Color(0xFF7FA6F0),
    background: Color(0xFF0C111C),
    surface: Color(0xFF161D2B),
    surfaceMuted: Color(0xFF212A3B),
    border: Color(0xFF2B3548),
    textPrimary: Color(0xFFF1F4F9),
    textSecondary: Color(0xFFA9B2C3),
    textMuted: Color(0xFF6F7B8F),
    primarySoft: Color(0xFF1C2A46),
    secondarySoft: Color(0xFF3A2419),
    successSoft: Color(0xFF12301F),
    warningSoft: Color(0xFF352812),
    errorSoft: Color(0xFF3A1B1D),
    infoSoft: Color(0xFF13283D),
    amberSoft: Color(0xFF332A10),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      primary: mix(primary, other.primary),
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      surfaceMuted: mix(surfaceMuted, other.surfaceMuted),
      border: mix(border, other.border),
      textPrimary: mix(textPrimary, other.textPrimary),
      textSecondary: mix(textSecondary, other.textSecondary),
      textMuted: mix(textMuted, other.textMuted),
      primarySoft: mix(primarySoft, other.primarySoft),
      secondarySoft: mix(secondarySoft, other.secondarySoft),
      successSoft: mix(successSoft, other.successSoft),
      warningSoft: mix(warningSoft, other.warningSoft),
      errorSoft: mix(errorSoft, other.errorSoft),
      infoSoft: mix(infoSoft, other.infoSoft),
      amberSoft: mix(amberSoft, other.amberSoft),
    );
  }
}

extension AppPaletteX on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}

import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Espacements (grille de 4).
class Sizes {
  Sizes._();

  static const p4 = 4.0;
  static const p8 = 8.0;
  static const p12 = 12.0;
  static const p16 = 16.0;
  static const p20 = 20.0;
  static const p24 = 24.0;
  static const p32 = 32.0;
  static const p48 = 48.0;
  static const p64 = 64.0;

  /// Marge horizontale des écrans.
  static const screenPadding = 20.0;

  /// Hauteur des boutons et des champs.
  static const controlHeight = 54.0;
}

/// Rayons d'arrondi.
class Radii {
  Radii._();

  static const sm = 10.0;
  static const md = 14.0;
  static const lg = 20.0;
  static const xl = 28.0;
  static const pill = 999.0;
}

/// Ombres : très douces, elles détachent sans alourdir.
class AppShadows {
  AppShadows._();

  /// Cartes posées sur le fond de l'écran.
  static const card = [
    BoxShadow(color: Color(0x0A101828), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0F101828), blurRadius: 18, offset: Offset(0, 6)),
  ];

  /// Éléments flottants au-dessus d'une carte routière (boutons, bandeaux).
  static const floating = [
    BoxShadow(color: Color(0x14101828), blurRadius: 4, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x1F101828), blurRadius: 24, offset: Offset(0, 8)),
  ];

  /// Panneaux qui montent du bas de l'écran.
  static const sheet = [
    BoxShadow(color: Color(0x1A101828), blurRadius: 24, offset: Offset(0, -4)),
  ];

  /// Halo coloré sous un bouton ou une pastille mise en avant.
  static List<BoxShadow> glow(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.28),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];

  static final primaryGlow = glow(AppColors.primary);
}

const gapW4 = SizedBox(width: Sizes.p4);
const gapW8 = SizedBox(width: Sizes.p8);
const gapW12 = SizedBox(width: Sizes.p12);
const gapW16 = SizedBox(width: Sizes.p16);
const gapW20 = SizedBox(width: Sizes.p20);
const gapW24 = SizedBox(width: Sizes.p24);

const gapH4 = SizedBox(height: Sizes.p4);
const gapH8 = SizedBox(height: Sizes.p8);
const gapH12 = SizedBox(height: Sizes.p12);
const gapH16 = SizedBox(height: Sizes.p16);
const gapH20 = SizedBox(height: Sizes.p20);
const gapH24 = SizedBox(height: Sizes.p24);
const gapH32 = SizedBox(height: Sizes.p32);
const gapH48 = SizedBox(height: Sizes.p48);

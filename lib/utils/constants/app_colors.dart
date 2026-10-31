import 'package:flutter/material.dart';

/// Palette de l'application. Marque Dksoft (marine + orange, partagée avec
/// les apps client et dealer) sur une base claire et neutre.
///
/// Règle d'usage : le marine pour la structure (titres, navigation, boutons
/// principaux), l'orange pour ce qui demande une action ou attire l'œil
/// (demandes, chrono, prochain arrêt). Les teintes `*Soft` servent de fond
/// aux pastilles et icônes.
class AppColors {
  AppColors._();

  // ---- Marque ----
  static const primary = Color(0xFF103166);
  static const primaryDark = Color(0xFF08244D);
  static const primaryLight = Color(0xFF3A63A0);
  static const primarySoft = Color(0xFFEBF0F8);

  static const secondary = Color(0xFFFF6B2D);
  static const secondaryDark = Color(0xFFE0541A);
  static const secondaryLight = Color(0xFFFF9566);
  static const secondarySoft = Color(0xFFFFF0E8);

  // ---- Surfaces ----
  static const background = Color(0xFFF6F7F9);
  static const surface = Color(0xFFFFFFFF);

  /// Fond des champs, tuiles et zones secondaires dans une carte.
  static const surfaceMuted = Color(0xFFF1F3F6);
  static const border = Color(0xFFE6E9EE);

  // ---- Texte ----
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF5B6474);
  static const textMuted = Color(0xFF9AA2AF);

  // ---- États ----
  static const success = Color(0xFF15925A);
  static const successSoft = Color(0xFFE6F6EE);

  static const warning = Color(0xFFB86E00);
  static const warningSoft = Color(0xFFFFF3DE);

  static const error = Color(0xFFD43C3C);
  static const errorSoft = Color(0xFFFDECEC);

  static const info = Color(0xFF1769AA);
  static const infoSoft = Color(0xFFE5F1FB);

  /// Notes et étoiles.
  static const amber = Color(0xFFE9A100);
  static const amberSoft = Color(0xFFFFF5DB);
}

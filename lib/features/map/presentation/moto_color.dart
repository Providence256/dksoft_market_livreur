import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Couleur de la moto choisie par le livreur à l'inscription (voir
/// `kMotoColors`). « Autre » ou une valeur inconnue : la couleur de l'app.
Color motoColorOf(String? name) {
  switch (name?.trim().toLowerCase()) {
    case 'noir':
      return const Color(0xFF22262E);
    case 'rouge':
      return const Color(0xFFD62828);
    case 'bleu':
      return const Color(0xFF1E5BD8);
    case 'blanc':
      return const Color(0xFFF1F3F6);
    case 'gris':
      return const Color(0xFF8E96A4);
    case 'vert':
      return const Color(0xFF1E9E55);
    case 'jaune':
      return const Color(0xFFF5B800);
    case 'orange':
      return const Color(0xFFFF6B2D);
    default:
      return AppColors.primary;
  }
}

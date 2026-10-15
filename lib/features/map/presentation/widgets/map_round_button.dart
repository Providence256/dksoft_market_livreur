import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Bouton rond blanc posé sur la carte (ma position, vue d'ensemble…).
class MapRoundButton extends StatelessWidget {
  const MapRoundButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.filled = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  /// Version pleine orange (bouton de localisation du modèle).
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.secondary : Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black38,
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, color: filled ? Colors.white : AppColors.primary),
        onPressed: onPressed,
      ),
    );
  }
}

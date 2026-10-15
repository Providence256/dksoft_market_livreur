import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Bouton carré blanc aux coins arrondis, avec pastille orange facultative
/// (la cloche de l'accueil).
class SquareIconButton extends StatelessWidget {
  const SquareIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.showDot = false,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final bool showDot;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.dividerLight),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: AppColors.primary, size: 24),
                if (showDot)
                  Positioned(
                    top: 13,
                    right: 14,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

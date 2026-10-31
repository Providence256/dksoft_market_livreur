import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:flutter/material.dart';

/// Icône sur un carré arrondi teinté de sa propre couleur.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
    this.radius = Radii.md,
    this.background,
  });

  final AppIconData icon;
  final Color color;
  final double size;
  final double radius;

  /// Fond ; par défaut une teinte légère de [color].
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: AppIcon(icon, color: color, size: size * 0.48),
    );
  }
}

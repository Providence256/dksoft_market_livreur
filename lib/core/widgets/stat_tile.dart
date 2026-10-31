import 'package:dksoft_market_livreur/core/animations/motion.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';

/// Chiffre clé sur une tuile teintée : icône dans un carré blanc, valeur,
/// libellé dans la couleur de la tuile.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.color,
    required this.background,
    required this.value,
    required this.label,
    this.onTap,
  });

  final AppIconData icon;
  final Color color;
  final Color background;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final tile = Container(
      padding: const EdgeInsets.all(Sizes.p12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.palette.surface,
                  borderRadius: BorderRadius.circular(Radii.sm),
                ),
                child: Center(child: AppIcon(icon, size: 19, color: color)),
              ),
            ],
          ),
          gapH12,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(height: 1.1),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(color: color),
          ),
        ],
      ),
    );

    if (onTap == null) return tile;
    return Pressable(onTap: onTap, child: tile);
  }
}

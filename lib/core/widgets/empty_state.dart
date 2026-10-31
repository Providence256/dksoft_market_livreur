import 'package:dksoft_market_livreur/core/widgets/icon_tile.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';

/// Message centré avec une icône, pour les listes vides et les erreurs.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.color,
  });

  final AppIconData icon;
  final String title;
  final String message;
  final Widget? action;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(Sizes.p32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTile(
              icon: icon,
              color: color ?? context.palette.primary,
              size: 80,
              radius: Radii.xl,
            ),
            gapH20,
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            gapH8,
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.palette.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[gapH24, action!],
          ],
        ),
      ),
    );
  }
}

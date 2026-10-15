import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';

/// Message centré avec grande icône, pour les listes vides et les erreurs.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Sizes.p32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppColors.primary),
            ),
            gapH20,
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            gapH8,
            Text(
              message,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.textSecondaryLight,
                fontWeight: FontWeight.w400,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[gapH20, action!],
          ],
        ),
      ),
    );
  }
}

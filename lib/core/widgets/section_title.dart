import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Titre de section, avec une action facultative à droite.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.secondaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

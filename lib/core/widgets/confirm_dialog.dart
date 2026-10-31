import 'package:dksoft_market_livreur/core/widgets/app_button.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/core/widgets/icon_tile.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';

/// Demande une confirmation. Renvoie true si l'utilisateur confirme.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  AppIconData icon = AppIcons.help,
  bool destructive = false,
}) async {
  final color = destructive ? AppColors.error : context.palette.primary;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final theme = Theme.of(context);
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: Sizes.p24),
        child: Padding(
          padding: const EdgeInsets.all(Sizes.p24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTile(icon: icon, color: color, size: 56, radius: Radii.lg),
              gapH16,
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge,
              ),
              gapH8,
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: context.palette.textSecondary,
                ),
              ),
              gapH24,
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Annuler',
                      variant: AppButtonVariant.tonal,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  gapW12,
                  Expanded(
                    child: AppButton(
                      label: confirmLabel,
                      variant: destructive
                          ? AppButtonVariant.danger
                          : AppButtonVariant.primary,
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
  return confirmed ?? false;
}

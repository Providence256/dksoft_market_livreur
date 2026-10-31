import 'package:dksoft_market_livreur/features/map/data/location_repository.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';

/// Bandeau d'avertissement flottant sur une carte, avec une action
/// facultative.
class MapNotice extends StatelessWidget {
  const MapNotice({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final AppIconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        Sizes.p12,
        Sizes.p8,
        actionLabel == null ? Sizes.p12 : Sizes.p4,
        Sizes.p8,
      ),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(Radii.md),
        boxShadow: AppShadows.floating,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: context.palette.warningSoft,
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            child: AppIcon(icon, size: 18, color: AppColors.warning),
          ),
          gapW12,
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.palette.textPrimary,
              ),
            ),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// Affiché quand la position du motard n'est pas disponible, avec l'action
/// qui permet de la rétablir.
class LocationBanner extends StatelessWidget {
  const LocationBanner({
    super.key,
    required this.access,
    required this.onAction,
  });

  final LocationAccess access;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final (message, actionLabel) = switch (access) {
      LocationAccess.serviceDisabled => (
        'La localisation est désactivée sur votre téléphone.',
        'Activer',
      ),
      LocationAccess.deniedForever => (
        "L'accès à la position est bloqué. Autorisez-le dans les réglages.",
        'Réglages',
      ),
      _ => (
        'Autorisez la localisation pour voir votre position sur la carte.',
        'Autoriser',
      ),
    };

    return MapNotice(
      icon: AppIcons.locationOff,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

import 'package:dksoft_market_livreur/features/map/data/location_repository.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';

/// Bandeau affiché sur la carte quand la position du motard n'est pas
/// disponible, avec l'action qui permet de la rétablir.
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
    final theme = Theme.of(context);

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

    return Material(
      color: AppColors.warningLight,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Sizes.p12,
          vertical: Sizes.p8,
        ),
        child: Row(
          children: [
            const Icon(Icons.location_off_outlined, color: AppColors.warning),
            gapW8,
            Expanded(child: Text(message, style: theme.textTheme.labelMedium)),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

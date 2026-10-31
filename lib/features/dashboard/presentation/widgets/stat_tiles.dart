import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/core/widgets/stat_tile.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';

/// Trois chiffres clés sur des tuiles teintées : livraisons, note,
/// demandes en attente (cette dernière mène à l'onglet Demandes).
class StatTiles extends StatelessWidget {
  const StatTiles({
    super.key,
    required this.deliveries,
    required this.rating,
    required this.ratingCount,
    required this.requests,
    required this.onRequestsTap,
    required this.onRatingTap,
  });

  final int deliveries;

  /// Note moyenne, null tant qu'aucune livraison n'est notée.
  final double? rating;
  final int ratingCount;
  final int requests;
  final VoidCallback onRequestsTap;
  final VoidCallback onRatingTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatTile(
            icon: AppIcons.delivered,
            color: context.palette.primary,
            background: context.palette.primarySoft,
            value: '$deliveries',
            label: 'Livraisons',
          ),
        ),
        gapW12,
        Expanded(
          child: StatTile(
            icon: AppIcons.star,
            color: AppColors.amber,
            background: context.palette.amberSoft,
            value: rating == null ? '—' : rating!.toStringAsFixed(1),
            label: ratingCount == 0 ? 'Note' : '$ratingCount avis',
            onTap: onRatingTap,
          ),
        ),
        gapW12,
        Expanded(
          child: StatTile(
            icon: AppIcons.bell,
            color: AppColors.secondaryDark,
            background: context.palette.secondarySoft,
            value: '$requests',
            label: 'Demandes',
            onTap: onRequestsTap,
          ),
        ),
      ],
    );
  }
}

import 'package:dksoft_market_livreur/core/widgets/pill.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/features/map/data/location_repository.dart';
import 'package:dksoft_market_livreur/features/map/presentation/widgets/elapsed_timer_pill.dart';
import 'package:dksoft_market_livreur/features/map/presentation/widgets/location_banner.dart';
import 'package:dksoft_market_livreur/features/map/presentation/widgets/map_round_button.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/helpers/distance_format.dart';
import 'package:dksoft_market_livreur/utils/helpers/duration_format.dart';
import 'package:flutter/material.dart';

/// Haut de la carte d'une course (hors navigation) : retour, étape de la
/// course, chrono et distance jusqu'au prochain arrêt, puis les
/// avertissements éventuels.
class DeliveryMapHeader extends StatelessWidget {
  const DeliveryMapHeader({
    super.key,
    required this.title,
    required this.assignedAt,
    required this.legMeters,
    required this.legSeconds,
    required this.onBack,
    required this.simulating,
    required this.farAway,
    required this.access,
    required this.onFixLocation,
    required this.missingGps,
  });

  final String title;
  final DateTime? assignedAt;
  final double? legMeters;
  final double? legSeconds;

  /// Null quand la carte est affichée comme onglet (pas de retour).
  final VoidCallback? onBack;
  final bool simulating;
  final bool farAway;
  final LocationAccess? access;
  final VoidCallback onFixLocation;

  /// Nombre d'arrêts sans coordonnées GPS.
  final int missingGps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final access = this.access;

    return Column(
      children: [
        Row(
          children: [
            if (onBack != null)
              MapRoundButton(
                icon: AppIcons.back,
                tooltip: 'Retour',
                onPressed: onBack!,
              ),
            if (onBack != null) gapW8,
            Expanded(
              child: MapGlass(
                radius: Radii.md,
                padding: const EdgeInsets.symmetric(horizontal: Sizes.p12),
                child: SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                      if (legMeters != null)
                        Text(
                          legSeconds == null
                              ? formatDistance(legMeters!)
                              : '${formatDistance(legMeters!)} · '
                                    '${formatDuration(legSeconds!)}',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: context.palette.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            gapW8,
            ElapsedTimerPill(since: assignedAt),
          ],
        ),
        if (simulating) ...[
          gapH8,
          const Pill(
            label: 'Déplacement simulé (test)',
            tone: PillTone.warning,
            icon: AppIcons.test,
          ),
        ] else if (farAway) ...[
          gapH8,
          const Pill(
            label: 'Position hors de Kinshasa',
            tone: PillTone.warning,
            icon: AppIcons.locationOff,
          ),
        ],
        if (access != null && access != LocationAccess.granted) ...[
          gapH8,
          LocationBanner(access: access, onAction: onFixLocation),
        ],
        if (missingGps > 0) ...[
          gapH8,
          MapNotice(
            icon: AppIcons.info,
            message:
                '$missingGps arrêt${missingGps > 1 ? 's' : ''} sans position '
                'GPS : non affiché sur la carte.',
          ),
        ],
      ],
    );
  }
}

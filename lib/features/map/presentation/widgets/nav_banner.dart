import 'package:dksoft_market_livreur/features/map/presentation/map_stop.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/features/map/presentation/widgets/stops_sheet.dart';
import 'package:dksoft_market_livreur/features/routing/domain/route_info.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/helpers/distance_format.dart';
import 'package:dksoft_market_livreur/utils/helpers/duration_format.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Bandeau de navigation : prochaine manœuvre, rue, distance restante.
class NavBanner extends StatelessWidget {
  const NavBanner({
    super.key,
    required this.route,
    required this.rider,
    required this.stop,
    required this.legMeters,
    required this.legSeconds,
    required this.onQuit,
  });

  final RouteInfo? route;
  final LatLng? rider;
  final MapStop stop;
  final double? legMeters;
  final double? legSeconds;
  final VoidCallback onQuit;

  static AppIconData _iconOf(RouteStep step) {
    if (step.isArrive) return AppIcons.flag;
    if (step.type.contains('round')) return AppIcons.roundabout;
    final m = step.modifier;
    if (m == 'uturn') return AppIcons.uTurn;
    if (m.startsWith('slight')) {
      return m.contains('left') ? AppIcons.slightLeft : AppIcons.slightRight;
    }
    if (m.contains('left')) return AppIcons.turnLeft;
    if (m.contains('right')) return AppIcons.turnRight;
    return AppIcons.straight;
  }

  static double _distance(LatLng a, LatLng b) => Geolocator.distanceBetween(
    a.latitude,
    a.longitude,
    b.latitude,
    b.longitude,
  );

  /// Première manœuvre encore devant nous (on ignore le départ et celles
  /// qu'on vient de passer).
  RouteStep? _nextStep() {
    final here = rider;
    for (final step in route?.firstLegSteps ?? const <RouteStep>[]) {
      if (step.isDepart) continue;
      if (here == null) return step;
      if (_distance(here, step.location) > 25 || step.isArrive) return step;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final here = rider;
    final target = stop.position;
    final toStop = (here != null && target != null)
        ? _distance(here, target)
        : null;
    final arrived = toStop != null && toStop <= StopsSheet.arrivalRadius;

    final step = arrived ? null : _nextStep();
    final distToStep = (step != null && here != null)
        ? _distance(here, step.location)
        : null;

    final String headline;
    final String? sub;
    final AppIconData icon;
    if (arrived) {
      icon = AppIcons.flag;
      headline = 'Vous êtes arrivé';
      sub = stop.isDealer ? stop.place.name : 'Chez ${stop.place.name}';
    } else if (step != null) {
      icon = _iconOf(step);
      headline = distToStep == null
          ? step.instruction
          : 'Dans ${formatDistance(distToStep)}';
      sub = distToStep == null
          ? (step.street.isEmpty ? null : step.street)
          : step.street.isEmpty
          ? step.instruction
          : '${step.instruction} · ${step.street}';
    } else {
      icon = AppIcons.straight;
      headline = 'Suivez le tracé';
      sub = 'Direction ${stop.place.name}';
    }

    final remaining = legMeters == null
        ? null
        : legSeconds == null
        ? '${formatDistance(legMeters!)} restants'
        : '${formatDistance(legMeters!)} · ${formatDuration(legSeconds!)}';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      decoration: BoxDecoration(
        color: context.palette.primary,
        borderRadius: BorderRadius.circular(Radii.lg),
        boxShadow: AppShadows.floating,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: AppIcon(icon, size: 34, color: Colors.white),
          ),
          gapW12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13.5,
                    ),
                  ),
                if (remaining != null) ...[
                  gapH4,
                  Text(
                    remaining,
                    style: const TextStyle(
                      color: AppColors.secondaryLight,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Quitter la navigation',
            onPressed: onQuit,
            icon: const AppIcon(AppIcons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

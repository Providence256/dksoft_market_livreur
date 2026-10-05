import 'package:dksoft_market_livreur/features/deliveries/domain/delivery_model.dart';
import 'package:dksoft_market_livreur/features/map/presentation/map_stop.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/helpers/distance_format.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// Panneau déroulant au bas de la carte : prochain arrêt, bouton
/// « Naviguer » et liste des étapes. Un tap sur une étape centre la carte
/// dessus.
class StopsSheet extends StatelessWidget {
  const StopsSheet({
    super.key,
    required this.stops,
    required this.riderPosition,
    required this.onNavigate,
    required this.onFocus,
  });

  final List<MapStop> stops;
  final Position? riderPosition;
  final void Function(MapStop stop) onNavigate;
  final void Function(MapStop stop) onFocus;

  /// Distance à vol d'oiseau entre le motard et un arrêt (null si l'une
  /// des deux positions manque). L'itinéraire routier (distance et durée
  /// réelles) arrive avec l'étape suivante.
  double? _distanceTo(MapStop stop) {
    final rider = riderPosition;
    final target = stop.position;
    if (rider == null || target == null) return null;
    return Geolocator.distanceBetween(
      rider.latitude,
      rider.longitude,
      target.latitude,
      target.longitude,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final next = MapStop.next(stops);

    return DraggableScrollableSheet(
      initialChildSize: 0.3,
      minChildSize: 0.14,
      maxChildSize: 0.62,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 12,
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              Sizes.p16,
              Sizes.p8,
              Sizes.p16,
              Sizes.p24,
            ),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.dividerLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              gapH12,

              // ---- Prochain arrêt ----
              if (next != null) ...[
                Text(
                  next.isDealer
                      ? 'Prochaine étape : le dealer'
                      : 'Prochain arrêt',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                gapH4,
                Text(next.place.name, style: theme.textTheme.titleMedium),
                Text(
                  '${next.place.address} · ${next.place.commune}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                if (_distanceTo(next) case final distance?) ...[
                  gapH4,
                  Text(
                    '≈ ${formatDistance(distance)} · à vol d\'oiseau',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ],
                gapH12,
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => onNavigate(next),
                    icon: const Icon(Icons.navigation_outlined, size: 20),
                    label: const Text('Naviguer'),
                  ),
                ),
                gapH16,
                const Divider(height: 1, color: AppColors.dividerLight),
                gapH12,
              ] else ...[
                Text(
                  'Tous les arrêts sont terminés.',
                  style: theme.textTheme.titleMedium,
                ),
                gapH12,
              ],

              // ---- Liste des étapes ----
              Text('Étapes', style: theme.textTheme.titleMedium),
              gapH8,
              for (final stop in stops)
                _StopTile(
                  stop: stop,
                  isNext: stop == next,
                  distance: stop.isPending ? _distanceTo(stop) : null,
                  onTap: stop.position == null ? null : () => onFocus(stop),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StopTile extends StatelessWidget {
  const _StopTile({
    required this.stop,
    required this.isNext,
    required this.distance,
    required this.onTap,
  });

  final MapStop stop;
  final bool isNext;
  final double? distance;
  final VoidCallback? onTap;

  Color get _color {
    if (stop.isDealer) return AppColors.secondary;
    return switch (stop.status) {
      PickupStatus.collected => AppColors.success,
      PickupStatus.unavailable => AppColors.error,
      _ => AppColors.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPosition = stop.position != null;

    final subtitle = stop.isDealer
        ? 'Remise au dealer · ${stop.place.commune}'
        : '${stop.place.commune} · ${stop.itemsCount} '
              'article${stop.itemsCount > 1 ? 's' : ''}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: Sizes.p8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: _color,
              child: stop.isDealer
                  ? const Icon(Icons.flag, size: 16, color: Colors.white)
                  : switch (stop.status) {
                      PickupStatus.collected => const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      ),
                      PickupStatus.unavailable => const Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.white,
                      ),
                      _ => Text(
                        '${stop.order + 1}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    },
            ),
            gapW12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop.place.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isNext ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                  Text(
                    hasPosition
                        ? subtitle
                        : '$subtitle · position GPS manquante',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: hasPosition
                          ? AppColors.textSecondaryLight
                          : AppColors.warning,
                    ),
                  ),
                ],
              ),
            ),
            if (distance != null)
              Text(
                formatDistance(distance!),
                style: theme.textTheme.labelMedium,
              )
            else if (!stop.isPending && !stop.isDealer)
              Text(
                stop.status?.label ?? '',
                style: theme.textTheme.labelSmall?.copyWith(color: _color),
              ),
          ],
        ),
      ),
    );
  }
}

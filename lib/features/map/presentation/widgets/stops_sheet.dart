import 'package:dksoft_market_livreur/core/widgets/stop_badge.dart';
import 'package:dksoft_market_livreur/features/deliveries/domain/delivery_model.dart';
import 'package:dksoft_market_livreur/features/map/presentation/map_stop.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/helpers/distance_format.dart';
import 'package:dksoft_market_livreur/utils/helpers/external_launcher.dart';
import 'package:flutter/material.dart';
import 'package:dksoft_market_livreur/utils/helpers/duration_format.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Panneau du bas de l'écran « En route » : l'arrêt en cours (nom, appel,
/// navigation), distance et articles, le gros bouton d'action, puis — en
/// faisant glisser — la liste de tous les arrêts.
class StopsSheet extends StatelessWidget {
  const StopsSheet({
    super.key,
    required this.stops,
    required this.riderPoint,
    this.nextLegMeters,
    this.nextLegSeconds,
    required this.initialFraction,
    required this.busy,
    required this.onNavigate,
    required this.onFocus,
    required this.onCollected,
    required this.onUnavailable,
    required this.onComplete,
  });

  final List<MapStop> stops;
  final LatLng? riderPoint;

  /// Distance et durée routières jusqu'au prochain arrêt (si connues).
  final double? nextLegMeters;
  final double? nextLegSeconds;

  /// Hauteur de départ (et minimale) du panneau, en fraction de l'écran :
  /// juste assez pour voir l'arrêt, les infos et le bouton.
  final double initialFraction;
  final bool busy;
  final void Function(MapStop stop) onNavigate;
  final void Function(MapStop stop) onFocus;
  final void Function(MapStop stop) onCollected;
  final void Function(MapStop stop) onUnavailable;
  final VoidCallback onComplete;

  /// Distance à vol d'oiseau entre le motard et un arrêt (null si l'une
  /// des deux positions manque).
  double? _distanceTo(MapStop stop) {
    final rider = riderPoint;
    final target = stop.position;
    if (rider == null || target == null) return null;
    return Geolocator.distanceBetween(
      rider.latitude,
      rider.longitude,
      target.latitude,
      target.longitude,
    );
  }

  /// Rayon (en mètres) à partir duquel le motard est considéré comme
  /// arrivé : assez large pour absorber l'imprécision du GPS en ville.
  static const arrivalRadius = 150.0;

  /// Le motard est-il arrivé à l'arrêt ? Sans position GPS ou sans
  /// coordonnées d'arrêt on ne peut pas le savoir : le bouton reste alors
  /// disponible pour ne pas bloquer la course.
  bool _hasArrived(MapStop stop) {
    final distance = _distanceTo(stop);
    if (distance == null) return true;
    return distance <= arrivalRadius;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final next = MapStop.next(stops);

    return DraggableScrollableSheet(
      initialChildSize: initialFraction,
      minChildSize: initialFraction,
      maxChildSize: 0.9,
      snap: true,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.14),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              Sizes.p16,
              Sizes.p8,
              Sizes.p16,
              Sizes.p32,
            ),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.dividerLight,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              gapH16,

              if (next != null) ...[
                _CurrentStop(
                  stop: next,
                  total: stops.length - 1,
                  onNavigate: () => onNavigate(next),
                ),
                gapH12,
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.route_rounded,
                        label: 'Distance',
                        value: nextLegMeters != null
                            ? formatDistance(nextLegMeters!)
                            : _distanceTo(next) == null
                            ? '—'
                            : '≈ ${formatDistance(_distanceTo(next)!)}',
                      ),
                    ),
                    gapW12,
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.schedule_rounded,
                        label: 'Durée',
                        value: nextLegSeconds != null
                            ? formatDuration(nextLegSeconds!)
                            : '—',
                      ),
                    ),
                  ],
                ),
                gapH16,
                if (!_hasArrived(next)) ...[
                  _EnRouteHint(
                    stop: next,
                    meters: _distanceTo(next),
                    onNavigate: () => onNavigate(next),
                  ),
                ] else ...[
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: busy
                          ? null
                          : () => next.isDealer
                                ? onComplete()
                                : onCollected(next),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: next.isDealer
                            ? AppColors.success
                            : AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              next.isDealer
                                  ? 'Marquer comme livré'
                                  : 'Marquer comme récupéré',
                            ),
                    ),
                  ),
                  if (!next.isDealer)
                    Center(
                      child: TextButton(
                        onPressed: busy ? null : () => onUnavailable(next),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                        ),
                        child: const Text('Article indisponible'),
                      ),
                    ),
                ],

                // ---- Articles de l'arrêt en cours ----
                if (next.items.isNotEmpty) ...[
                  gapH8,
                  Text(
                    'À récupérer chez ${next.place.name}',
                    style: theme.textTheme.titleMedium,
                  ),
                  gapH8,
                  for (final item in next.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          Text(
                            '× ${item.quantity}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                ],
              ] else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Sizes.p16),
                  child: Text(
                    'Tous les arrêts sont terminés.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              gapH24,

              // ---- Frise des arrêts ----
              Text('Tous les arrêts', style: theme.textTheme.titleMedium),
              gapH12,
              for (final (index, stop) in stops.indexed)
                _StopTile(
                  stop: stop,
                  isNext: identical(stop, next),
                  isLast: index == stops.length - 1,
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

/// L'arrêt en cours : pastille, nom, rôle, et boutons appel / navigation.
class _CurrentStop extends StatelessWidget {
  const _CurrentStop({
    required this.stop,
    required this.total,
    required this.onNavigate,
  });

  final MapStop stop;

  /// Nombre de commerçants de la course.
  final int total;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phone = stop.place.phone;
    final hasPhone = phone != null && phone.isNotEmpty;

    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: stop.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            stop.isDealer ? Icons.flag_rounded : Icons.storefront_rounded,
            color: stop.color,
            size: 26,
          ),
        ),
        gapW12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stop.place.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(fontSize: 17),
              ),
              Text(
                stop.isDealer
                    ? 'Dealer · ${stop.place.commune}'
                    : 'Commerçant ${stop.order + 1} sur $total'
                          ' · ${stop.itemsCount} article'
                          '${stop.itemsCount > 1 ? 's' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
        if (hasPhone)
          IconButton(
            tooltip: 'Appeler',
            onPressed: () => callPhone(phone),
            icon: const Icon(Icons.call_rounded, color: AppColors.primary),
          ),
        IconButton(
          tooltip: 'Naviguer',
          onPressed: onNavigate,
          icon: const Icon(
            Icons.navigation_rounded,
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(Sizes.p12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.dividerLight),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 19, color: AppColors.primary),
          ),
          gapW8,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StopTile extends StatelessWidget {
  const _StopTile({
    required this.stop,
    required this.isNext,
    required this.isLast,
    required this.distance,
    required this.onTap,
  });

  final MapStop stop;
  final bool isNext;
  final bool isLast;
  final double? distance;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPosition = stop.position != null;

    final subtitle = stop.isDealer
        ? 'Remise au dealer · ${stop.place.commune}'
        : '${stop.place.commune} · ${stop.itemsCount} '
              'article${stop.itemsCount > 1 ? 's' : ''}';

    final badge = stop.isDealer
        ? const StopBadge(icon: Icons.flag_rounded, color: AppColors.primary)
        : switch (stop.status) {
            PickupStatus.collected => const StopBadge(
              icon: Icons.check_rounded,
              color: AppColors.success,
            ),
            PickupStatus.unavailable => const StopBadge(
              icon: Icons.close_rounded,
              color: AppColors.error,
            ),
            _ => StopBadge(
              label: '${stop.order + 1}',
              color: AppColors.secondary,
            ),
          };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 30,
              child: Column(
                children: [
                  badge,
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        color: stop.status == PickupStatus.collected
                            ? AppColors.success
                            : AppColors.dividerLight,
                      ),
                    ),
                ],
              ),
            ),
            gapW12,
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: Sizes.p16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            stop.place.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: isNext
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (distance != null)
                          Text(
                            formatDistance(distance!),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else if (!stop.isPending && !stop.isDealer)
                          Text(
                            stop.status?.label ?? '',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: stop.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    Text(
                      hasPosition
                          ? subtitle
                          : '$subtitle · position GPS manquante',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: hasPosition
                            ? AppColors.textSecondaryLight
                            : AppColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Affiché tant que le motard n'est pas arrivé : le bouton de validation
/// n'apparaît qu'une fois sur place.
class _EnRouteHint extends StatelessWidget {
  const _EnRouteHint({
    required this.stop,
    required this.meters,
    required this.onNavigate,
  });

  final MapStop stop;
  final double? meters;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = stop.isDealer ? 'le dealer' : stop.place.name;

    return Container(
      padding: const EdgeInsets.all(Sizes.p16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.near_me_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              gapW8,
              Expanded(
                child: Text(
                  meters == null
                      ? 'Rendez-vous chez $target'
                      : 'Encore ${formatDistance(meters!)} jusqu\'à $target',
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ],
          ),
          gapH4,
          Text(
            stop.isDealer
                ? 'Le bouton « Marquer comme livré » apparaîtra à votre '
                      'arrivée chez le dealer.'
                : 'Le bouton « Marquer comme récupéré » apparaîtra à votre '
                      'arrivée chez le commerçant.',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondaryLight,
              height: 1.4,
            ),
          ),
          gapH12,
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onNavigate,
              icon: const Icon(Icons.navigation_rounded, size: 20),
              label: const Text('Démarrer la navigation'),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

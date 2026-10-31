import 'package:dksoft_market_livreur/core/widgets/app_button.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/core/widgets/icon_tile.dart';
import 'package:dksoft_market_livreur/features/map/presentation/map_stop.dart';
import 'package:dksoft_market_livreur/features/map/presentation/widgets/stop_timeline.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/helpers/distance_format.dart';
import 'package:dksoft_market_livreur/utils/helpers/duration_format.dart';
import 'package:dksoft_market_livreur/utils/helpers/external_launcher.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Panneau du bas de l'écran « En route » : l'arrêt en cours (nom, appel,
/// navigation), distance et durée, le gros bouton d'action, puis — en
/// faisant glisser — les articles et la liste de tous les arrêts.
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
    required this.onIncident,
    this.bottomInset = 0,
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

  /// Chez le dealer : impossible de remettre le colis (absent, adresse).
  final VoidCallback onIncident;

  /// Place occupée en bas par la barre de navigation flottante.
  final double bottomInset;

  /// Rayon (en mètres) à partir duquel le motard est considéré comme
  /// arrivé : assez large pour absorber l'imprécision du GPS en ville.
  static const arrivalRadius = 150.0;

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

  /// Le motard est-il arrivé à l'arrêt ? Sans position GPS ou sans
  /// coordonnées d'arrêt on ne peut pas le savoir : le bouton reste alors
  /// disponible pour ne pas bloquer la course.
  bool _hasArrived(MapStop stop) {
    final distance = _distanceTo(stop);
    return distance == null || distance <= arrivalRadius;
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
        return DecoratedBox(
          decoration: BoxDecoration(
            color: context.palette.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
            boxShadow: AppShadows.sheet,
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(
              Sizes.screenPadding,
              Sizes.p12,
              Sizes.screenPadding,
              Sizes.p32 + bottomInset,
            ),
            children: [
              const _DragHandle(),
              gapH16,
              if (next != null) ...[
                _CurrentStop(
                  stop: next,
                  total: stops.length - 1,
                  onNavigate: () => onNavigate(next),
                ),
                gapH16,
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        icon: AppIcons.route,
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
                        icon: AppIcons.clock,
                        label: 'Durée',
                        value: nextLegSeconds != null
                            ? formatDuration(nextLegSeconds!)
                            : '—',
                      ),
                    ),
                  ],
                ),
                gapH16,
                if (!_hasArrived(next))
                  _EnRouteHint(
                    stop: next,
                    meters: _distanceTo(next),
                    onNavigate: () => onNavigate(next),
                  )
                else ...[
                  AppButton(
                    label: next.isDealer
                        ? 'Marquer comme livré'
                        : 'Marquer comme récupéré',
                    icon: next.isDealer ? AppIcons.delivered : AppIcons.package,
                    variant: next.isDealer
                        ? AppButtonVariant.success
                        : AppButtonVariant.primary,
                    loading: busy,
                    height: 58,
                    onPressed: () =>
                        next.isDealer ? onComplete() : onCollected(next),
                  ),
                  gapH4,
                  Center(
                    child: TextButton.icon(
                      onPressed: busy
                          ? null
                          : next.isDealer
                          ? onIncident
                          : () => onUnavailable(next),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      icon: const AppIcon(AppIcons.alert, size: 18),
                      label: Text(
                        next.isDealer
                            ? 'Signaler un problème'
                            : 'Article indisponible',
                      ),
                    ),
                  ),
                ],

                // ---- Articles de l'arrêt en cours ----
                if (next.items.isNotEmpty) ...[gapH16, _ItemsCard(stop: next)],
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
              Text('Itinéraire', style: theme.textTheme.titleMedium),
              gapH12,
              for (final (index, stop) in stops.indexed)
                StopTimelineTile(
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

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: context.palette.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// L'arrêt en cours : icône, nom, rôle, et boutons appel / navigation.
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
        IconTile(
          icon: stop.isDealer ? AppIcons.flag : AppIcons.store,
          color: stop.color,
          size: 52,
          radius: Radii.lg,
        ),
        gapW12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stop.isDealer
                    ? 'REMISE AU DEALER'
                    : 'COMMERÇANT ${stop.order + 1} SUR $total',
                style: theme.textTheme.labelSmall?.copyWith(color: stop.color),
              ),
              Text(
                stop.place.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge,
              ),
              Text(
                stop.isDealer
                    ? stop.place.commune
                    : '${stop.place.commune} · ${stop.itemsCount} article'
                          '${stop.itemsCount > 1 ? 's' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        if (hasPhone) ...[
          _RoundAction(
            icon: AppIcons.call,
            tooltip: 'Appeler',
            color: AppColors.success,
            onPressed: () => callPhone(phone),
          ),
          gapW8,
        ],
        _RoundAction(
          icon: AppIcons.navigation,
          tooltip: 'Naviguer',
          color: context.palette.primary,
          onPressed: onNavigate,
        ),
      ],
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  final AppIconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        fixedSize: const Size.square(46),
      ),
      icon: AppIcon(icon, size: 22),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final AppIconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(Sizes.p12),
      decoration: BoxDecoration(
        color: context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        children: [
          AppIcon(icon, size: 20, color: context.palette.textSecondary),
          gapW8,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.labelMedium),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: theme.textTheme.titleMedium),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Articles à récupérer chez le commerçant en cours.
class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.stop});

  final MapStop stop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(Sizes.p16),
      decoration: BoxDecoration(
        color: context.palette.surfaceMuted,
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'À récupérer chez ${stop.place.name}',
            style: theme.textTheme.titleSmall,
          ),
          gapH8,
          for (final item in stop.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(item.name, style: theme.textTheme.bodyMedium),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: context.palette.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '× ${item.quantity}',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
            ),
        ],
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
    final target = stop.isDealer ? 'le dealer' : stop.place.name;
    final distance = meters == null
        ? 'Rendez-vous chez $target.'
        : 'Encore ${formatDistance(meters!)} jusqu\'à $target.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppButton(
          label: 'Démarrer la navigation',
          icon: AppIcons.navigation,
          variant: AppButtonVariant.accent,
          height: 58,
          onPressed: onNavigate,
        ),
        gapH12,
        Text(
          '$distance Le bouton de validation apparaîtra à votre arrivée.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

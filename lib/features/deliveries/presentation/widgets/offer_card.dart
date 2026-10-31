import 'package:dksoft_market_livreur/core/data/livreur_repository.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/core/widgets/app_button.dart';
import 'package:dksoft_market_livreur/core/widgets/pill.dart';
import 'package:dksoft_market_livreur/features/authentication/data/auth_repository.dart';
import 'package:dksoft_market_livreur/features/deliveries/domain/delivery_model.dart';
import 'package:dksoft_market_livreur/features/deliveries/presentation/delivery_action_controller.dart';
import 'package:dksoft_market_livreur/features/deliveries/presentation/delivery_actions.dart';
import 'package:dksoft_market_livreur/features/shell/presentation/main_shell.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/formatters/currency_formatter.dart';
import 'package:dksoft_market_livreur/utils/helpers/distance_format.dart';
import 'package:dksoft_market_livreur/utils/helpers/duration_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Carte du bas de l'écran « Proposition de course » : gain, distance et
/// durée, parcours détaillé, puis les boutons selon l'état de la course.
class OfferCard extends StatelessWidget {
  const OfferCard({
    super.key,
    required this.delivery,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.routeLoading,
    required this.maxHeight,
  });

  final DeliveryModel delivery;
  final double? distanceMeters;
  final double? durationSeconds;
  final bool routeLoading;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stops = delivery.pickups.length;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        boxShadow: AppShadows.sheet,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Sizes.screenPadding,
                Sizes.p24,
                Sizes.screenPadding,
                Sizes.p16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Gain de la course',
                        style: theme.textTheme.bodySmall,
                      ),
                      const Spacer(),
                      if (delivery.urgent)
                        const Pill(
                          label: 'Urgent',
                          tone: PillTone.error,
                          icon: AppIcons.flash,
                        )
                      else
                        Text(
                          delivery.shortRef,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: context.palette.textMuted,
                          ),
                        ),
                    ],
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      CurrencyFormatter.formatUsd(delivery.deliveryFee),
                      style: theme.textTheme.displaySmall,
                    ),
                  ),
                  gapH12,
                  Wrap(
                    spacing: Sizes.p8,
                    runSpacing: Sizes.p8,
                    children: [
                      if (distanceMeters != null)
                        Pill(
                          label: formatDistance(distanceMeters!),
                          tone: PillTone.brand,
                          icon: AppIcons.route,
                        ),
                      if (durationSeconds != null)
                        Pill(
                          label:
                              '${formatDuration(durationSeconds!)} · '
                              'arrivée ${formatArrival(durationSeconds!)}',
                          tone: PillTone.brand,
                          icon: AppIcons.clock,
                        )
                      else if (routeLoading)
                        const Pill(
                          label: "Calcul de l'itinéraire…",
                          icon: AppIcons.hourglass,
                        ),
                      Pill(
                        label:
                            '$stops arrêt${stops > 1 ? 's' : ''} · '
                            '${delivery.itemsCount} article'
                            '${delivery.itemsCount > 1 ? 's' : ''}',
                        icon: AppIcons.package,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(
              indent: Sizes.screenPadding,
              endIndent: Sizes.screenPadding,
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  Sizes.screenPadding,
                  Sizes.p16,
                  Sizes.screenPadding,
                  Sizes.p8,
                ),
                child: _TripTimeline(delivery: delivery),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Sizes.p16,
                Sizes.p8,
                Sizes.p16,
                Sizes.p16,
              ),
              child: _OfferActions(delivery: delivery),
            ),
          ],
        ),
      ),
    );
  }
}

/// Le parcours : chaque commerçant (point orange) puis le dealer (drapeau
/// marine), reliés par un trait.
class _TripTimeline extends StatelessWidget {
  const _TripTimeline({required this.delivery});

  final DeliveryModel delivery;

  @override
  Widget build(BuildContext context) {
    final pickups = delivery.pickups;

    String join(DeliveryPlace place) =>
        [place.address, place.commune].where((e) => e.isNotEmpty).join(', ');

    return Column(
      children: [
        for (final (i, stop) in pickups.indexed)
          _TimelineRow(
            label: pickups.length > 1
                ? 'Récupération ${i + 1} sur ${pickups.length}'
                : 'Récupération',
            color: AppColors.secondary,
            name: stop.place.name,
            address: join(stop.place),
            items: stop.items
                .map((e) => '${e.quantity} × ${e.name}')
                .join(', '),
            isLast: false,
          ),
        _TimelineRow(
          label: 'Remise au dealer',
          color: context.palette.primary,
          name: delivery.dropoff.name,
          address: join(delivery.dropoff),
          items: '',
          isLast: true,
        ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.label,
    required this.color,
    required this.name,
    required this.address,
    required this.items,
    required this.isLast,
  });

  final String label;
  final Color color;
  final String name;
  final String address;
  final String items;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: context.palette.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 4),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: context.palette.border,
                    ),
                  ),
              ],
            ),
          ),
          gapW12,
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : Sizes.p20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(color: color),
                  ),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  if (address.isNotEmpty)
                    Text(
                      address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  if (items.isNotEmpty)
                    Text(
                      items,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: context.palette.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Boutons du bas, selon l'état de la course.
class _OfferActions extends ConsumerWidget {
  const _OfferActions({required this.delivery});

  final DeliveryModel delivery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
    final isMine = uid != null && delivery.livreurId == uid;
    final isOpen =
        delivery.status == DeliveryStatus.pendingAssignment &&
        delivery.livreurId == null;
    final loading = ref.watch(deliveryActionControllerProvider).isLoading;
    final hasOtherActive = ref.watch(
      currentLivreurProvider.select(
        (value) => value.value?.activeDeliveryId != null,
      ),
    );

    Widget info(String text) => Padding(
      padding: const EdgeInsets.only(bottom: Sizes.p12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodySmall,
      ),
    );

    if (isOpen && !hasOtherActive) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: AppButton(
              label: 'Refuser',
              variant: AppButtonVariant.tonal,
              height: 58,
              onPressed: loading
                  ? null
                  : () async {
                      final declined = await confirmDecline(
                        context,
                        ref,
                        delivery.id,
                      );
                      if (declined && context.mounted) context.pop();
                    },
            ),
          ),
          gapW12,
          Expanded(
            flex: 3,
            child: AppButton(
              label: 'Accepter',
              icon: AppIcons.check,
              variant: AppButtonVariant.accent,
              height: 58,
              loading: loading,
              onPressed: () async {
                final ok = await acceptAndOpenMap(context, ref, delivery.id);
                if (ok && context.mounted) context.pop();
              },
            ),
          ),
        ],
      );
    }

    if (isOpen && hasOtherActive) {
      return info(
        "Terminez votre course en cours avant d'en prendre une autre.",
      );
    }

    if (isMine) {
      return AppButton(
        label: 'Ouvrir la carte',
        icon: AppIcons.map,
        height: 58,
        onPressed: () {
          ref.read(shellIndexProvider.notifier).select(kTabMap);
          context.pop();
        },
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        info('Cette course a été prise par un autre motard.'),
        AppButton(
          label: 'Retour aux demandes',
          variant: AppButtonVariant.tonal,
          onPressed: () => context.pop(),
        ),
      ],
    );
  }
}

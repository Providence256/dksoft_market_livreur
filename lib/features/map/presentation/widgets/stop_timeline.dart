import 'package:dksoft_market_livreur/core/widgets/stop_badge.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/features/deliveries/domain/delivery_model.dart';
import 'package:dksoft_market_livreur/features/map/presentation/map_stop.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/helpers/distance_format.dart';
import 'package:flutter/material.dart';

/// Une ligne de la frise des arrêts : pastille d'état reliée à la
/// suivante, nom, commune et distance (ou état si l'arrêt est traité).
class StopTimelineTile extends StatelessWidget {
  const StopTimelineTile({
    super.key,
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
        ? StopBadge(icon: AppIcons.flag, color: stop.color)
        : switch (stop.status) {
            PickupStatus.collected => StopBadge(
              icon: AppIcons.check,
              color: stop.color,
            ),
            PickupStatus.unavailable => StopBadge(
              icon: AppIcons.close,
              color: stop.color,
            ),
            _ => StopBadge(label: '${stop.order + 1}', color: stop.color),
          };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.md),
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
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: stop.status == PickupStatus.collected
                              ? AppColors.success.withValues(alpha: 0.5)
                              : context.palette.border,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            gapW12,
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4, bottom: Sizes.p16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            stop.place.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: isNext
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: stop.isPending
                                  ? context.palette.textPrimary
                                  : context.palette.textSecondary,
                            ),
                          ),
                        ),
                        if (distance != null)
                          Text(
                            formatDistance(distance!),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: context.palette.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        else if (!stop.isPending)
                          Text(
                            stop.status?.label ?? '',
                            style: theme.textTheme.labelMedium?.copyWith(
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
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: hasPosition ? null : AppColors.warning,
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

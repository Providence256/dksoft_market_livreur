import 'package:dksoft_market_livreur/core/widgets/app_card.dart';
import 'package:dksoft_market_livreur/features/deliveries/domain/delivery_model.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/formatters/currency_formatter.dart';
import 'package:flutter/material.dart';

/// Demande de course : référence, trajet (commerçants puis dealer), gain,
/// et boutons Accepter / Refuser. Une pastille orange posée sur le bord du
/// haut indique depuis quand la course attend.
class DeliveryCard extends StatelessWidget {
  const DeliveryCard({
    super.key,
    required this.delivery,
    this.onTap,
    this.onAccept,
    this.onDecline,
    this.loading = false,
  });

  final DeliveryModel delivery;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  /// Une acceptation est en cours : les boutons sont désactivés.
  final bool loading;

  static String timeAgo(DateTime? date) {
    if (date == null) return "À l'instant";
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return "À l'instant";
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    return 'Il y a ${diff.inDays} j';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pickups = delivery.pickups;
    final shown = pickups.take(2).toList();
    final hidden = pickups.length - shown.length;
    final stops = pickups.length;
    final hasActions = onAccept != null || onDecline != null;

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AppCard(
            onTap: onTap,
            padding: const EdgeInsets.fromLTRB(
              Sizes.p16,
              Sizes.p24,
              Sizes.p16,
              Sizes.p16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        delivery.shortRef,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 19,
                        ),
                      ),
                    ),
                    gapW8,
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cardLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$stops arrêt${stops > 1 ? 's' : ''}'
                        ' · ${delivery.itemsCount} art.',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                    ),
                    gapW8,
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        CurrencyFormatter.formatUsd(delivery.deliveryFee),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                gapH16,
                for (final stop in shown)
                  _RouteLine(
                    icon: Icons.location_on_outlined,
                    color: AppColors.secondary,
                    text: [
                      stop.place.name,
                      stop.place.commune,
                    ].where((e) => e.isNotEmpty).join(', '),
                  ),
                if (hidden > 0)
                  _RouteLine(
                    icon: Icons.more_horiz_rounded,
                    color: AppColors.textHintLight,
                    text:
                        '+ $hidden autre${hidden > 1 ? 's' : ''} '
                        'commerçant${hidden > 1 ? 's' : ''}',
                  ),
                _RouteLine(
                  icon: Icons.flag_outlined,
                  color: AppColors.primary,
                  text: [
                    delivery.dropoff.name,
                    delivery.dropoff.commune,
                  ].where((e) => e.isNotEmpty).join(', '),
                  isLast: true,
                ),
                if (hasActions) ...[
                  gapH16,
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: loading ? null : onAccept,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: loading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Accepter'),
                          ),
                        ),
                      ),
                      gapW12,
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: loading ? null : onDecline,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: AppColors.cardLight,
                              foregroundColor: AppColors.textPrimaryLight,
                              disabledBackgroundColor: AppColors.cardLight,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Refuser'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            top: -14,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: delivery.urgent
                      ? AppColors.error
                      : AppColors.secondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (delivery.urgent) ...[
                      const Icon(
                        Icons.bolt_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 2),
                    ],
                    Text(
                      delivery.urgent
                          ? 'Urgent · ${timeAgo(delivery.createdAt)}'
                          : timeAgo(delivery.createdAt),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine({
    required this.icon,
    required this.color,
    required this.text,
    this.isLast = false,
  });

  final IconData icon;
  final Color color;
  final String text;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : Sizes.p12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          gapW12,
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textSecondaryLight,
                fontSize: 14.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

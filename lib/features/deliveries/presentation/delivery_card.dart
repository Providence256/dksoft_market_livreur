import 'package:dksoft_market_livreur/features/deliveries/domain/delivery_model.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/formatters/currency_formatter.dart';
import 'package:flutter/material.dart';

/// Carte d'une course : les commerçants où passer, puis le dealer où
/// livrer, et le gain du motard.
class DeliveryCard extends StatelessWidget {
  const DeliveryCard({super.key, required this.delivery, this.onTap});

  final DeliveryModel delivery;
  final VoidCallback? onTap;

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
    final merchantCount = delivery.pickups.length;
    final itemsCount = delivery.itemsCount;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(Sizes.p16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.dividerLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---- Ligne du haut : urgence, résumé, ancienneté ----
              Row(
                children: [
                  if (delivery.urgent) ...[
                    const _Chip(
                      label: 'Urgent',
                      background: AppColors.warningLight,
                      foreground: AppColors.warning,
                      icon: Icons.bolt_rounded,
                    ),
                    gapW8,
                  ],
                  Expanded(
                    child: Text(
                      '$merchantCount commerçant${merchantCount > 1 ? 's' : ''}'
                      ' · $itemsCount article${itemsCount > 1 ? 's' : ''}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                  Text(
                    timeAgo(delivery.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              gapH12,

              // ---- Trajet : commerçants puis dealer ----
              for (final stop in delivery.pickups) ...[
                _Stop(
                  icon: Icons.storefront_outlined,
                  color: AppColors.primary,
                  title: stop.place.commune,
                  subtitle: stop.place.name,
                ),
                const _Connector(),
              ],
              _Stop(
                icon: Icons.flag_outlined,
                color: AppColors.secondary,
                title: delivery.dropoff.commune,
                subtitle: 'Remise au dealer · ${delivery.dropoff.name}',
              ),
              gapH12,
              const Divider(height: 1, color: AppColors.dividerLight),
              gapH12,

              // ---- Gain ----
              Text(
                'Votre gain',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
              Text(
                CurrencyFormatter.formatUsd(delivery.deliveryFee),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 11),
      child: Container(width: 2, height: 12, color: AppColors.dividerLight),
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 24),
        gapW12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.bodyMedium),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

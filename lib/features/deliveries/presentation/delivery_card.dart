import 'package:dksoft_market_livreur/core/widgets/app_button.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/core/widgets/app_card.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/features/deliveries/domain/delivery_model.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/formatters/currency_formatter.dart';
import 'package:flutter/material.dart';

/// Demande de course : en-tête (référence, ancienneté, gain), trajet
/// commerçants → dealer, et boutons Refuser / Accepter.
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
    final hasActions = onAccept != null || onDecline != null;
    final accent = delivery.urgent ? AppColors.error : AppColors.secondary;

    return AppCard(
      onTap: onTap,
      radius: Radii.xl,
      padding: const EdgeInsets.all(Sizes.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- En-tête ----
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent.withValues(alpha: 0.75), accent],
                  ),
                  borderRadius: BorderRadius.circular(Radii.md),
                  boxShadow: AppShadows.glow(accent),
                ),
                child: Center(
                  child: AppIcon(
                    delivery.urgent ? AppIcons.flash : AppIcons.moto,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
              ),
              gapW12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      delivery.urgent ? 'Course urgente' : 'Nouvelle course',
                      style: theme.textTheme.titleMedium,
                    ),
                    Row(
                      children: [
                        AppIcon(
                          AppIcons.clock,
                          size: 13,
                          color: context.palette.textMuted,
                        ),
                        gapW4,
                        Flexible(
                          child: Text(
                            '${timeAgo(delivery.createdAt)} · '
                            '${delivery.shortRef}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              gapW8,
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.formatUsd(delivery.deliveryFee),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${delivery.itemsCount} article'
                    '${delivery.itemsCount > 1 ? 's' : ''}',
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
            ],
          ),
          gapH16,

          // ---- Trajet ----
          Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              color: context.palette.surfaceMuted,
              borderRadius: BorderRadius.circular(Radii.lg),
            ),
            child: Column(
              children: [
                for (final stop in shown)
                  _RouteLine(
                    icon: AppIcons.store,
                    color: AppColors.secondary,
                    title: stop.place.name,
                    subtitle: stop.place.commune,
                  ),
                if (hidden > 0)
                  _RouteLine(
                    icon: AppIcons.store,
                    color: context.palette.textMuted,
                    title:
                        '+ $hidden autre${hidden > 1 ? 's' : ''} '
                        'commerçant${hidden > 1 ? 's' : ''}',
                    subtitle: '',
                  ),
                _RouteLine(
                  icon: AppIcons.flag,
                  color: context.palette.primary,
                  title: delivery.dropoff.name,
                  subtitle: delivery.dropoff.commune,
                  isLast: true,
                ),
              ],
            ),
          ),

          if (hasActions) ...[
            gapH16,
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: AppButton(
                    label: 'Refuser',
                    variant: AppButtonVariant.outlined,
                    height: 50,
                    onPressed: loading ? null : onDecline,
                  ),
                ),
                gapW12,
                Expanded(
                  flex: 3,
                  child: AppButton(
                    label: 'Accepter',
                    icon: AppIcons.checkCircle,
                    variant: AppButtonVariant.accent,
                    height: 50,
                    loading: loading,
                    onPressed: onAccept,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Une étape du trajet : pastille d'icône reliée à la suivante, et le lieu.
class _RouteLine extends StatelessWidget {
  const _RouteLine({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.isLast = false,
  });

  final AppIconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool isLast;

  static const double rowHeight = 46;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: isLast ? 34 : rowHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: context.palette.surface,
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                  child: Center(child: AppIcon(icon, size: 18, color: color)),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: context.palette.border,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          gapW12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(height: 1.2),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

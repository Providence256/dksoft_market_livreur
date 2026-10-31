import 'package:dksoft_market_livreur/core/widgets/app_button.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/core/widgets/app_card.dart';
import 'package:dksoft_market_livreur/core/widgets/icon_tile.dart';
import 'package:dksoft_market_livreur/core/widgets/initials_avatar.dart';
import 'package:dksoft_market_livreur/core/widgets/pill.dart';
import 'package:dksoft_market_livreur/features/map/presentation/widgets/map_round_button.dart';
import 'package:dksoft_market_livreur/features/dashboard/presentation/availability_controller.dart';
import 'package:dksoft_market_livreur/features/deliveries/domain/delivery_model.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/formatters/currency_formatter.dart';
import 'package:dksoft_market_livreur/utils/helpers/distance_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Barre flottante du haut de l'onglet Carte : état des courses et profil.
class OverviewTopBar extends StatelessWidget {
  const OverviewTopBar({
    super.key,
    required this.disponible,
    required this.count,
    required this.name,
    required this.onProfile,
  });

  final bool disponible;
  final int count;
  final String name;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (title, subtitle) = !disponible
        ? ('Vous êtes indisponible', 'Aucune course ne vous est proposée')
        : count == 0
        ? ('Aucune course', 'Les demandes arrivent en direct')
        : (
            '$count course${count > 1 ? 's' : ''} '
                'disponible${count > 1 ? 's' : ''}',
            'Touchez une course pour la voir',
          );

    return MapGlass(
      radius: Radii.xl,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: disponible ? AppColors.success : context.palette.textMuted,
              borderRadius: BorderRadius.circular(Radii.md),
              boxShadow: disponible ? AppShadows.glow(AppColors.success) : null,
            ),
            child: const Center(
              child: AppIcon(AppIcons.moto, size: 22, color: Colors.white),
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
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          gapW8,
          GestureDetector(
            onTap: onProfile,
            child: InitialsAvatar(name: name, size: 38),
          ),
        ],
      ),
    );
  }
}

/// Course du carrousel de l'onglet Carte.
class MapDeliveryCard extends StatelessWidget {
  const MapDeliveryCard({
    super.key,
    required this.delivery,
    required this.selected,
    required this.distance,
    required this.onOpen,
  });

  final DeliveryModel delivery;
  final bool selected;

  /// Distance du livreur au premier commerçant.
  final double? distance;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = delivery.pickups.length;
    final first = delivery.pickups.isEmpty ? null : delivery.pickups.first;

    return AppCard(
      onTap: onOpen,
      elevated: false,
      radius: Radii.xl,
      color: selected ? context.palette.surface : context.palette.surfaceMuted,
      borderColor: selected ? AppColors.secondary : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (delivery.urgent) ...[
                const Pill(
                  label: 'Urgent',
                  tone: PillTone.error,
                  icon: AppIcons.flash,
                ),
                gapW8,
              ],
              Pill(
                label:
                    '$count arrêt${count > 1 ? 's' : ''} · '
                    '${delivery.itemsCount} art.',
                tone: PillTone.brand,
                icon: AppIcons.package,
              ),
              const Spacer(),
              Text(
                CurrencyFormatter.formatUsd(delivery.deliveryFee),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          gapH12,
          _Leg(
            icon: AppIcons.store,
            color: AppColors.secondary,
            title: first?.place.name ?? '—',
            subtitle: count > 1
                ? '${first?.place.commune} · +${count - 1} autre'
                      '${count > 2 ? 's' : ''}'
                : first?.place.commune ?? '',
          ),
          gapH8,
          _Leg(
            icon: AppIcons.flag,
            color: context.palette.primary,
            title: delivery.dropoff.name,
            subtitle: delivery.dropoff.commune,
          ),
          const Spacer(),
          Row(
            children: [
              if (distance != null) ...[
                AppIcon(
                  AppIcons.nearMe,
                  size: 16,
                  color: context.palette.primary,
                ),
                gapW4,
                Text(
                  '${formatDistance(distance!)} de vous',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: context.palette.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const Spacer(),
              AppButton(
                label: 'Voir la course',
                variant: AppButtonVariant.accent,
                expand: false,
                height: 40,
                onPressed: onOpen,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Leg extends StatelessWidget {
  const _Leg({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final AppIconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        IconTile(icon: icon, color: color, size: 30, radius: Radii.sm),
        gapW8,
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: title, style: theme.textTheme.titleSmall),
                if (subtitle.isNotEmpty)
                  TextSpan(
                    text: '  ·  $subtitle',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Pas de course pour le moment.
class NoDeliveryCard extends StatelessWidget {
  const NoDeliveryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _HintCard(
      icon: AppIcons.radar,
      color: context.palette.primary,
      title: 'Recherche de courses…',
      message:
          "Les nouvelles demandes apparaîtront ici. Gardez l'application "
          'ouverte.',
    );
  }
}

/// Le motard est indisponible : bouton pour repasser disponible.
class UnavailableCard extends ConsumerWidget {
  const UnavailableCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(availabilityControllerProvider).isLoading;

    return _HintCard(
      icon: AppIcons.pause,
      color: context.palette.textSecondary,
      title: 'Passez disponible',
      message: 'Vous verrez ici toutes les courses et leurs destinations.',
      action: AppButton(
        label: 'Me mettre disponible',
        variant: AppButtonVariant.success,
        loading: loading,
        onPressed: () => ref
            .read(availabilityControllerProvider.notifier)
            .setDisponible(true),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    this.action,
  });

  final AppIconData icon;
  final Color color;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      elevated: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: icon, color: color),
              gapW12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    Text(message, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
          if (action != null) ...[gapH16, action!],
        ],
      ),
    );
  }
}

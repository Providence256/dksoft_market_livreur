import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/core/widgets/app_card.dart';
import 'package:dksoft_market_livreur/core/widgets/icon_tile.dart';
import 'package:dksoft_market_livreur/core/widgets/section_title.dart';
import 'package:dksoft_market_livreur/core/domain/livreur_model.dart';
import 'package:dksoft_market_livreur/features/deliveries/data/deliveries_repository.dart';
import 'package:dksoft_market_livreur/features/deliveries/presentation/delivery_action_controller.dart';
import 'package:dksoft_market_livreur/features/deliveries/presentation/delivery_actions.dart';
import 'package:dksoft_market_livreur/features/deliveries/presentation/delivery_card.dart';
import 'package:dksoft_market_livreur/features/shell/presentation/main_shell.dart';
import 'package:dksoft_market_livreur/routing/app_router.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Bas de l'accueil : la course en cours, sinon les demandes à prendre.
class MissionSection extends ConsumerWidget {
  const MissionSection({super.key, required this.livreur});

  final LivreurModel livreur;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeId = livreur.activeDeliveryId;
    if (activeId != null) return _ActiveDeliveryCard(deliveryId: activeId);

    if (!livreur.disponible) {
      return _HintCard(
        icon: AppIcons.pause,
        color: context.palette.textSecondary,
        title: 'Vous êtes hors ligne',
        message: 'Passez disponible pour recevoir des demandes de course.',
      );
    }

    final deliveries = ref.watch(availableDeliveriesProvider).value ?? const [];
    if (deliveries.isEmpty) {
      return _HintCard(
        icon: AppIcons.radar,
        color: context.palette.primary,
        title: 'Aucune demande pour le moment',
        message: 'Elles apparaîtront ici en direct.',
      );
    }

    return _RequestsCarousel(count: deliveries.length);
  }
}

/// Course en cours : étape, progression de la collecte et accès à la carte.
class _ActiveDeliveryCard extends ConsumerWidget {
  const _ActiveDeliveryCard({required this.deliveryId});

  final String deliveryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final delivery = ref.watch(deliveryByIdProvider(deliveryId)).value;
    final total = delivery?.pickups.length ?? 0;
    final done = delivery?.collectedCount ?? 0;
    final collecting = done < total || total == 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Course en cours'),
        gapH8,
        Container(
          padding: const EdgeInsets.all(Sizes.p20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.secondaryLight, AppColors.secondaryDark],
            ),
            borderRadius: BorderRadius.circular(Radii.xl),
            boxShadow: AppShadows.glow(AppColors.secondary),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconTile(
                    icon: collecting ? AppIcons.store : AppIcons.flag,
                    color: Colors.white,
                    background: Colors.white.withValues(alpha: 0.2),
                    size: 48,
                  ),
                  gapW12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          delivery == null
                              ? 'Chargement…'
                              : collecting
                              ? 'Collecte en cours'
                              : 'En route vers le dealer',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          delivery == null
                              ? ''
                              : collecting
                              ? '$done sur $total commerçant'
                                    '${total > 1 ? 's' : ''} visité'
                                    '${done > 1 ? 's' : ''}'
                              : delivery.dropoff.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (total > 0) ...[
                gapH16,
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: done / total,
                    minHeight: 6,
                    color: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              ],
              gapH16,
              FilledButton.icon(
                onPressed: () =>
                    ref.read(shellIndexProvider.notifier).select(kTabMap),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.secondaryDark,
                  minimumSize: const Size.fromHeight(Sizes.controlHeight),
                ),
                icon: const AppIcon(AppIcons.navigation, size: 20),
                label: const Text('Reprendre la course'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Les cinq demandes les plus récentes, à faire défiler.
class _RequestsCarousel extends ConsumerStatefulWidget {
  const _RequestsCarousel({required this.count});

  final int count;

  @override
  ConsumerState<_RequestsCarousel> createState() => _RequestsCarouselState();
}

class _RequestsCarouselState extends ConsumerState<_RequestsCarousel> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(deliveryActionControllerProvider).isLoading;
    final deliveries = ref.watch(availableDeliveriesProvider).value ?? const [];
    final visible = deliveries.take(5).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    // Toutes les pages ont la hauteur de la plus haute carte.
    var maxLines = 1;
    for (final d in visible) {
      final lines = (d.pickups.length > 2 ? 3 : d.pickups.length) + 1;
      if (lines > maxLines) maxLines = lines;
    }
    final cardHeight = 186.0 + maxLines * 46;
    final page = _page.clamp(0, visible.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          'Demandes de course',
          actionLabel: deliveries.length > 1 ? 'Tout voir' : null,
          onAction: () =>
              ref.read(shellIndexProvider.notifier).select(kTabDeliveries),
        ),
        gapH8,
        SizedBox(
          height: cardHeight,
          child: PageView.builder(
            controller: _controller,
            clipBehavior: Clip.none,
            itemCount: visible.length,
            onPageChanged: (value) => setState(() => _page = value),
            itemBuilder: (context, index) {
              final delivery = visible[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: DeliveryCard(
                    delivery: delivery,
                    loading: loading,
                    onTap: () => context.pushNamed(
                      AppRoute.delivery.name,
                      pathParameters: {'id': delivery.id},
                    ),
                    onAccept: () => acceptAndOpenMap(context, ref, delivery.id),
                    onDecline: () => confirmDecline(context, ref, delivery.id),
                  ),
                ),
              );
            },
          ),
        ),
        if (visible.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: Sizes.p8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < visible.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == page ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == page
                          ? context.palette.primary
                          : context.palette.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  final AppIconData icon;
  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Row(
        children: [
          IconTile(icon: icon, color: color, size: 48),
          gapW16,
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
    );
  }
}

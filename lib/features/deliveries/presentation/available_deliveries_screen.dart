import 'package:dksoft_market_livreur/features/deliveries/presentation/widgets/delivery_list_skeleton.dart';
import 'package:dksoft_market_livreur/core/animations/motion.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/core/data/livreur_repository.dart';
import 'package:dksoft_market_livreur/core/widgets/app_button.dart';
import 'package:dksoft_market_livreur/core/widgets/empty_state.dart';
import 'package:dksoft_market_livreur/core/widgets/pill.dart';
import 'package:dksoft_market_livreur/features/dashboard/presentation/availability_controller.dart';
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

/// Onglet « Demandes » : les courses proposées aux motards disponibles,
/// en temps réel. Le premier qui accepte obtient la course.
class AvailableDeliveriesScreen extends ConsumerWidget {
  const AvailableDeliveriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disponible =
        ref.watch(
          currentLivreurProvider.select((value) => value.value?.disponible),
        ) ??
        false;
    final activeDeliveryId = ref.watch(
      currentLivreurProvider.select((value) => value.value?.activeDeliveryId),
    );
    final deliveriesAsync = ref.watch(availableDeliveriesProvider);
    final loading = ref.watch(deliveryActionControllerProvider).isLoading;
    final count = deliveriesAsync.value?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Demandes'),
            if (disponible && activeDeliveryId == null && count > 0) ...[
              gapW8,
              Pill(label: '$count', tone: PillTone.accent),
            ],
          ],
        ),
        actions: [gapW8],
      ),
      body: SafeArea(
        child: activeDeliveryId != null
            ? EmptyState(
                icon: AppIcons.moto,
                color: AppColors.secondary,
                title: 'Une course est en cours',
                message: "Terminez-la avant d'en prendre une autre.",
                action: AppButton(
                  label: 'Ouvrir la carte',
                  icon: AppIcons.map,
                  variant: AppButtonVariant.accent,
                  expand: false,
                  onPressed: () =>
                      ref.read(shellIndexProvider.notifier).select(kTabMap),
                ),
              )
            : !disponible
            ? const _UnavailableState()
            : deliveriesAsync.when(
                loading: () => const DeliveryListSkeleton(),
                error: (_, _) => EmptyState(
                  icon: AppIcons.offline,
                  title: 'Impossible de charger les courses',
                  message: 'Vérifiez votre connexion internet.',
                  action: AppButton(
                    label: 'Réessayer',
                    variant: AppButtonVariant.tonal,
                    expand: false,
                    onPressed: () =>
                        ref.invalidate(availableDeliveriesProvider),
                  ),
                ),
                data: (deliveries) {
                  if (deliveries.isEmpty) {
                    return const RadarEmptyState(
                      title: 'Recherche de courses…',
                      message:
                          'Les nouvelles demandes apparaissent ici '
                          "automatiquement. Gardez l'application ouverte.",
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      Sizes.screenPadding,
                      Sizes.p4,
                      Sizes.screenPadding,
                      Sizes.p24,
                    ),
                    itemCount: deliveries.length,
                    separatorBuilder: (_, _) => gapH12,
                    itemBuilder: (context, index) {
                      final delivery = deliveries[index];
                      return FadeSlideIn(
                        key: ValueKey(delivery.id),
                        delay: Motion.stagger(index),
                        child: DeliveryCard(
                          delivery: delivery,
                          loading: loading,
                          onTap: () => context.pushNamed(
                            AppRoute.delivery.name,
                            pathParameters: {'id': delivery.id},
                          ),
                          onAccept: () =>
                              acceptAndOpenMap(context, ref, delivery.id),
                          onDecline: () =>
                              confirmDecline(context, ref, delivery.id),
                        ),
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _UnavailableState extends ConsumerWidget {
  const _UnavailableState();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(availabilityControllerProvider).isLoading;

    return EmptyState(
      icon: AppIcons.pause,
      color: context.palette.textSecondary,
      title: 'Vous êtes hors ligne',
      message: 'Passez disponible pour voir et prendre des courses.',
      action: AppButton(
        label: 'Me mettre disponible',
        variant: AppButtonVariant.success,
        expand: false,
        loading: isLoading,
        onPressed: () => ref
            .read(availabilityControllerProvider.notifier)
            .setDisponible(true),
      ),
    );
  }
}

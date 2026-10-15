import 'package:dksoft_market_livreur/core/data/livreur_repository.dart';
import 'package:dksoft_market_livreur/core/widgets/app_card.dart';
import 'package:dksoft_market_livreur/core/widgets/empty_state.dart';
import 'package:dksoft_market_livreur/features/dashboard/presentation/availability_controller.dart';
import 'package:dksoft_market_livreur/features/deliveries/data/deliveries_repository.dart';
import 'package:dksoft_market_livreur/features/deliveries/presentation/debug_delivery_seeder.dart';
import 'package:dksoft_market_livreur/features/deliveries/presentation/delivery_action_controller.dart';
import 'package:dksoft_market_livreur/features/deliveries/presentation/delivery_actions.dart';
import 'package:dksoft_market_livreur/features/deliveries/presentation/delivery_card.dart';
import 'package:dksoft_market_livreur/features/shell/presentation/main_shell.dart';
import 'package:dksoft_market_livreur/routing/app_router.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/foundation.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demandes de course'),
        actions: [
          // Outil de test : n'existe qu'en debug. À supprimer avec
          // debug_delivery_seeder.dart quand les vraies courses arrivent.
          if (kDebugMode)
            IconButton(
              tooltip: 'Créer une course de test',
              icon: const Icon(Icons.add_circle_outline),
              color: AppColors.textPrimaryLight,
              onPressed: () async {
                await createTestDelivery();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Course de test créée.')),
                );
              },
            ),
        ],
      ),
      body: SafeArea(
        child: activeDeliveryId != null
            ? const _ActiveNotice()
            : !disponible
            ? const _UnavailableState()
            : deliveriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => EmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: 'Impossible de charger les courses',
                  message: 'Vérifiez votre connexion internet.',
                  action: OutlinedButton(
                    onPressed: () =>
                        ref.invalidate(availableDeliveriesProvider),
                    child: const Text('Réessayer'),
                  ),
                ),
                data: (deliveries) {
                  if (deliveries.isEmpty) {
                    return const EmptyState(
                      icon: Icons.two_wheeler,
                      title: 'Aucune demande pour le moment',
                      message:
                          'Les nouvelles courses apparaissent ici '
                          "automatiquement. Gardez l'application ouverte.",
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(Sizes.p16),
                    itemCount: deliveries.length,
                    separatorBuilder: (_, _) => gapH16,
                    itemBuilder: (context, index) {
                      final delivery = deliveries[index];
                      return DeliveryCard(
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
      icon: Icons.pause_circle_outline_rounded,
      title: 'Vous êtes indisponible',
      message: 'Passez disponible pour voir et prendre des courses.',
      action: ElevatedButton(
        onPressed: isLoading
            ? null
            : () => ref
                  .read(availabilityControllerProvider.notifier)
                  .setDisponible(true),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : const Text('Me mettre disponible'),
      ),
    );
  }
}

/// Une seule course à la fois : tant qu'elle est en cours, l'onglet y
/// renvoie au lieu de proposer d'autres demandes.
class _ActiveNotice extends ConsumerWidget {
  const _ActiveNotice();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(Sizes.p16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppCard(
            borderColor: AppColors.secondary,
            child: Column(
              children: [
                const Icon(
                  Icons.two_wheeler_rounded,
                  size: 40,
                  color: AppColors.secondary,
                ),
                gapH12,
                Text(
                  'Une course est en cours',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                gapH4,
                Text(
                  "Terminez-la avant d'en prendre une autre.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                gapH16,
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        ref.read(shellIndexProvider.notifier).select(kTabMap),
                    icon: const Icon(Icons.map_rounded, size: 20),
                    label: const Text('Ouvrir la carte'),
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

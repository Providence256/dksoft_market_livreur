import 'package:dksoft_market_livreur/core/data/livreur_repository.dart';
import 'package:dksoft_market_livreur/features/dashboard/presentation/availability_controller.dart';
import 'package:dksoft_market_livreur/features/deliveries/data/deliveries_repository.dart';
import 'package:dksoft_market_livreur/features/deliveries/presentation/debug_delivery_seeder.dart';
import 'package:dksoft_market_livreur/features/deliveries/presentation/delivery_card.dart';
import 'package:dksoft_market_livreur/routing/app_router.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Courses proposées aux motards disponibles, en temps réel. Le motard
/// qui accepte en premier obtient la course (le détail et l'acceptation
/// arrivent à l'étape 6).
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses disponibles'),
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
            ? _ActiveDeliveryView(deliveryId: activeDeliveryId)
            : !disponible
            ? const _UnavailableState()
            : deliveriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => _MessageState(
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
                    return const _MessageState(
                      icon: Icons.two_wheeler,
                      title: 'Aucune course pour le moment',
                      message:
                          'Les nouvelles courses apparaissent ici '
                          'automatiquement. Gardez l\'application ouverte.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(Sizes.p16),
                    itemCount: deliveries.length,
                    separatorBuilder: (_, _) => gapH12,
                    itemBuilder: (context, index) {
                      final delivery = deliveries[index];
                      return DeliveryCard(
                        delivery: delivery,
                        onTap: () => context.pushNamed(
                          AppRoute.delivery.name,
                          pathParameters: {'id': delivery.id},
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

    return _MessageState(
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
            : Text(
                'Me mettre disponible',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall!.copyWith(color: Colors.white),
              ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Sizes.p24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(Sizes.p20),
              decoration: const BoxDecoration(
                color: AppColors.cardLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: AppColors.primary),
            ),
            gapH16,
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            gapH8,
            Text(
              message,
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[gapH16, action!],
          ],
        ),
      ),
    );
  }
}

/// Le motard n'a qu'une course à la fois : tant qu'elle est en cours,
/// l'onglet la met en avant au lieu de proposer d'autres courses.
class _ActiveDeliveryView extends ConsumerWidget {
  const _ActiveDeliveryView({required this.deliveryId});

  final String deliveryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final deliveryAsync = ref.watch(deliveryByIdProvider(deliveryId));

    return ListView(
      padding: const EdgeInsets.all(Sizes.p16),
      children: [
        Text('Votre course en cours', style: theme.textTheme.titleMedium),
        gapH4,
        Text(
          "Terminez-la avant d'en prendre une autre.",
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondaryLight,
          ),
        ),
        gapH16,
        deliveryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Text('Impossible de charger la course.'),
          data: (delivery) => delivery == null
              ? const Text("Cette course n'existe plus.")
              : DeliveryCard(
                  delivery: delivery,
                  onTap: () => context.pushNamed(
                    AppRoute.delivery.name,
                    pathParameters: {'id': delivery.id},
                  ),
                ),
        ),
      ],
    );
  }
}

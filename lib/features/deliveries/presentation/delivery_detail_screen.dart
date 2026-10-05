import 'package:dksoft_market_livreur/core/data/livreur_repository.dart';
import 'package:dksoft_market_livreur/features/authentication/data/auth_repository.dart';
import 'package:dksoft_market_livreur/features/deliveries/data/deliveries_repository.dart';
import 'package:dksoft_market_livreur/features/deliveries/domain/delivery_model.dart';
import 'package:dksoft_market_livreur/features/deliveries/presentation/delivery_action_controller.dart';
import 'package:dksoft_market_livreur/routing/app_router.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/formatters/currency_formatter.dart';
import 'package:dksoft_market_livreur/utils/helpers/external_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Détail d'une course : les commerçants où récupérer les articles, puis
/// le dealer où livrer. Les numéros de téléphone et les boutons
/// d'appel / d'itinéraire n'apparaissent qu'une fois la course prise.
class DeliveryDetailScreen extends ConsumerWidget {
  const DeliveryDetailScreen({super.key, required this.deliveryId});

  final String deliveryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveryAsync = ref.watch(deliveryByIdProvider(deliveryId));

    ref.listen<AsyncValue<void>>(deliveryActionControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${next.error}')));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de la course'),
        actions: [
          IconButton(
            tooltip: 'Voir sur la carte',
            icon: const Icon(Icons.map_outlined),
            color: AppColors.textPrimaryLight,
            onPressed: () => context.pushNamed(
              AppRoute.deliveryMap.name,
              pathParameters: {'id': deliveryId},
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: deliveryAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              const Center(child: Text('Impossible de charger la course.')),
          data: (delivery) => delivery == null
              ? const Center(child: Text("Cette course n'existe plus."))
              : _DetailBody(delivery: delivery),
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.delivery});

  final DeliveryModel delivery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
    final isMine = uid != null && delivery.livreurId == uid;
    final isOpen =
        delivery.status == DeliveryStatus.pendingAssignment &&
        delivery.livreurId == null;
    final takenByOther = !isOpen && !isMine;
    final pickupCount = delivery.pickups.length;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(Sizes.p16),
            children: [
              _SummaryCard(
                delivery: delivery,
                stateLabel: isMine
                    ? delivery.status.label
                    : (isOpen ? 'Disponible' : 'Déjà prise'),
                stateColor: isMine || isOpen
                    ? AppColors.success
                    : AppColors.textSecondaryLight,
              ),
              gapH16,
              if (pickupCount == 0)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: Sizes.p16),
                  child: Text(
                    'Aucun point de récupération renseigné pour cette course.',
                    textAlign: TextAlign.center,
                  ),
                ),
              for (var i = 0; i < pickupCount; i++) ...[
                _PlaceCard(
                  badge: '${i + 1}',
                  title: pickupCount > 1
                      ? 'Récupération ${i + 1} sur $pickupCount'
                      : 'Récupération',
                  color: AppColors.primary,
                  place: delivery.pickups[i].place,
                  items: delivery.pickups[i].items,
                  showContacts: isMine,
                ),
                gapH12,
              ],
              _PlaceCard(
                icon: Icons.flag_outlined,
                title: 'Remise au dealer',
                color: AppColors.secondary,
                place: delivery.dropoff,
                showContacts: isMine,
              ),
              gapH12,
              _OrderCard(delivery: delivery),
            ],
          ),
        ),
        _ActionBar(
          delivery: delivery,
          isOpen: isOpen,
          isMine: isMine,
          takenByOther: takenByOther,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.delivery,
    required this.stateLabel,
    required this.stateColor,
  });

  final DeliveryModel delivery;
  final String stateLabel;
  final Color stateColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final merchants = delivery.pickups.length;
    final items = delivery.itemsCount;

    return Container(
      padding: const EdgeInsets.all(Sizes.p16),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.circle, size: 10, color: stateColor),
              gapW8,
              Text(
                stateLabel,
                style: theme.textTheme.labelMedium?.copyWith(color: stateColor),
              ),
              const Spacer(),
              if (delivery.urgent)
                Text(
                  '⚡ Urgent',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.warning,
                  ),
                ),
            ],
          ),
          gapH12,
          Text(
            'Votre gain',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          Text(
            CurrencyFormatter.formatUsd(delivery.deliveryFee),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.success,
            ),
          ),
          gapH12,
          Row(
            children: [
              const Icon(
                Icons.route_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              gapW8,
              Expanded(
                child: Text(
                  '$merchants récupération${merchants > 1 ? 's' : ''} '
                  'puis remise au dealer · $items article${items > 1 ? 's' : ''}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.title,
    required this.color,
    required this.place,
    required this.showContacts,
    this.badge,
    this.icon,
    this.items = const [],
  });

  final String title;
  final Color color;
  final DeliveryPlace place;
  final bool showContacts;

  /// Numéro de l'arrêt (commerçants). Sinon, [icon] est affichée.
  final String? badge;
  final IconData? icon;
  final List<PickupItem> items;

  Future<void> _call(BuildContext context, String phone) async {
    final ok = await callPhone(phone);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Impossible d'appeler le $phone.")),
      );
    }
  }

  Future<void> _openMaps(BuildContext context) async {
    final ok = await openInMaps(place);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible d'ouvrir les cartes.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phone = place.phone;
    final hasPhone = phone != null && phone.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Sizes.p16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.dividerLight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (badge != null)
                CircleAvatar(
                  radius: 13,
                  backgroundColor: color,
                  child: Text(
                    badge!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Icon(icon ?? Icons.place_outlined, color: color),
              gapW8,
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            ],
          ),
          gapH12,
          Text(place.name, style: theme.textTheme.bodyMedium),
          gapH4,
          Text(
            '${place.address} · ${place.commune}',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          if (place.reference.isNotEmpty) ...[
            gapH4,
            Text(
              'Repère : ${place.reference}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
          if (showContacts && hasPhone) ...[
            gapH4,
            Text(phone, style: theme.textTheme.labelMedium),
          ],

          // ---- Articles à récupérer chez ce commerçant ----
          if (items.isNotEmpty) ...[
            gapH12,
            const Divider(height: 1, color: AppColors.dividerLight),
            gapH12,
            Text(
              'À récupérer',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.textSecondaryLight,
              ),
            ),
            gapH4,
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(item.name, style: theme.textTheme.bodySmall),
                    ),
                    Text(
                      '× ${item.quantity}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
          ],

          // ---- Contacts : seulement après acceptation ----
          if (showContacts) ...[
            gapH12,
            Row(
              children: [
                if (hasPhone) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _call(context, phone),
                      icon: const Icon(Icons.call_outlined, size: 18),
                      label: const Text('Appeler'),
                    ),
                  ),
                  gapW12,
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openMaps(context),
                    icon: const Icon(Icons.directions_outlined, size: 18),
                    label: const Text('Itinéraire'),
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

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.delivery});

  final DeliveryModel delivery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = delivery.note;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Sizes.p16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.dividerLight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Commande', style: theme.textTheme.titleMedium),
          gapH8,
          Text(delivery.orderId, style: theme.textTheme.bodySmall),
          if (note != null && note.isNotEmpty) ...[
            gapH8,
            Text('Note : $note', style: theme.textTheme.labelMedium),
          ],
        ],
      ),
    );
  }
}

class _ActionBar extends ConsumerWidget {
  const _ActionBar({
    required this.delivery,
    required this.isOpen,
    required this.isMine,
    required this.takenByOther,
  });

  final DeliveryModel delivery;
  final bool isOpen;
  final bool isMine;
  final bool takenByOther;

  Future<void> _confirmRefuse(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Refuser cette course ?'),
        content: const Text(
          'Elle ne vous sera plus proposée, mais restera disponible pour '
          'les autres motards.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    ref.read(deliveryActionControllerProvider.notifier).refuse(delivery.id);
    if (context.mounted) context.pop();
  }

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    final success = await ref
        .read(deliveryActionControllerProvider.notifier)
        .accept(delivery.id);

    if (success && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Course acceptée !')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(deliveryActionControllerProvider).isLoading;
    final hasOtherActive = ref.watch(
      currentLivreurProvider.select(
        (value) => value.value?.activeDeliveryId != null,
      ),
    );

    Widget content;

    if (isOpen && hasOtherActive) {
      content = Text(
        "Terminez votre course en cours avant d'en prendre une autre.",
        style: theme.textTheme.labelMedium,
        textAlign: TextAlign.center,
      );
    } else if (isOpen) {
      content = Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: isLoading ? null : () => _confirmRefuse(context, ref),
              child: const Text('Refuser'),
            ),
          ),
          gapW12,
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isLoading ? null : () => _accept(context, ref),
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
                      'Accepter la course',
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      );
    } else if (isMine) {
      content = Text(
        'Course acceptée. Commencez par récupérer les articles chez les '
        'commerçants.',
        style: theme.textTheme.labelMedium,
        textAlign: TextAlign.center,
      );
    } else if (takenByOther) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Cette course a été prise par un autre motard.',
            style: theme.textTheme.labelMedium,
            textAlign: TextAlign.center,
          ),
          gapH8,
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('Retour aux courses'),
            ),
          ),
        ],
      );
    } else {
      content = const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        Sizes.p16,
        Sizes.p12,
        Sizes.p16,
        Sizes.p16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.dividerLight)),
      ),
      child: content,
    );
  }
}

import 'package:dksoft_market_livreur/core/data/livreur_repository.dart';
import 'package:dksoft_market_livreur/core/domain/livreur_model.dart';
import 'package:dksoft_market_livreur/core/widgets/app_card.dart';
import 'package:dksoft_market_livreur/core/widgets/section_title.dart';
import 'package:dksoft_market_livreur/core/widgets/sparkline.dart';
import 'package:dksoft_market_livreur/core/widgets/square_icon_button.dart';
import 'package:dksoft_market_livreur/core/widgets/weekly_bar_chart.dart';
import 'package:dksoft_market_livreur/features/dashboard/presentation/availability_controller.dart';
import 'package:dksoft_market_livreur/features/deliveries/data/deliveries_repository.dart';
import 'package:dksoft_market_livreur/features/deliveries/presentation/delivery_action_controller.dart';
import 'package:dksoft_market_livreur/features/deliveries/presentation/delivery_actions.dart';
import 'package:dksoft_market_livreur/features/deliveries/presentation/delivery_card.dart';
import 'package:dksoft_market_livreur/features/earnings/domain/week_stats.dart';
import 'package:dksoft_market_livreur/features/shell/presentation/main_shell.dart';
import 'package:dksoft_market_livreur/routing/app_router.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Montant court pour les bulles et les cartes : « 230 USD », « 12,5 USD ».
String shortUsd(double value) {
  final text = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1).replaceAll('.', ',');
  return '$text USD';
}

/// Initiales du nom complet, pour l'avatar.
String initialsOf(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  final first = parts.first[0];
  final second = parts.length > 1 ? parts.last[0] : '';
  return '$first$second'.toUpperCase();
}

/// Accueil du motard : salutation, disponibilité, résultats de la semaine,
/// course en cours ou demandes à prendre.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final livreurAsync = ref.watch(currentLivreurProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: livreurAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              const Center(child: Text('Impossible de charger votre profil.')),
          data: (livreur) => livreur == null
              ? const Center(child: Text('Profil introuvable.'))
              : _DashboardBody(livreur: livreur),
        ),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.livreur});

  final LivreurModel livreur;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final availableCount =
        ref.watch(availableDeliveriesProvider).value?.length ?? 0;
    final mine = ref.watch(myDeliveriesProvider).value ?? const [];
    final stats = WeekStats.compute(mine, DateTime.now());

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Sizes.p16,
        Sizes.p12,
        Sizes.p16,
        Sizes.p24,
      ),
      children: [
        // ---- Salutation + cloche ----
        Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.secondary,
              child: Text(
                initialsOf(livreur.fullName),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
            ),
            gapW12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bon retour !',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  Text(
                    livreur.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            SquareIconButton(
              icon: Icons.notifications_rounded,
              tooltip: 'Demandes de course',
              showDot: availableCount > 0,
              onPressed: () =>
                  ref.read(shellIndexProvider.notifier).select(kTabDeliveries),
            ),
          ],
        ),
        gapH16,
        _AvailabilityCard(disponible: livreur.disponible),
        gapH12,

        // ---- Gains + livraisons (courbes) ----
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Gains',
                value: shortUsd(stats.totalEarnings),
                series: _cumulative(stats.dailyEarnings),
                delta: stats.earningsDelta,
              ),
            ),
            gapW12,
            Expanded(
              child: _StatCard(
                label: 'Livraisons',
                value: '${stats.totalCount}',
                series: _cumulative(
                  stats.dailyCounts.map((e) => e.toDouble()).toList(),
                ),
                delta: stats.countDelta,
              ),
            ),
          ],
        ),
        gapH24,

        // ---- Gains de la semaine ----
        Text('Gains de la semaine', style: theme.textTheme.titleLarge),
        gapH12,
        AppCard(
          padding: const EdgeInsets.fromLTRB(
            Sizes.p12,
            Sizes.p48,
            Sizes.p12,
            Sizes.p16,
          ),
          child: WeeklyBarChart(
            values: stats.dailyEarnings,
            valueLabel: shortUsd,
          ),
        ),
        gapH24,

        // ---- Course en cours ou demandes ----
        _MissionSection(livreur: livreur),
      ],
    );
  }

  /// Cumul du lundi à aujourd'hui (la courbe monte au fil de la semaine).
  static List<double> _cumulative(List<double> daily) {
    final today = DateTime.now().weekday - 1;
    var total = 0.0;
    return [
      for (var i = 0; i <= today && i < daily.length; i++) total += daily[i],
    ];
  }
}

class _AvailabilityCard extends ConsumerWidget {
  const _AvailabilityCard({required this.disponible});

  final bool disponible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(availabilityControllerProvider).isLoading;

    ref.listen<AsyncValue<void>>(availabilityControllerProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${next.error}')));
      }
    });

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: Sizes.p16,
        vertical: Sizes.p8,
      ),
      child: Row(
        children: [
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: disponible ? AppColors.success : AppColors.textHintLight,
            ),
          ),
          gapW12,
          Expanded(
            child: Text(
              disponible ? 'Vous êtes disponible' : 'Vous êtes indisponible',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              ),
            )
          else
            Switch.adaptive(
              value: disponible,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.primary,
              onChanged: (value) => ref
                  .read(availabilityControllerProvider.notifier)
                  .setDisponible(value),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.series,
    required this.delta,
  });

  final String label;
  final String value;
  final List<double> series;
  final double? delta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final positive = (delta ?? 0) >= 0;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        Sizes.p12,
        Sizes.p12,
        Sizes.p12,
        Sizes.p8,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
          gapH12,
          Sparkline(values: series.length >= 2 ? series : [0, 0]),
          SizedBox(
            height: 18,
            child: Align(
              alignment: Alignment.centerRight,
              child: delta == null
                  ? Text(
                      'cette semaine',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textHintLight,
                      ),
                    )
                  : Text(
                      '${positive ? '+' : ''}${delta!.toStringAsFixed(0)}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: positive ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bas de l'accueil : la course en cours, sinon les demandes à prendre.
class _MissionSection extends ConsumerStatefulWidget {
  const _MissionSection({required this.livreur});

  final LivreurModel livreur;

  @override
  ConsumerState<_MissionSection> createState() => _MissionSectionState();
}

class _MissionSectionState extends ConsumerState<_MissionSection> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final livreur = widget.livreur;
    final activeId = livreur.activeDeliveryId;
    final loading = ref.watch(deliveryActionControllerProvider).isLoading;
    final deliveries = ref.watch(availableDeliveriesProvider).value ?? const [];

    void openMap() => ref.read(shellIndexProvider.notifier).select(kTabMap);

    // ---- Course en cours ----
    if (activeId != null) {
      final delivery = ref.watch(deliveryByIdProvider(activeId)).value;
      final total = delivery?.pickups.length ?? 0;
      final done = delivery?.collectedCount ?? 0;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Course en cours', style: theme.textTheme.titleLarge),
          gapH12,
          AppCard(
            borderColor: AppColors.secondary,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  delivery == null
                      ? 'Chargement de la course…'
                      : done >= total && total > 0
                      ? 'Direction : ${delivery.dropoff.name}'
                      : 'Collecte : $done sur $total commerçants',
                  style: theme.textTheme.titleMedium,
                ),
                gapH4,
                Text(
                  'Reprenez votre trajet sur la carte.',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                gapH16,
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: openMap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.map_rounded, size: 20),
                    label: const Text('Ouvrir la carte'),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // ---- Indisponible ----
    if (!livreur.disponible) {
      return AppCard(
        child: Row(
          children: [
            const Icon(
              Icons.pause_circle_outline_rounded,
              color: AppColors.textHintLight,
              size: 34,
            ),
            gapW12,
            Expanded(
              child: Text(
                'Passez disponible pour recevoir des demandes de course.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ---- Aucune demande ----
    if (deliveries.isEmpty) {
      return AppCard(
        child: Row(
          children: [
            const Icon(
              Icons.two_wheeler_rounded,
              color: AppColors.primary,
              size: 34,
            ),
            gapW12,
            Expanded(
              child: Text(
                'Aucune demande pour le moment. Elles apparaîtront ici en '
                'direct.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ---- Demandes (carrousel) ----
    final visible = deliveries.take(5).toList();
    var maxLines = 1;
    for (final d in visible) {
      final lines = (d.pickups.length > 2 ? 3 : d.pickups.length) + 1;
      if (lines > maxLines) maxLines = lines;
    }
    final cardHeight = 160.0 + maxLines * 34;
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
        gapH12,
        SizedBox(
          height: cardHeight,
          child: PageView.builder(
            controller: _controller,
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
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < visible.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == page ? 16 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: i == page
                          ? AppColors.secondary
                          : AppColors.dividerLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

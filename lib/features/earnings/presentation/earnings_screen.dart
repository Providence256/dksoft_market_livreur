import 'package:dksoft_market_livreur/features/earnings/presentation/widgets/earnings_skeleton.dart';
import 'package:dksoft_market_livreur/core/animations/motion.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/core/widgets/app_card.dart';
import 'package:dksoft_market_livreur/core/widgets/empty_state.dart';
import 'package:dksoft_market_livreur/core/widgets/hero_card.dart';
import 'package:dksoft_market_livreur/core/widgets/icon_tile.dart';
import 'package:dksoft_market_livreur/core/widgets/section_title.dart';
import 'package:dksoft_market_livreur/core/widgets/weekly_bar_chart.dart';
import 'package:dksoft_market_livreur/features/deliveries/data/deliveries_repository.dart';
import 'package:dksoft_market_livreur/features/deliveries/domain/delivery_model.dart';
import 'package:dksoft_market_livreur/core/data/livreur_repository.dart';
import 'package:dksoft_market_livreur/features/earnings/data/payouts_repository.dart';
import 'package:dksoft_market_livreur/features/earnings/domain/week_stats.dart';
import 'package:dksoft_market_livreur/features/earnings/presentation/widgets/balance_card.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/formatters/currency_formatter.dart';
import 'package:dksoft_market_livreur/utils/formatters/date_formatter_fr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onglet « Gains » : total de la semaine, solde et retraits, histogramme
/// par jour et liste des livraisons terminées.
class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myDeliveriesProvider);
    final livreur = ref.watch(currentLivreurProvider).value;
    final payouts = ref.watch(payoutRequestsProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(title: Text('Mes gains')),
      body: SafeArea(
        child: async.when(
          loading: () => const EarningsSkeleton(),
          error: (_, _) => const EmptyState(
            icon: AppIcons.offline,
            title: "Impossible de charger l'historique",
            message: 'Vérifiez votre connexion internet.',
          ),
          data: (all) {
            final done =
                all.where((d) => d.status == DeliveryStatus.delivered).toList()
                  ..sort(
                    (a, b) => (b.completedOn ?? DateTime(2000)).compareTo(
                      a.completedOn ?? DateTime(2000),
                    ),
                  );
            final stats = WeekStats.compute(all, DateTime.now());

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                Sizes.screenPadding,
                Sizes.p4,
                Sizes.screenPadding,
                Sizes.p32,
              ),
              children: staggerIn([
                _WeekTotalCard(stats: stats),
                gapH16,
                if (livreur != null) BalanceCard(livreur: livreur),
                if (payouts.isNotEmpty) ...[
                  gapH24,
                  const SectionTitle('Mes retraits'),
                  gapH8,
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: Sizes.p4),
                    child: Column(
                      children: [
                        for (final (i, request) in payouts.indexed) ...[
                          if (i > 0)
                            const Divider(indent: 72, endIndent: Sizes.p16),
                          PayoutTile(request: request),
                        ],
                      ],
                    ),
                  ),
                ],
                gapH24,
                const SectionTitle('Par jour'),
                gapH8,
                AppCard(
                  padding: const EdgeInsets.fromLTRB(
                    Sizes.p12,
                    Sizes.p48,
                    Sizes.p12,
                    Sizes.p16,
                  ),
                  child: WeeklyBarChart(
                    values: stats.dailyEarnings,
                    valueLabel: CurrencyFormatter.shortUsd,
                  ),
                ),
                gapH24,
                const SectionTitle('Livraisons terminées'),
                gapH8,
                if (done.isEmpty)
                  AppCard(
                    child: Row(
                      children: [
                        IconTile(
                          icon: AppIcons.invoice,
                          color: context.palette.textSecondary,
                        ),
                        gapW12,
                        Expanded(
                          child: Text(
                            'Vos livraisons terminées apparaîtront ici.',
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  AppCard(
                    padding: const EdgeInsets.symmetric(vertical: Sizes.p4),
                    child: Column(
                      children: [
                        for (final (i, delivery) in done.take(30).indexed) ...[
                          if (i > 0)
                            const Divider(indent: 72, endIndent: Sizes.p16),
                          _HistoryTile(delivery: delivery),
                        ],
                      ],
                    ),
                  ),
              ]),
            );
          },
        ),
      ),
    );
  }
}

/// Total de la semaine, nombre de livraisons et évolution.
class _WeekTotalCard extends StatelessWidget {
  const _WeekTotalCard({required this.stats});

  final WeekStats stats;

  @override
  Widget build(BuildContext context) {
    final delta = stats.earningsDelta;

    return HeroBackground(
      child: Padding(
        padding: const EdgeInsets.all(Sizes.p24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total de la semaine',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            gapH8,
            CountUp(
              value: stats.totalEarnings,
              format: CurrencyFormatter.formatUsd,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
                height: 1.1,
              ),
            ),
            gapH16,
            Wrap(
              spacing: Sizes.p8,
              runSpacing: Sizes.p8,
              children: [
                HeroChip(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppIcon(AppIcons.delivered),
                      gapW4,
                      Text(
                        '${stats.totalCount} livraison'
                        '${stats.totalCount > 1 ? 's' : ''}',
                      ),
                    ],
                  ),
                ),
                if (delta != null && stats.totalEarnings > 0)
                  HeroChip(
                    color: (delta >= 0 ? AppColors.success : AppColors.error)
                        .withValues(alpha: 0.3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppIcon(
                          delta >= 0 ? AppIcons.trendUp : AppIcons.trendDown,
                        ),
                        gapW4,
                        Text(
                          '${delta >= 0 ? '+' : ''}'
                          '${delta.toStringAsFixed(0)}% vs semaine dernière',
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.delivery});

  final DeliveryModel delivery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = delivery.completedOn;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Sizes.p16,
        vertical: Sizes.p12,
      ),
      child: Row(
        children: [
          const IconTile(icon: AppIcons.check, color: AppColors.success),
          gapW12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  delivery.dropoff.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall,
                ),
                Text(
                  [
                    if (date != null) DateFormatterFr.dayLabel(date),
                    delivery.shortRef,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          gapW8,
          Text(
            '+${CurrencyFormatter.formatUsd(delivery.deliveryFee)}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

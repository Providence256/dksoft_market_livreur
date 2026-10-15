import 'package:dksoft_market_livreur/core/widgets/app_card.dart';
import 'package:dksoft_market_livreur/core/widgets/empty_state.dart';
import 'package:dksoft_market_livreur/core/widgets/section_title.dart';
import 'package:dksoft_market_livreur/core/widgets/weekly_bar_chart.dart';
import 'package:dksoft_market_livreur/features/dashboard/presentation/dashboard_screen.dart';
import 'package:dksoft_market_livreur/features/deliveries/data/deliveries_repository.dart';
import 'package:dksoft_market_livreur/features/deliveries/domain/delivery_model.dart';
import 'package:dksoft_market_livreur/features/earnings/domain/week_stats.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/formatters/currency_formatter.dart';
import 'package:dksoft_market_livreur/utils/formatters/date_formatter_fr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onglet « Gains » : total de la semaine, histogramme par jour et liste
/// des livraisons terminées.
class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final async = ref.watch(myDeliveriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes gains')),
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const EmptyState(
            icon: Icons.wifi_off_rounded,
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
              padding: const EdgeInsets.all(Sizes.p16),
              children: [
                // ---- Total de la semaine ----
                Container(
                  padding: const EdgeInsets.all(Sizes.p20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cette semaine',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      gapH4,
                      Text(
                        CurrencyFormatter.formatUsd(stats.totalEarnings),
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontSize: 30,
                        ),
                      ),
                      gapH4,
                      Text(
                        '${stats.totalCount} livraison'
                        '${stats.totalCount > 1 ? 's' : ''}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.secondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                gapH24,
                const SectionTitle('Par jour'),
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
                const SectionTitle('Livraisons terminées'),
                gapH12,
                if (done.isEmpty)
                  const AppCard(
                    child: Text(
                      'Vos livraisons terminées apparaîtront ici.',
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  for (final delivery in done.take(30)) ...[
                    _HistoryTile(delivery: delivery),
                    gapH8,
                  ],
              ],
            );
          },
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

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: Sizes.p16,
        vertical: Sizes.p12,
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.check_rounded, color: AppColors.success),
          ),
          gapW12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(delivery.shortRef, style: theme.textTheme.bodyMedium),
                Text(
                  [
                    if (date != null) DateFormatterFr.dayLabel(date),
                    delivery.dropoff.name,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Text(
            CurrencyFormatter.formatUsd(delivery.deliveryFee),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

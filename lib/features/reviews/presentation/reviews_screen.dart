import 'package:dksoft_market_livreur/features/reviews/presentation/reviews_skeleton.dart';
import 'package:dksoft_market_livreur/core/animations/motion.dart';
import 'package:dksoft_market_livreur/core/widgets/app_card.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/core/widgets/empty_state.dart';
import 'package:dksoft_market_livreur/core/widgets/initials_avatar.dart';
import 'package:dksoft_market_livreur/features/reviews/data/reviews_repository.dart';
import 'package:dksoft_market_livreur/features/reviews/domain/livreur_review.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/formatters/date_formatter_fr.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// « Mes avis » : la note moyenne laissée par les dealers, sa répartition,
/// et chaque avis (qui, combien d'étoiles, quand, et ce qu'il a écrit).
class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviews = ref.watch(myReviewsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes avis')),
      body: SafeArea(
        child: reviews.when(
          loading: () => const ReviewsSkeleton(),
          error: (_, _) => const EmptyState(
            icon: AppIcons.offline,
            title: 'Impossible de charger vos avis',
            message: 'Vérifiez votre connexion internet.',
          ),
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(
                icon: AppIcons.star,
                color: AppColors.amber,
                title: 'Pas encore d’avis',
                message:
                    'Après chaque livraison, le dealer peut vous noter. '
                    'Ses avis apparaîtront ici.',
              );
            }
            final summary = ReviewsSummary(list);
            return ListView(
              padding: const EdgeInsets.fromLTRB(
                Sizes.screenPadding,
                Sizes.p4,
                Sizes.screenPadding,
                Sizes.p32,
              ),
              children: staggerIn([
                _SummaryCard(summary: summary),
                gapH24,
                Text(
                  '${summary.count} avis',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                gapH8,
                for (final review in list) ...[
                  _ReviewCard(review: review),
                  gapH12,
                ],
              ]),
            );
          },
        ),
      ),
    );
  }
}

/// Étoiles pleines / vides.
class Stars extends StatelessWidget {
  const Stars({super.key, required this.value, this.size = 16});

  /// Note, éventuellement décimale (arrondie à l'étoile la plus proche).
  final double value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final full = value.round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 2,
      children: [
        for (var i = 1; i <= 5; i++)
          AppIcon(
            AppIcons.star,
            size: size,
            color: i <= full ? AppColors.amber : context.palette.border,
            strokeWidth: i <= full ? 2.2 : 1.5,
          ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final ReviewsSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = context.palette;

    return AppCard(
      padding: const EdgeInsets.all(Sizes.p20),
      child: Row(
        children: [
          Column(
            children: [
              Text(
                summary.average.toStringAsFixed(1),
                style: theme.textTheme.displaySmall,
              ),
              Stars(value: summary.average, size: 18),
              gapH4,
              Text('${summary.count} avis', style: theme.textTheme.bodySmall),
            ],
          ),
          gapW24,
          Expanded(
            child: Column(
              children: [
                for (var stars = 5; stars >= 1; stars--)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 14,
                          child: Text(
                            '$stars',
                            style: theme.textTheme.labelMedium,
                          ),
                        ),
                        gapW8,
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: summary.count == 0
                                  ? 0
                                  : summary.countFor(stars) / summary.count,
                              minHeight: 7,
                              color: AppColors.amber,
                              backgroundColor: palette.surfaceMuted,
                            ),
                          ),
                        ),
                        gapW8,
                        SizedBox(
                          width: 22,
                          child: Text(
                            '${summary.countFor(stars)}',
                            textAlign: TextAlign.end,
                            style: theme.textTheme.labelMedium,
                          ),
                        ),
                      ],
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

class _ReviewCard extends ConsumerWidget {
  const _ReviewCard({required this.review});

  final LivreurReview review;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final name =
        ref.watch(dealerNameProvider(review.dealerId)).value ?? 'Un dealer';
    final date = review.createdAt;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialsAvatar(name: name, size: 40),
              gapW12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    if (date != null)
                      Text(
                        DateFormatterFr.dayLabel(date),
                        style: theme.textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              Stars(value: review.rating.toDouble()),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            gapH12,
            Text(
              '« ${review.comment} »',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.palette.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

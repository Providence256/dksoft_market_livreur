import 'package:dksoft_market_livreur/core/widgets/skeleton.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';

/// Accueil en chargement : mêmes blocs, aux mêmes places, que l'écran
/// réel (salutation, disponibilité, chiffres clés, course).
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Sizes.screenPadding,
          Sizes.p12,
          Sizes.screenPadding,
          Sizes.p24,
        ),
        children: [
          const Row(
            children: [
              SkeletonBox.circle(size: 50),
              gapW12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: 0.7,
                      child: SkeletonBox.line(height: 18),
                    ),
                    gapH8,
                    FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: 0.4,
                      child: SkeletonBox.line(height: 11),
                    ),
                  ],
                ),
              ),
              gapW12,
              SkeletonBox.circle(size: 48),
            ],
          ),
          gapH20,
          const SkeletonBox(height: 104, radius: Radii.xl),
          gapH16,
          Row(
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) gapW12,
                const Expanded(
                  child: SkeletonBox(height: 116, radius: Radii.lg),
                ),
              ],
            ],
          ),
          gapH24,
          const SkeletonBox.line(width: 140, height: 14),
          gapH12,
          const SkeletonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SkeletonBox(width: 44, height: 44),
                    gapW12,
                    Expanded(child: SkeletonBox.line(height: 14)),
                    gapW24,
                    SkeletonBox.line(width: 56, height: 22),
                  ],
                ),
                gapH20,
                SkeletonBox.line(),
                gapH12,
                FractionallySizedBox(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: 0.7,
                  child: SkeletonBox.line(),
                ),
                gapH20,
                SkeletonBox(height: 50, radius: Radii.md),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:dksoft_market_livreur/core/widgets/skeleton.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';

/// Gains en chargement : total de la semaine, solde, histogramme et
/// livraisons terminées.
class EarningsSkeleton extends StatelessWidget {
  const EarningsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Sizes.screenPadding,
          Sizes.p4,
          Sizes.screenPadding,
          Sizes.p32,
        ),
        children: [
          const SkeletonBox(height: 168, radius: Radii.xl),
          gapH16,
          const SkeletonCard(
            child: Row(
              children: [
                SkeletonBox(width: 44, height: 44),
                gapW12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox.line(width: 90, height: 10),
                      gapH8,
                      SkeletonBox.line(width: 120, height: 20),
                    ],
                  ),
                ),
                SkeletonBox(width: 96, height: 40, radius: Radii.md),
              ],
            ),
          ),
          gapH24,
          const SkeletonBox.line(width: 90, height: 14),
          gapH12,
          SkeletonCard(
            padding: const EdgeInsets.fromLTRB(
              Sizes.p16,
              Sizes.p48,
              Sizes.p16,
              Sizes.p16,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (i, h) in const [
                  40.0,
                  70,
                  55,
                  95,
                  30,
                  80,
                  60,
                ].indexed) ...[
                  if (i > 0) gapW12,
                  Expanded(child: SkeletonBox(height: h.toDouble())),
                ],
              ],
            ),
          ),
          gapH24,
          const SkeletonBox.line(width: 160, height: 14),
          gapH12,
          SkeletonCard(
            padding: const EdgeInsets.symmetric(vertical: Sizes.p4),
            child: Column(
              children: [for (var i = 0; i < 3; i++) const SkeletonRow()],
            ),
          ),
        ],
      ),
    );
  }
}

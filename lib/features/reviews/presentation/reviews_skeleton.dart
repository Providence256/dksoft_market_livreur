import 'package:dksoft_market_livreur/core/widgets/skeleton.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';

/// Avis en chargement : la carte de moyenne puis quelques avis.
class ReviewsSkeleton extends StatelessWidget {
  const ReviewsSkeleton({super.key});

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
          SkeletonCard(
            padding: const EdgeInsets.all(Sizes.p20),
            child: Row(
              children: [
                const Column(
                  children: [
                    SkeletonBox(width: 64, height: 40),
                    gapH8,
                    SkeletonBox.line(width: 80, height: 10),
                  ],
                ),
                gapW24,
                Expanded(
                  child: Column(
                    children: [
                      for (var i = 0; i < 5; i++) ...[
                        if (i > 0) gapH8,
                        const SkeletonBox.line(height: 8),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          gapH24,
          const SkeletonBox.line(width: 80, height: 16),
          gapH12,
          for (var i = 0; i < 3; i++) ...[
            const SkeletonCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SkeletonBox.circle(size: 40),
                      gapW12,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBox.line(width: 120),
                            gapH8,
                            SkeletonBox.line(width: 80, height: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                  gapH16,
                  SkeletonBox.line(height: 10),
                  gapH8,
                  FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: 0.6,
                    child: SkeletonBox.line(height: 10),
                  ),
                ],
              ),
            ),
            gapH12,
          ],
        ],
      ),
    );
  }
}

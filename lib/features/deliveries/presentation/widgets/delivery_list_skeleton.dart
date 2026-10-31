import 'package:dksoft_market_livreur/core/widgets/skeleton.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';

/// Demandes en chargement : quelques cartes de course (en-tête et gain,
/// trajet, boutons Refuser / Accepter).
class DeliveryListSkeleton extends StatelessWidget {
  const DeliveryListSkeleton({super.key, this.count = 3});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          Sizes.screenPadding,
          Sizes.p4,
          Sizes.screenPadding,
          Sizes.p24,
        ),
        itemCount: count,
        separatorBuilder: (_, _) => gapH12,
        itemBuilder: (_, _) => const _DeliveryCardSkeleton(),
      ),
    );
  }
}

class _DeliveryCardSkeleton extends StatelessWidget {
  const _DeliveryCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SkeletonCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(width: 44, height: 44),
              gapW12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: 0.6,
                      child: SkeletonBox.line(height: 14),
                    ),
                    gapH8,
                    FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: 0.4,
                      child: SkeletonBox.line(height: 10),
                    ),
                  ],
                ),
              ),
              gapW12,
              SkeletonBox(width: 64, height: 28, radius: Radii.pill),
            ],
          ),
          gapH20,
          _StopLine(widthFactor: 0.75),
          gapH12,
          _StopLine(widthFactor: 0.55),
          gapH20,
          Row(
            children: [
              Expanded(child: SkeletonBox(height: 48, radius: Radii.md)),
              gapW12,
              Expanded(child: SkeletonBox(height: 48, radius: Radii.md)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StopLine extends StatelessWidget {
  const _StopLine({required this.widthFactor});

  final double widthFactor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SkeletonBox.circle(size: 14),
        gapW12,
        Expanded(
          child: FractionallySizedBox(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: widthFactor,
            child: const SkeletonBox.line(),
          ),
        ),
      ],
    );
  }
}

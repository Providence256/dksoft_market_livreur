import 'package:dksoft_market_livreur/core/widgets/skeleton.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';

/// Profil en chargement : en-tête, raccourcis, moto.
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    Widget rows(int count) => SkeletonCard(
      padding: const EdgeInsets.symmetric(vertical: Sizes.p4),
      child: Column(
        children: [for (var i = 0; i < count; i++) const SkeletonRow()],
      ),
    );

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
          const SkeletonBox(height: 118, radius: Radii.xl),
          gapH24,
          rows(2),
          gapH24,
          const SkeletonBox.line(width: 100, height: 14),
          gapH12,
          rows(3),
        ],
      ),
    );
  }
}

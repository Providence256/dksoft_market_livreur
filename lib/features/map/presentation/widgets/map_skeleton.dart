import 'package:dksoft_market_livreur/core/widgets/skeleton.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:flutter/material.dart';

/// Écran de carte en chargement : le fond de carte, le bouton retour et
/// la feuille du bas (titre, détails, bouton d'action).
class MapSkeleton extends StatelessWidget {
  const MapSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Shimmer(
      child: Stack(
        children: [
          const Positioned.fill(child: SkeletonBox(radius: 0)),
          Positioned(
            top: top + Sizes.p12,
            left: Sizes.p16,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: palette.surface,
                shape: BoxShape.circle,
                boxShadow: AppShadows.floating,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                Sizes.screenPadding,
                Sizes.p12,
                Sizes.screenPadding,
                bottom + Sizes.p16,
              ),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(Radii.xl),
                ),
                boxShadow: AppShadows.sheet,
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: SkeletonBox.line(width: 40, height: 5)),
                  gapH20,
                  Row(
                    children: [
                      SkeletonBox(width: 48, height: 48),
                      gapW12,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FractionallySizedBox(
                              alignment: AlignmentDirectional.centerStart,
                              widthFactor: 0.65,
                              child: SkeletonBox.line(height: 16),
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
                    ],
                  ),
                  gapH20,
                  SkeletonBox.line(),
                  gapH12,
                  FractionallySizedBox(
                    alignment: AlignmentDirectional.centerStart,
                    widthFactor: 0.6,
                    child: SkeletonBox.line(),
                  ),
                  gapH24,
                  SkeletonBox(height: Sizes.controlHeight, radius: Radii.md),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

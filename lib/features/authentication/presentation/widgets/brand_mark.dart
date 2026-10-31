import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';

/// Logo de l'application : moto blanche sur carré orange, et le nom.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.onDark = false});

  /// Posé sur un fond marine : textes en blanc.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final textColor = onDark ? Colors.white : context.palette.textPrimary;

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.secondaryLight, AppColors.secondaryDark],
            ),
            borderRadius: BorderRadius.circular(Radii.md),
            boxShadow: AppShadows.glow(AppColors.secondary),
          ),
          child: const Center(
            child: AppIcon(AppIcons.moto, color: Colors.white, size: 28),
          ),
        ),
        gapW12,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dksoft Livreur',
              style: TextStyle(
                color: textColor,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Espace motard',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.65),
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

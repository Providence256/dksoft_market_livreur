import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';

/// Écran temporaire de l'étape 1 : sert uniquement à vérifier que le
/// projet, le thème (Poppins, couleurs) et Firebase se lancent bien.
/// Il sera remplacé par le splash puis le login à l'étape 2.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Sizes.p24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(Sizes.p24),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.two_wheeler,
                    color: AppColors.secondary,
                    size: 48,
                  ),
                ),
                gapH16,
                Text('Dksoft Livreur', style: textTheme.titleLarge),
                gapH8,
                Text(
                  'Application motard — étape 1 OK',
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:dksoft_market_livreur/core/animations/motion.dart';
import 'package:dksoft_market_livreur/core/widgets/toast.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/core/widgets/hero_card.dart';
import 'package:dksoft_market_livreur/features/dashboard/presentation/availability_controller.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/core/widgets/loading_dots.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Carte marine de l'accueil : le motard passe en ligne ou hors ligne.
class AvailabilityCard extends ConsumerWidget {
  const AvailabilityCard({super.key, required this.disponible});

  final bool disponible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(availabilityControllerProvider).isLoading;

    ref.listen<AsyncValue<void>>(availabilityControllerProvider, (_, next) {
      if (next.hasError) {
        Toast.error(context, next.error!);
      }
    });

    void toggle(bool value) {
      HapticFeedback.mediumImpact();
      ref.read(availabilityControllerProvider.notifier).setDisponible(value);
    }

    return Pressable(
      onTap: isLoading ? null : () => toggle(!disponible),
      scale: 0.98,
      child: HeroBackground(
        child: Padding(
          padding: const EdgeInsets.all(Sizes.p20),
          child: Row(
            children: [
              AnimatedContainer(
                duration: Motion.medium,
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: disponible
                      ? AppColors.success
                      : Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(Radii.md),
                ),
                child: const Center(
                  child: AppIcon(AppIcons.moto, size: 26, color: Colors.white),
                ),
              ),
              gapW16,
              Expanded(
                child: AnimatedSwitcher(
                  duration: Motion.fast,
                  child: Column(
                    key: ValueKey(disponible),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        disponible
                            ? 'Vous êtes en ligne'
                            : 'Vous êtes hors ligne',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      gapH4,
                      Text(
                        disponible
                            ? 'Les nouvelles courses vous sont proposées'
                            : 'Activez pour recevoir des courses',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              gapW8,
              if (isLoading)
                const SizedBox(
                  width: 60,
                  height: 40,
                  child: Center(child: LoadingDots(color: Colors.white)),
                )
              else
                Switch(
                  value: disponible,
                  onChanged: toggle,
                  trackColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.selected)
                        ? AppColors.success
                        : Colors.white.withValues(alpha: 0.2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

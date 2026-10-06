import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Ligne de l'étape « moto » : un indicateur à gauche (fait / en cours /
/// verrouillé) et le champ à droite. Les lignes se débloquent une à une,
/// dans l'ordre.
class ProgressRow extends StatelessWidget {
  const ProgressRow({
    super.key,
    required this.child,
    required this.done,
    required this.active,
  });

  final Widget child;

  /// Rempli : coche verte.
  final bool done;

  /// Prochaine ligne à remplir : point orange.
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _Indicator(done: done, active: active),
        const SizedBox(width: 16),
        Expanded(child: child),
      ],
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({required this.done, required this.active});

  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AppColors.success : AppColors.cardLight,
      ),
      child: done
          ? const Icon(Icons.check, size: 18, color: Colors.white)
          : active
          ? Center(
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary,
                ),
              ),
            )
          : null,
    );
  }
}

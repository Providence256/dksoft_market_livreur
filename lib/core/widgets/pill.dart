import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:flutter/material.dart';

/// Couleurs prédéfinies d'une [Pill], selon le thème clair ou sombre.
enum PillTone {
  neutral,
  brand,
  accent,
  success,
  warning,
  error;

  (Color, Color) colorsOf(BuildContext context) {
    final p = context.palette;
    return switch (this) {
      PillTone.neutral => (p.textSecondary, p.surfaceMuted),
      PillTone.brand => (p.primary, p.primarySoft),
      PillTone.accent => (AppColors.secondary, p.secondarySoft),
      PillTone.success => (AppColors.success, p.successSoft),
      PillTone.warning => (AppColors.warning, p.warningSoft),
      PillTone.error => (AppColors.error, p.errorSoft),
    };
  }
}

/// Petite étiquette arrondie (statut, urgence, compteur…).
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    this.tone = PillTone.neutral,
    this.icon,
  });

  final String label;
  final PillTone tone;
  final AppIconData? icon;

  @override
  Widget build(BuildContext context) {
    final (foreground, background) = tone.colorsOf(context);
    return Container(
      padding: EdgeInsets.fromLTRB(icon == null ? 10 : 8, 4, 10, 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            AppIcon(icon!, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

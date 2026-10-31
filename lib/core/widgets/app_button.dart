import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/core/widgets/loading_dots.dart';
import 'package:flutter/material.dart';

enum AppButtonVariant {
  /// Action principale (marine).
  primary,

  /// Action mise en avant (orange) : accepter, démarrer.
  accent,

  /// Validation finale (vert) : livré.
  success,

  /// Action destructive (rouge plein).
  danger,

  /// Action secondaire sur fond gris clair.
  tonal,

  /// Contour discret.
  outlined,
}

/// Bouton de l'application : pleine largeur par défaut, hauteur fixe, avec
/// icône facultative et état de chargement (spinner à la place du texte,
/// bouton désactivé).
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
    this.height = Sizes.controlHeight,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppIconData? icon;
  final bool loading;
  final bool expand;
  final double height;

  (Color, Color) _colorsOf(BuildContext context) {
    final p = context.palette;
    return switch (variant) {
      // En sombre le bleu est éclairci : texte marine pour rester lisible.
      AppButtonVariant.primary => (
        p.primary,
        context.isDark ? AppColors.primaryDark : Colors.white,
      ),
      AppButtonVariant.accent => (AppColors.secondary, Colors.white),
      AppButtonVariant.success => (AppColors.success, Colors.white),
      AppButtonVariant.danger => (AppColors.error, Colors.white),
      AppButtonVariant.tonal => (p.surfaceMuted, p.textPrimary),
      AppButtonVariant.outlined => (Colors.transparent, p.textPrimary),
    };
  }

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _colorsOf(context);
    final enabled = onPressed != null && !loading;
    final isOutlined = variant == AppButtonVariant.outlined;

    final child = loading
        ? LoadingDots(color: foreground)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[AppIcon(icon!, size: 20), gapW8],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    return FilledButton(
      onPressed: enabled ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        // En chargement le bouton garde sa couleur : seuls les points remplacent le texte.
        disabledBackgroundColor: loading
            ? background
            : isOutlined
            ? Colors.transparent
            : context.palette.surfaceMuted,
        disabledForegroundColor: loading
            ? foreground
            : context.palette.textMuted,
        minimumSize: Size(expand ? double.infinity : 64, height),
        side: isOutlined
            ? BorderSide(color: context.palette.border, width: 1.2)
            : null,
      ),
      child: child,
    );
  }
}

import 'package:dksoft_market_livreur/core/animations/motion.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';

/// Surface flottante posée sur la carte : blanche, arrondie, ombre douce.
class MapGlass extends StatelessWidget {
  const MapGlass({
    super.key,
    required this.child,
    this.radius = Radii.lg,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: AppShadows.floating,
      ),
      // Pas de BackdropFilter : sur iOS, un flou posé sur la carte native
      // empêche celle-ci de dessiner ses tuiles (rues, quartiers…).
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: context.palette.surface.withValues(alpha: 0.96),
          borderRadius: borderRadius,
        ),
        child: child,
      ),
    );
  }
}

/// Bouton seul posé sur la carte (retour, vue d'ensemble…).
class MapRoundButton extends StatelessWidget {
  const MapRoundButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
  });

  final AppIconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  /// Option activée (ex. vue satellite) : fond marine.
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Pressable(
        onTap: onPressed,
        scale: 0.9,
        child: active
            ? Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.palette.primary,
                  borderRadius: BorderRadius.circular(Radii.md),
                  boxShadow: AppShadows.floating,
                ),
                child: Center(
                  child: AppIcon(icon, size: 22, color: Colors.white),
                ),
              )
            : MapGlass(
                radius: Radii.md,
                child: SizedBox.square(
                  dimension: 48,
                  child: Center(
                    child: AppIcon(
                      icon,
                      size: 22,
                      color: context.palette.textPrimary,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// Un bouton d'un [MapControlGroup].
class MapControl {
  const MapControl({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.active = false,
  });

  final AppIconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final bool active;
}

/// Colonne de boutons de carte réunis dans une seule capsule de verre,
/// séparés par un filet (vue d'ensemble, satellite, ma position…).
class MapControlGroup extends StatelessWidget {
  const MapControlGroup({super.key, required this.controls});

  final List<MapControl> controls;

  @override
  Widget build(BuildContext context) {
    return MapGlass(
      radius: Radii.lg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, control) in controls.indexed) ...[
            if (i > 0)
              Container(width: 26, height: 1, color: context.palette.border),
            Tooltip(
              message: control.tooltip,
              child: Pressable(
                onTap: control.onPressed,
                scale: 0.88,
                child: SizedBox.square(
                  dimension: 50,
                  child: Center(
                    child: AnimatedContainer(
                      duration: Motion.fast,
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: control.active
                            ? context.palette.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(Radii.sm),
                      ),
                      child: Center(
                        child: AppIcon(
                          control.icon,
                          size: 22,
                          color: control.active
                              ? Colors.white
                              : context.palette.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

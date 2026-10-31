import 'package:dksoft_market_livreur/core/animations/motion.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';

/// Surface blanche arrondie avec une ombre très douce : brique de base de
/// tous les écrans. Cliquable, elle s'enfonce légèrement sous le doigt.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Sizes.p16),
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = Radii.lg,
    this.elevated = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Fond ; la surface du thème par défaut.
  final Color? color;

  /// Contour coloré pour mettre une carte en avant (sélection, course en
  /// cours).
  final Color? borderColor;
  final double radius;

  /// Sans ombre : pour une carte posée dans une autre surface blanche.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: Motion.fast,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? context.palette.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color:
              borderColor ??
              (elevated ? Colors.transparent : context.palette.border),
          width: borderColor != null ? 1.5 : 1,
        ),
        boxShadow: elevated ? AppShadows.card : null,
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Pressable(onTap: onTap, scale: 0.98, child: card);
  }
}

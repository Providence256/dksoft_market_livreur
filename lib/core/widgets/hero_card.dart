import 'dart:math' as math;

import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';

/// Fond signature de l'app : dégradé marine profond, halo orange dans un
/// coin et anneaux décoratifs. Sert aux blocs mis en avant (gains,
/// profil, connexion).
class HeroBackground extends StatelessWidget {
  const HeroBackground({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(Radii.xl)),
    this.shadow = true,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 14),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: CustomPaint(painter: const _HeroPainter(), child: child),
      ),
    );
  }
}

class _HeroPainter extends CustomPainter {
  const _HeroPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Dégradé de fond.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C4485), AppColors.primary, Color(0xFF071C3D)],
          stops: [0, 0.55, 1],
        ).createShader(rect),
    );

    // Halo orange en haut à droite.
    final glowCenter = Offset(size.width * 0.92, size.height * 0.05);
    final glowRadius = math.max(size.width, size.height) * 0.6;
    canvas.drawCircle(
      glowCenter,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.38),
            AppColors.primary.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: glowCenter, radius: glowRadius)),
    );

    // Anneaux concentriques discrets.
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.07);
    final ringCenter = Offset(size.width * 0.95, size.height * 0.1);
    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(ringCenter, 46.0 * i, ring);
    }

    // Petit cercle plein en bas à gauche.
    canvas.drawCircle(
      Offset(size.width * 0.04, size.height * 1.02),
      size.height * 0.32,
      Paint()..color = Colors.white.withValues(alpha: 0.05),
    );
  }

  @override
  bool shouldRepaint(_HeroPainter oldDelegate) => false;
}

/// Pastille translucide pour poser une info sur un [HeroBackground].
class HeroChip extends StatelessWidget {
  const HeroChip({super.key, required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(Radii.pill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        child: IconTheme.merge(
          data: const IconThemeData(color: Colors.white, size: 14),
          child: child,
        ),
      ),
    );
  }
}

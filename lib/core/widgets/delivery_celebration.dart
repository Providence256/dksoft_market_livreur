import 'dart:async';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'dart:math' as math;

import 'package:dksoft_market_livreur/core/animations/motion.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Petite fête à la fin d'une course : coche qui jaillit, éclats de
/// couleur et gain qui défile. Se referme toute seule.
///
/// Prend le navigateur et non un `BuildContext` : l'écran qui l'appelle
/// peut avoir disparu (la carte laisse sa place aux demandes dès que la
/// course est terminée).
void showDeliveryCelebration(
  NavigatorState navigator, {
  required double amount,
}) {
  HapticFeedback.heavyImpact();

  navigator.push(
    RawDialogRoute<void>(
      barrierDismissible: true,
      barrierLabel: 'Fermer',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (context, _, _) => _Celebration(amount: amount),
      transitionBuilder: (context, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeIn,
        );
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    ),
  );
}

class _Celebration extends StatefulWidget {
  const _Celebration({required this.amount});

  final double amount;

  @override
  State<_Celebration> createState() => _CelebrationState();
}

class _CelebrationState extends State<_Celebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _burst.dispose();
    super.dispose();
  }

  String _format(double v) =>
      '+${v.toStringAsFixed(2).replaceAll('.', ',')} USD';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 290,
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: context.palette.primary.withValues(alpha: 0.35),
                blurRadius: 50,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 150,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _burst,
                      builder: (context, _) => CustomPaint(
                        size: const Size(150, 130),
                        painter: _BurstPainter(_burst.value),
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.elasticOut,
                      builder: (context, v, child) =>
                          Transform.scale(scale: v, child: child),
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF2BC275), AppColors.success],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.success.withValues(alpha: 0.45),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const AppIcon(
                          AppIcons.check,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              FadeSlideIn(
                delay: Duration(milliseconds: 250),
                child: Text(
                  'Course terminée !',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: context.palette.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FadeSlideIn(
                delay: const Duration(milliseconds: 380),
                child: CountUp(
                  value: widget.amount,
                  format: _format,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              FadeSlideIn(
                delay: Duration(milliseconds: 520),
                child: Text(
                  'ajoutés à vos gains',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.palette.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Éclats de couleur qui partent du centre et retombent en s'estompant.
class _BurstPainter extends CustomPainter {
  _BurstPainter(this.t);

  final double t;

  static const _colors = [
    AppColors.secondary,
    AppColors.primaryLight,
    AppColors.success,
    AppColors.secondaryLight,
    Color(0xFFFFC84A),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const count = 22;
    final eased = Curves.easeOutCubic.transform(t);

    for (var i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi + (i.isEven ? 0.12 : -0.12);
      final reach = 52 + (i % 3) * 14;
      final gravity = t * t * 18;
      final offset = Offset(
        math.cos(angle) * reach * eased,
        math.sin(angle) * reach * eased + gravity,
      );
      final fade = (1 - t).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = _colors[i % _colors.length].withValues(alpha: fade);

      if (i % 3 == 0) {
        canvas.drawCircle(center + offset, 3.4 * (1 - t * 0.4), paint);
      } else {
        canvas.save();
        canvas.translate(center.dx + offset.dx, center.dy + offset.dy);
        canvas.rotate(angle + t * 5);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: 9, height: 4),
            const Radius.circular(2),
          ),
          paint,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(_BurstPainter old) => old.t != t;
}

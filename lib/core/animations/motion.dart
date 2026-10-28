import 'dart:async';
import 'dart:math' as math;

import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Courbes et durées communes : toute l'application bouge de la même façon.
class Motion {
  Motion._();

  /// Démarrage vif, arrivée très douce (le « easeOutExpo » des apps récentes).
  static const Curve emphasized = Cubic(0.16, 1, 0.3, 1);

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 420);
  static const Duration slow = Duration(milliseconds: 750);

  /// Délai d'apparition du n-ième élément d'une liste (3 éléments à la
  /// suite au maximum, pour ne pas faire attendre).
  static Duration stagger(int index, {int step = 70, int max = 6}) =>
      Duration(milliseconds: step * math.min(index, max));
}

/// Enveloppe chaque élément d'une liste dans une apparition décalée : les
/// blocs d'un écran arrivent l'un après l'autre.
List<Widget> staggerIn(List<Widget> children, {int step = 70, int max = 7}) {
  return [
    for (final (i, child) in children.indexed)
      FadeSlideIn(
        delay: Motion.stagger(i, step: step, max: max),
        child: child,
      ),
  ];
}

/// Fait apparaître son contenu en fondu en le faisant glisser vers sa place.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 700),
    this.offset = const Offset(0, 0.14),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Décalage de départ, en fraction de la taille du contenu.
  final Offset offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _curve = CurvedAnimation(
    parent: _controller,
    curve: Motion.emphasized,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: widget.offset,
          end: Offset.zero,
        ).animate(_curve),
        child: widget.child,
      ),
    );
  }
}

/// Réagit au doigt : le contenu s'enfonce légèrement pendant l'appui et
/// revient en rebondissant, avec un léger retour haptique au toucher.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    required this.onTap,
    this.scale = 0.965,
    this.haptic = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final bool haptic;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool value) {
    if (_down != value && mounted) setState(() => _down = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: enabled
          ? () {
              if (widget.haptic) HapticFeedback.selectionClick();
              widget.onTap!();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: _down
            ? const Duration(milliseconds: 90)
            : const Duration(milliseconds: 380),
        curve: _down ? Curves.easeOut : Curves.elasticOut,
        child: widget.child,
      ),
    );
  }
}

/// Nombre qui défile de 0 jusqu'à sa valeur (et d'une valeur à l'autre
/// quand elle change).
class CountUp extends StatelessWidget {
  const CountUp({
    super.key,
    required this.value,
    required this.format,
    this.style,
    this.duration = const Duration(milliseconds: 1400),
  });

  final double value;
  final String Function(double value) format;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: Motion.emphasized,
      builder: (context, v, _) => Text(format(v), style: style),
    );
  }
}

/// Point d'état qui « respire » : un anneau qui s'étend et s'efface.
class PulsingDot extends StatefulWidget {
  const PulsingDot({super.key, required this.color, this.size = 11});

  final Color color;
  final double size;

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = widget.size * 2.6;
    return SizedBox(
      width: box,
      height: box,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: widget.size + (box - widget.size) * t,
                height: widget.size + (box - widget.size) * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: 0.38 * (1 - t)),
                ),
              ),
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Radar de recherche : des ondes qui partent d'une moto flottante, pour
/// les écrans qui attendent des courses.
class RadarPulse extends StatefulWidget {
  const RadarPulse({super.key, this.size = 190});

  final double size;

  @override
  State<RadarPulse> createState() => _RadarPulseState();
}

class _RadarPulseState extends State<RadarPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final float = math.sin(_controller.value * 2 * math.pi) * 3;
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _RadarPainter(_controller.value),
              ),
              Transform.translate(
                offset: Offset(0, float),
                child: Container(
                  width: size * 0.36,
                  height: size * 0.36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primaryLight, AppColors.primaryDark],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 22,
                        offset: Offset(0, 10 - float),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.two_wheeler_rounded,
                    color: Colors.white,
                    size: size * 0.18,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final minRadius = size.width * 0.18;
    final maxRadius = size.width / 2;

    for (var i = 0; i < 3; i++) {
      final phase = (t + i / 3) % 1;
      final radius = minRadius + (maxRadius - minRadius) * phase;
      final fade = (1 - phase);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.fill
          ..color = AppColors.secondary.withValues(alpha: 0.10 * fade),
      );
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = AppColors.secondary.withValues(alpha: 0.45 * fade),
      );
    }
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.t != t;
}

/// Écran d'attente : radar animé, titre et message.
class RadarEmptyState extends StatelessWidget {
  const RadarEmptyState({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const RadarPulse(),
            const SizedBox(height: 24),
            FadeSlideIn(
              delay: const Duration(milliseconds: 150),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            FadeSlideIn(
              delay: const Duration(milliseconds: 260),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

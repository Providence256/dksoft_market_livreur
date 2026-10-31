import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Petite courbe lissée, avec un dégradé dessous et un point à son
/// extrémité. Elle se dessine de gauche à droite à l'apparition.
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    this.color = AppColors.secondary,
    this.height = 46,
  });

  final List<double> values;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1400),
        curve: Curves.easeOutCubic,
        builder: (context, progress, _) => CustomPaint(
          painter: _SparklinePainter(
            values: values,
            color: color,
            progress: progress,
          ),
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.color,
    required this.progress,
  });

  final List<double> values;
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    const pad = 6.0;
    var minValue = values.first;
    var maxValue = values.first;
    for (final v in values) {
      if (v < minValue) minValue = v;
      if (v > maxValue) maxValue = v;
    }
    final range = maxValue - minValue;

    final points = <Offset>[
      for (final (i, v) in values.indexed)
        Offset(
          pad + i * (size.width - 2 * pad) / (values.length - 1),
          range == 0
              ? size.height - pad
              : size.height -
                    pad -
                    (v - minValue) / range * (size.height - 2 * pad),
        ),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final midX = (previous.dx + current.dx) / 2;
      path.cubicTo(midX, previous.dy, midX, current.dy, current.dx, current.dy);
    }

    final metric = path.computeMetrics().first;
    final drawn = metric.extractPath(0, metric.length * progress);
    final end =
        metric.getTangentForOffset(metric.length * progress)?.position ??
        points.last;

    // Dégradé sous la partie déjà dessinée.
    final fill = Path.from(drawn)
      ..lineTo(end.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withValues(alpha: 0.18), color.withValues(alpha: 0)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      drawn,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawCircle(end, 6, Paint()..color = Colors.white);
    canvas.drawCircle(end, 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values || old.color != color || old.progress != progress;
}

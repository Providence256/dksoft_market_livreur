import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Petite courbe lissée avec un point à son extrémité (cartes de
/// statistiques de l'accueil).
class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    this.lineColor = AppColors.secondary,
    this.dotColor = AppColors.primary,
    this.height = 46,
  });

  final List<double> values;
  final Color lineColor;
  final Color dotColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(
          values: values,
          lineColor: lineColor,
          dotColor: dotColor,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.lineColor,
    required this.dotColor,
  });

  final List<double> values;
  final Color lineColor;
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    const pad = 7.0;
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

    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final end = points.last;
    canvas.drawCircle(end, 5.5, Paint()..color = Colors.white);
    canvas.drawCircle(end, 4, Paint()..color = dotColor);
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values ||
      old.lineColor != lineColor ||
      old.dotColor != dotColor;
}

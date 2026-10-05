import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Dessine les pastilles de la carte (numéro, drapeau, coche…) et les
/// garde en mémoire : on ne redessine pas la même icône deux fois.
class MarkerIconFactory {
  final Map<String, BitmapDescriptor> _cache = {};

  /// Pastille ronde colorée avec un [label] (le numéro de l'arrêt) ou une
  /// [icon]. [pixelRatio] = densité de l'écran, pour une image nette.
  Future<BitmapDescriptor> build({
    String? label,
    IconData? icon,
    required Color color,
    required double pixelRatio,
  }) async {
    assert(label != null || icon != null);
    final key = '${label ?? icon!.codePoint}|${color.toARGB32()}|$pixelRatio';
    final cached = _cache[key];
    if (cached != null) return cached;

    const logicalSize = 44.0;
    final size = logicalSize * pixelRatio;
    final center = Offset(size / 2, size / 2);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Liseré blanc + disque coloré + ombre légère.
    canvas.drawCircle(
      center.translate(0, pixelRatio),
      size / 2 - pixelRatio,
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );
    canvas.drawCircle(
      center,
      size / 2 - pixelRatio,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      center,
      size / 2 - 4 * pixelRatio,
      Paint()..color = color,
    );

    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      text: icon != null
          ? TextSpan(
              text: String.fromCharCode(icon.codePoint),
              style: TextStyle(
                fontSize: size * 0.5,
                fontFamily: icon.fontFamily,
                package: icon.fontPackage,
                color: Colors.white,
              ),
            )
          : TextSpan(
              text: label,
              style: TextStyle(
                fontSize: size * 0.46,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
    )..layout();

    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );

    final image = await recorder.endRecording().toImage(
      size.round(),
      size.round(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    final descriptor = BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      imagePixelRatio: pixelRatio,
    );
    _cache[key] = descriptor;
    return descriptor;
  }
}

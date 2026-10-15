import 'dart:ui' as ui;

import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Icône de marqueur + point d'ancrage (le centre de la pastille, pas du
/// bitmap entier quand une étiquette est dessinée dessous).
class MarkerIcon {
  const MarkerIcon(this.descriptor, this.anchor);

  final BitmapDescriptor descriptor;
  final Offset anchor;
}

/// Point d'ancrage d'une épingle : sa pointe, en bas au centre.
const kPinAnchor = Offset(0.5, 1.0);

/// Dessine les marqueurs de la carte (pastille numérotée, drapeau, moto…,
/// avec ou sans étiquette de nom) et les garde en mémoire : on ne redessine
/// pas la même icône deux fois.
class MarkerIconFactory {
  final Map<String, MarkerIcon> _cache = {};

  /// Pastille ronde seule.
  Future<BitmapDescriptor> build({
    String? label,
    IconData? icon,
    required Color color,
    required double pixelRatio,
    double logicalSize = 44,
  }) async {
    final result = await buildLabeled(
      label: label,
      icon: icon,
      color: color,
      pixelRatio: pixelRatio,
      badgeSize: logicalSize,
    );
    return result.descriptor;
  }

  /// La moto du livreur : une petite moto vue de dessus, avec relief, dans
  /// la couleur choisie à l'inscription. Ni pilote, ni top-case, ni phare.
  /// L'avant est en haut : à faire pivoter avec `rotation` (marqueur plat).
  Future<BitmapDescriptor> buildRider(
    double pixelRatio, {
    Color color = AppColors.primary,
  }) async {
    final key = 'moto|${color.toARGB32()}|$pixelRatio';
    final cached = _cache[key];
    if (cached != null) return cached.descriptor;

    final u = pixelRatio;
    final size = 60 * u;
    final cx = size / 2;
    final cy = size / 2;

    final light = Color.lerp(color, Colors.white, 0.40)!;
    final dark = Color.lerp(color, Colors.black, 0.38)!;
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9 * u
      ..color = Colors.black.withValues(alpha: 0.35);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    RRect box(double x, double y, double w, double h, double r) =>
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, y), width: w, height: h),
          Radius.circular(r),
        );

    // Dégradé de gauche à droite : bords sombres, centre clair, comme un
    // volume arrondi éclairé d'en haut.
    Paint shaded(RRect shape) => Paint()
      ..shader = LinearGradient(
        colors: [dark, light, dark],
        stops: const [0, 0.5, 1],
      ).createShader(shape.outerRect);

    // ---- Ombre portée ----
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + 3.5 * u, cy + 3.5 * u),
        width: 17 * u,
        height: 48 * u,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.5 * u),
    );

    // ---- Pneus ----
    final tyre = Paint()..color = const Color(0xFF1A1D24);
    canvas.drawRRect(box(cx, cy - 17 * u, 5.6 * u, 14 * u, 2.8 * u), tyre);
    canvas.drawRRect(box(cx, cy + 17 * u, 6.8 * u, 15 * u, 3.4 * u), tyre);

    // ---- Garde-boue arrière et avant ----
    final rear = box(cx, cy + 14 * u, 10 * u, 11 * u, 4 * u);
    canvas.drawRRect(rear, shaded(rear));
    canvas.drawRRect(rear, outline);
    final front = box(cx, cy - 15 * u, 8 * u, 9 * u, 3.5 * u);
    canvas.drawRRect(front, shaded(front));
    canvas.drawRRect(front, outline);

    // ---- Réservoir (corps principal, brillant) ----
    final tank = box(cx, cy - 6 * u, 13 * u, 17 * u, 6 * u);
    canvas.drawRRect(tank, shaded(tank));
    canvas.drawRRect(tank, outline);
    canvas.drawRRect(
      box(cx - 2.2 * u, cy - 9 * u, 2.6 * u, 8 * u, 1.3 * u),
      Paint()..color = Colors.white.withValues(alpha: 0.55),
    );

    // ---- Selle ----
    final seat = box(cx, cy + 6 * u, 9 * u, 15 * u, 4.5 * u);
    canvas.drawRRect(
      seat,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF14161B), Color(0xFF3B414D), Color(0xFF14161B)],
          stops: [0, 0.5, 1],
        ).createShader(seat.outerRect),
    );

    // ---- Guidon avec poignées ----
    final bar = Paint()
      ..color = const Color(0xFF14171D)
      ..strokeWidth = 2.4 * u
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - 11 * u, cy - 12 * u),
      Offset(cx + 11 * u, cy - 12 * u),
      bar,
    );
    final grip = Paint()
      ..color = const Color(0xFF5A6170)
      ..strokeWidth = 3 * u
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(cx - 11.5 * u, cy - 12 * u),
      Offset(cx - 9.5 * u, cy - 12 * u),
      grip,
    );
    canvas.drawLine(
      Offset(cx + 9.5 * u, cy - 12 * u),
      Offset(cx + 11.5 * u, cy - 12 * u),
      grip,
    );

    final image = await recorder.endRecording().toImage(
      size.ceil(),
      size.ceil(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final descriptor = BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      imagePixelRatio: pixelRatio,
    );
    _cache[key] = MarkerIcon(descriptor, const Offset(0.5, 0.5));
    return descriptor;
  }

  /// Épingle classique (goutte) avec un numéro ou un symbole dedans : le
  /// bout de la pointe est le point exact. À poser avec [kPinAnchor].
  Future<BitmapDescriptor> buildPin({
    String? label,
    IconData? icon,
    required Color color,
    required double pixelRatio,
    double width = 38,
  }) async {
    assert(label != null || icon != null);
    final key =
        'pin|${label ?? icon!.codePoint}|${color.toARGB32()}|$pixelRatio|$width';
    final cached = _cache[key];
    if (cached != null) return cached.descriptor;

    final w = width * pixelRatio;
    final h = w * 1.3;
    final margin = 2 * pixelRatio;
    final cx = w / 2;
    final r = w / 2 - margin;
    final cy = margin + r;

    final head = Path()
      ..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    final tail = Path()
      ..moveTo(cx - r * 0.82, cy + r * 0.58)
      ..lineTo(cx, h - margin)
      ..lineTo(cx + r * 0.82, cy + r * 0.58)
      ..close();
    final pin = Path.combine(PathOperation.union, head, tail);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawPath(
      pin.shift(Offset(0, 1.5 * pixelRatio)),
      Paint()..color = Colors.black.withValues(alpha: 0.25),
    );
    canvas.drawPath(pin, Paint()..color = color);
    canvas.drawPath(
      pin,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * pixelRatio
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white,
    );
    // Disque blanc au centre de la tête, symbole coloré dedans.
    canvas.drawCircle(Offset(cx, cy), r * 0.58, Paint()..color = Colors.white);

    final glyph = TextPainter(
      textDirection: TextDirection.ltr,
      text: icon != null
          ? TextSpan(
              text: String.fromCharCode(icon.codePoint),
              style: TextStyle(
                fontSize: r * 0.95,
                fontFamily: icon.fontFamily,
                package: icon.fontPackage,
                color: color,
              ),
            )
          : TextSpan(
              text: label,
              style: TextStyle(
                fontSize: r * 0.9,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
    )..layout();
    glyph.paint(canvas, Offset(cx - glyph.width / 2, cy - glyph.height / 2));

    final image = await recorder.endRecording().toImage(w.ceil(), h.ceil());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final descriptor = BitmapDescriptor.bytes(
      bytes!.buffer.asUint8List(),
      imagePixelRatio: pixelRatio,
    );
    _cache[key] = MarkerIcon(descriptor, kPinAnchor);
    return descriptor;
  }

  /// Bulle de durée posée sur le tracé : « 20 » gros, « min » dessous.
  Future<BitmapDescriptor> buildEta(int minutes, double pixelRatio) async {
    final key = 'eta|$minutes|$pixelRatio';
    final cached = _cache[key];
    if (cached != null) return cached.descriptor;

    final size = 60 * pixelRatio;
    final center = Offset(size / 2, size / 2);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawCircle(
      center.translate(0, pixelRatio * 2),
      size / 2 - pixelRatio * 2,
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );
    canvas.drawCircle(
      center,
      size / 2 - pixelRatio * 2,
      Paint()..color = AppColors.primary,
    );
    canvas.drawCircle(
      center,
      size / 2 - pixelRatio * 2,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * pixelRatio
        ..color = Colors.white,
    );

    final number = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: minutes > 99 ? '99+' : '$minutes',
        style: TextStyle(
          fontSize: 22 * pixelRatio,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1,
        ),
      ),
    )..layout();
    final unit = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: 'min',
        style: TextStyle(
          fontSize: 12 * pixelRatio,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          height: 1,
        ),
      ),
    )..layout();

    final total = number.height + unit.height + 1 * pixelRatio;
    final top = (size - total) / 2;
    number.paint(canvas, Offset((size - number.width) / 2, top));
    unit.paint(
      canvas,
      Offset((size - unit.width) / 2, top + number.height + pixelRatio),
    );

    final image = await recorder.endRecording().toImage(
      size.ceil(),
      size.ceil(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final icon = MarkerIcon(
      BitmapDescriptor.bytes(
        bytes!.buffer.asUint8List(),
        imagePixelRatio: pixelRatio,
      ),
      const Offset(0.5, 0.5),
    );
    _cache[key] = icon;
    return icon.descriptor;
  }

  /// Pastille ronde avec, dessous, une étiquette blanche : [title] en gras
  /// et [subtitle] en petit (nom du commerçant, nombre d'articles…).
  Future<MarkerIcon> buildLabeled({
    String? label,
    IconData? icon,
    required Color color,
    required double pixelRatio,
    double badgeSize = 44,
    String? title,
    String? subtitle,
  }) async {
    assert(label != null || icon != null);
    final key =
        '${label ?? icon!.codePoint}|${color.toARGB32()}|$pixelRatio|'
        '$badgeSize|$title|$subtitle';
    final cached = _cache[key];
    if (cached != null) return cached;

    final badge = badgeSize * pixelRatio;
    final hasLabel = title != null && title.isNotEmpty;

    TextPainter? titlePainter;
    TextPainter? subtitlePainter;
    var pillWidth = 0.0;
    var pillHeight = 0.0;
    final padH = 10 * pixelRatio;
    final padV = 5 * pixelRatio;
    final gap = 4 * pixelRatio;

    if (hasLabel) {
      titlePainter = TextPainter(
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
        text: TextSpan(
          text: title,
          style: TextStyle(
            fontSize: 12.5 * pixelRatio,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimaryLight,
          ),
        ),
      )..layout(maxWidth: 150 * pixelRatio);

      if (subtitle != null && subtitle.isNotEmpty) {
        subtitlePainter = TextPainter(
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…',
          text: TextSpan(
            text: subtitle,
            style: TextStyle(
              fontSize: 11 * pixelRatio,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondaryLight,
            ),
          ),
        )..layout(maxWidth: 150 * pixelRatio);
      }

      final subWidth = subtitlePainter?.width ?? 0;
      final textWidth = titlePainter.width > subWidth
          ? titlePainter.width
          : subWidth;
      pillWidth = textWidth + 2 * padH;
      pillHeight =
          titlePainter.height +
          (subtitlePainter == null ? 0 : subtitlePainter.height) +
          2 * padV;
    }

    final width = hasLabel && pillWidth > badge ? pillWidth : badge;
    final height = hasLabel ? badge + gap + pillHeight : badge;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(width / 2, badge / 2);

    // ---- Pastille : ombre, liseré blanc, disque coloré, symbole ----
    canvas.drawCircle(
      center.translate(0, pixelRatio * 1.5),
      badge / 2 - pixelRatio * 1.5,
      Paint()..color = Colors.black.withValues(alpha: 0.22),
    );
    canvas.drawCircle(
      center,
      badge / 2 - pixelRatio * 1.5,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(center, badge / 2 - badge * 0.1, Paint()..color = color);

    final glyph = TextPainter(
      textDirection: TextDirection.ltr,
      text: icon != null
          ? TextSpan(
              text: String.fromCharCode(icon.codePoint),
              style: TextStyle(
                fontSize: badge * 0.5,
                fontFamily: icon.fontFamily,
                package: icon.fontPackage,
                color: Colors.white,
              ),
            )
          : TextSpan(
              text: label,
              style: TextStyle(
                fontSize: badge * 0.46,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
    )..layout();
    glyph.paint(canvas, center - Offset(glyph.width / 2, glyph.height / 2));

    // ---- Étiquette sous la pastille ----
    if (hasLabel) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          (width - pillWidth) / 2,
          badge + gap,
          pillWidth,
          pillHeight,
        ),
        Radius.circular(10 * pixelRatio),
      );
      canvas.drawRRect(
        rect.shift(Offset(0, pixelRatio)),
        Paint()..color = Colors.black.withValues(alpha: 0.16),
      );
      canvas.drawRRect(rect, Paint()..color = Colors.white);
      canvas.drawRRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = pixelRatio
          ..color = AppColors.dividerLight,
      );

      var y = badge + gap + padV;
      titlePainter!.paint(canvas, Offset((width - titlePainter.width) / 2, y));
      y += titlePainter.height;
      subtitlePainter?.paint(
        canvas,
        Offset((width - subtitlePainter.width) / 2, y),
      );
    }

    final image = await recorder.endRecording().toImage(
      width.ceil(),
      height.ceil(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    final result = MarkerIcon(
      BitmapDescriptor.bytes(
        bytes!.buffer.asUint8List(),
        imagePixelRatio: pixelRatio,
      ),
      Offset(0.5, (badge / 2) / height),
    );
    _cache[key] = result;
    return result;
  }
}

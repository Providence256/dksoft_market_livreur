import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Position ramenée sur la route, avec la direction de la route à cet endroit.
class SnappedPoint {
  const SnappedPoint(this.point, this.bearing);

  final LatLng point;

  /// Cap de la route (degrés, 0 = nord, sens horaire).
  final double bearing;
}

/// Pose [p] sur le tracé [route] s'il en est à moins de [maxMeters] ; sinon
/// renvoie null (le livreur n'est pas sur la route : on garde son GPS brut).
///
/// Le GPS dérive de quelques mètres : sans cet ajustement, la moto roule
/// à côté de la rue ou en travers. Le cap de la route donne aussi une
/// orientation propre, sans les à-coups du capteur.
SnappedPoint? snapToRoute(
  LatLng p,
  List<LatLng>? route, {
  double maxMeters = 35,
  double? preferBearing,
}) {
  if (route == null || route.length < 2) return null;

  // Repère local en mètres autour de p (suffisant sur quelques centaines
  // de mètres).
  const metersPerDegree = 111320.0;
  final cosLat = math.cos(p.latitude * math.pi / 180);

  double x(LatLng q) => (q.longitude - p.longitude) * metersPerDegree * cosLat;
  double y(LatLng q) => (q.latitude - p.latitude) * metersPerDegree;

  var bestDistance = double.infinity;
  LatLng? bestPoint;
  double? bestBearing;

  for (var i = 0; i < route.length - 1; i++) {
    final ax = x(route[i]);
    final ay = y(route[i]);
    final bx = x(route[i + 1]);
    final by = y(route[i + 1]);
    final dx = bx - ax;
    final dy = by - ay;
    final lengthSquared = dx * dx + dy * dy;
    if (lengthSquared < 0.01) continue;

    // Projection de l'origine (p) sur le segment [a, b].
    final t = ((-ax) * dx + (-ay) * dy) / lengthSquared;
    final clamped = t.clamp(0.0, 1.0);
    final px = ax + dx * clamped;
    final py = ay + dy * clamped;
    final distance = math.sqrt(px * px + py * py);

    // Le tracé repasse parfois par la même rue dans l'autre sens (trajet
    // aller vers le commerçant puis retour) : on écarte les segments qui
    // vont à contresens du cap connu du livreur.
    var segmentBearing = math.atan2(dx, dy) * 180 / math.pi;
    if (segmentBearing < 0) segmentBearing += 360;
    if (preferBearing != null) {
      final diff = ((segmentBearing - preferBearing + 540) % 360) - 180;
      if (diff.abs() > 100) continue;
    }

    if (distance < bestDistance) {
      bestDistance = distance;
      bestPoint = LatLng(
        p.latitude + py / metersPerDegree,
        p.longitude + px / (metersPerDegree * cosLat),
      );
      bestBearing = segmentBearing;
    }
  }

  if (bestPoint == null || bestDistance > maxMeters) return null;
  return SnappedPoint(bestPoint, bestBearing!);
}

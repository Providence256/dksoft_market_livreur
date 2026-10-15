import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Une manœuvre de l'itinéraire : « Tournez à gauche sur Ave Kasa-Vubu ».
class RouteStep {
  const RouteStep({
    required this.type,
    required this.modifier,
    required this.street,
    required this.distanceMeters,
    required this.location,
  });

  /// Type de manœuvre OSRM (turn, depart, arrive, roundabout…).
  final String type;

  /// Direction (left, right, slight left, straight, uturn…).
  final String modifier;

  /// Nom de la rue sur laquelle on arrive (peut être vide).
  final String street;

  /// Longueur de l'étape qui suit la manœuvre.
  final double distanceMeters;

  /// Où la manœuvre a lieu.
  final LatLng location;

  bool get isDepart => type == 'depart';
  bool get isArrive => type == 'arrive';

  String get instruction {
    String side(String left, String right, String fallback) =>
        modifier.contains('left')
        ? left
        : modifier.contains('right')
        ? right
        : fallback;

    switch (type) {
      case 'depart':
        return 'Démarrez';
      case 'arrive':
        return 'Vous êtes arrivé';
      case 'roundabout':
      case 'rotary':
      case 'roundabout turn':
        return 'Au rond-point, continuez';
      case 'merge':
        return 'Insérez-vous';
      case 'fork':
        return side('Prenez à gauche', 'Prenez à droite', 'Continuez');
      case 'continue':
      case 'new name':
        return side(
          'Serrez à gauche',
          'Serrez à droite',
          'Continuez tout droit',
        );
      default:
        if (modifier == 'uturn') return 'Faites demi-tour';
        if (modifier == 'straight') return 'Continuez tout droit';
        if (modifier.startsWith('slight')) {
          return side(
            'Tournez légèrement à gauche',
            'Tournez légèrement à droite',
            'Continuez',
          );
        }
        if (modifier.startsWith('sharp')) {
          return side(
            'Tournez franchement à gauche',
            'Tournez franchement à droite',
            'Continuez',
          );
        }
        return side('Tournez à gauche', 'Tournez à droite', 'Continuez');
    }
  }
}

/// Un itinéraire routier : le tracé qui suit les rues, la distance et la
/// durée totales, et le détail par étape (de point en point).
class RouteInfo {
  const RouteInfo({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.legMeters = const [],
    this.legSeconds = const [],
    this.legSteps = const [],
  });

  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  /// Distance et durée de chaque étape (étape 0 = jusqu'au premier arrêt).
  final List<double> legMeters;
  final List<double> legSeconds;

  /// Manœuvres de chaque étape (même ordre que [legMeters]).
  final List<List<RouteStep>> legSteps;

  List<RouteStep> get firstLegSteps =>
      legSteps.isEmpty ? const [] : legSteps.first;

  int get minutes => (durationSeconds / 60).ceil().clamp(1, 9999);

  double? get firstLegMeters => legMeters.isEmpty ? null : legMeters.first;
  double? get firstLegSeconds => legSeconds.isEmpty ? null : legSeconds.first;

  /// Point situé à mi-chemin sur le tracé (pour y poser la bulle de durée).
  LatLng get midPoint {
    if (points.length < 3) return points.first;

    double between(LatLng a, LatLng b) {
      final dLat = (b.latitude - a.latitude) * 111320;
      final dLng = (b.longitude - a.longitude) * 111320 * 0.997;
      return (dLat * dLat + dLng * dLng);
    }

    var total = 0.0;
    final lengths = <double>[];
    for (var i = 1; i < points.length; i++) {
      final len = between(points[i - 1], points[i]);
      final root = math.sqrt(len);
      lengths.add(root);
      total += root;
    }

    var walked = 0.0;
    for (var i = 0; i < lengths.length; i++) {
      if (walked + lengths[i] >= total / 2) {
        final ratio = lengths[i] == 0 ? 0.0 : (total / 2 - walked) / lengths[i];
        final a = points[i];
        final b = points[i + 1];
        return LatLng(
          a.latitude + (b.latitude - a.latitude) * ratio,
          a.longitude + (b.longitude - a.longitude) * ratio,
        );
      }
      walked += lengths[i];
    }
    return points[points.length ~/ 2];
  }
}

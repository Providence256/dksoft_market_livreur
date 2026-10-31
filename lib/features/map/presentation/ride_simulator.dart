import 'dart:async';

import 'package:dksoft_market_livreur/features/map/presentation/map_stop.dart';
import 'package:dksoft_market_livreur/features/routing/data/routing_repository.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Outil de test (debug seulement) : le livreur « roule » le long de
/// l'itinéraire vers son prochain arrêt, une nouvelle position par seconde.
class RideSimulator {
  RideSimulator({
    required this.routing,
    required this.nextStop,
    required this.onMove,
    required this.onArrive,
    required this.onFinished,
  });

  final RoutingRepository routing;

  /// Prochain arrêt de la course, relu à chaque pas.
  final MapStop? Function() nextStop;
  final void Function(Position position) onMove;
  final void Function(MapStop stop) onArrive;

  /// Plus d'arrêt à atteindre : la simulation s'est arrêtée seule.
  final void Function() onFinished;

  static const _speed = 13.0; // m/s, environ 47 km/h

  Timer? _timer;
  Position? _position;
  List<LatLng> _path = const [];
  int _segment = 0;
  String? _pathFor;
  bool _fetching = false;

  bool get isRunning => _timer != null;

  /// Position simulée en cours (null quand la simulation est arrêtée).
  Position? get position => _position;

  void start(LatLng from) {
    _path = const [];
    _segment = 0;
    _pathFor = null;
    _position = _positionOf(from, 0);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _position = null;
  }

  Position _positionOf(LatLng point, double heading) => Position(
    longitude: point.longitude,
    latitude: point.latitude,
    timestamp: DateTime.now(),
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: heading,
    headingAccuracy: 0,
    speed: _speed,
    speedAccuracy: 0,
  );

  void _tick() {
    final current = _position;
    if (current == null) return;

    final stop = nextStop();
    final target = stop?.position;
    if (stop == null || target == null) {
      this.stop();
      onFinished();
      return;
    }

    final here = LatLng(current.latitude, current.longitude);
    final toTarget = _distance(here, target);

    // Déjà posé sur l'arrêt : le livreur attend qu'on valide.
    if (toTarget < 1) return;

    LatLng next;
    if (toTarget <= _speed * 3) {
      // Dernière ligne droite : on se gare pile sur l'arrêt (le tracé
      // routier s'arrête souvent à la rue, à quelques dizaines de mètres).
      next = target;
      onArrive(stop);
    } else {
      // Chemin propre à cette destination, suivi dans l'ordre : chercher
      // « le point le plus proche » faisait tourner en rond.
      final key = '${target.latitude},${target.longitude}';
      if (_pathFor != key) {
        if (!_fetching) _fetchPath(here, target, key);
        return;
      }
      next = _walk(here, target, _speed);
    }

    final heading = Geolocator.bearingBetween(
      here.latitude,
      here.longitude,
      next.latitude,
      next.longitude,
    );
    _position = _positionOf(next, heading < 0 ? heading + 360 : heading);
    onMove(_position!);
  }

  Future<void> _fetchPath(LatLng from, LatLng target, String key) async {
    _fetching = true;
    final route = await routing.route([from, target]);
    _fetching = false;
    if (!isRunning) return;
    _path = route?.points ?? const [];
    _segment = 0;
    _pathFor = key;
  }

  /// Avance de [meters] le long du chemin, puis tout droit vers l'arrêt
  /// quand le chemin est épuisé.
  LatLng _walk(LatLng from, LatLng target, double meters) {
    var current = from;
    var remaining = meters;

    while (remaining > 0 && _segment < _path.length) {
      final point = _path[_segment];
      final d = _distance(current, point);
      if (d <= remaining) {
        remaining -= d;
        current = point;
        _segment++;
      } else {
        return _stepToward(current, point, remaining);
      }
    }
    return remaining > 0 ? _stepToward(current, target, remaining) : current;
  }

  static LatLng _stepToward(LatLng from, LatLng target, double meters) {
    final distance = _distance(from, target);
    if (distance <= meters) return target;
    final t = meters / distance;
    return LatLng(
      from.latitude + (target.latitude - from.latitude) * t,
      from.longitude + (target.longitude - from.longitude) * t,
    );
  }

  static double _distance(LatLng a, LatLng b) => Geolocator.distanceBetween(
    a.latitude,
    a.longitude,
    b.latitude,
    b.longitude,
  );
}

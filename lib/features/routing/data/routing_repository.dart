import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dksoft_market_livreur/features/routing/domain/route_info.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Calcule l'itinéraire routier entre plusieurs points.
///
/// Service provisoire : le serveur public OSRM (données OpenStreetMap),
/// gratuit et sans clé, suffisant pour le développement. Pour la
/// production, on le remplacera par l'API Google Routes appelée depuis une
/// Cloud Function (clé gardée côté serveur) : seule cette classe change.
class RoutingRepository {
  static const _host = 'router.project-osrm.org';

  /// Renvoie null si le calcul échoue (hors connexion, serveur occupé…) :
  /// l'écran retombe alors sur un trait en pointillés.
  Future<RouteInfo?> route(List<LatLng> waypoints) async {
    if (waypoints.length < 2) return null;

    final coordinates = waypoints
        .map((p) => '${p.longitude},${p.latitude}')
        .join(';');
    final uri = Uri.https(_host, '/route/v1/driving/$coordinates', {
      'overview': 'full',
      'geometries': 'polyline',
      'steps': 'true',
    });

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 8)
      ..userAgent = 'DksoftMarketLivreur/1.0';

    try {
      final request = await client.getUrl(uri);
      final response = await request.close().timeout(
        const Duration(seconds: 12),
      );
      if (response.statusCode != 200) return null;

      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body);
      if (json is! Map || json['code'] != 'Ok') return null;

      final routes = json['routes'];
      if (routes is! List || routes.isEmpty) return null;
      final best = routes.first as Map;

      final legs = (best['legs'] as List? ?? const []).whereType<Map>();

      return RouteInfo(
        points: decodePolyline(best['geometry'] as String),
        distanceMeters: (best['distance'] as num).toDouble(),
        durationSeconds: (best['duration'] as num).toDouble(),
        legMeters: [for (final l in legs) (l['distance'] as num).toDouble()],
        legSeconds: [for (final l in legs) (l['duration'] as num).toDouble()],
        legSteps: [for (final l in legs) _parseSteps(l['steps'])],
      );
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  static List<RouteStep> _parseSteps(Object? raw) {
    if (raw is! List) return const [];
    final steps = <RouteStep>[];
    for (final item in raw.whereType<Map>()) {
      final maneuver = item['maneuver'];
      if (maneuver is! Map) continue;
      final location = maneuver['location'];
      if (location is! List || location.length < 2) continue;
      steps.add(
        RouteStep(
          type: maneuver['type']?.toString() ?? 'turn',
          modifier: maneuver['modifier']?.toString() ?? '',
          street: item['name']?.toString() ?? '',
          distanceMeters: (item['distance'] as num?)?.toDouble() ?? 0,
          location: LatLng(
            (location[1] as num).toDouble(),
            (location[0] as num).toDouble(),
          ),
        ),
      );
    }
    return steps;
  }

  /// Décode un tracé encodé au format « polyline » de Google (précision 5).
  static List<LatLng> decodePolyline(String encoded) {
    final points = <LatLng>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      var shift = 0;
      var result = 0;
      int byte;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lat += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);
      lng += (result & 1) != 0 ? ~(result >> 1) : (result >> 1);

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }
}

final routingRepositoryProvider = Provider<RoutingRepository>((ref) {
  return RoutingRepository();
});

/// Clé stable pour un trajet : le départ (position du motard) est arrondi
/// à ~100 m pour ne pas recalculer l'itinéraire à chaque petit déplacement.
String routeKey(List<LatLng> points, {bool roundFirst = false}) {
  return [
    for (final (i, p) in points.indexed)
      (roundFirst && i == 0)
          ? '${p.latitude.toStringAsFixed(3)},${p.longitude.toStringAsFixed(3)}'
          : '${p.latitude.toStringAsFixed(5)},${p.longitude.toStringAsFixed(5)}',
  ].join('|');
}

/// Itinéraire pour une clé donnée ([routeKey]). Gardé 5 minutes en mémoire :
/// revenir sur un écran ne relance pas le calcul.
final routeProvider = FutureProvider.autoDispose.family<RouteInfo?, String>((
  ref,
  key,
) async {
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 5), link.close);
  ref.onDispose(timer.cancel);

  final points = [
    for (final part in key.split('|'))
      LatLng(
        double.parse(part.split(',')[0]),
        double.parse(part.split(',')[1]),
      ),
  ];
  return ref.read(routingRepositoryProvider).route(points);
});

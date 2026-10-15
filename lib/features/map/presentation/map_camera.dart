import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Cadre la caméra sur un ensemble de points. Ne fait rien si la liste est
/// vide, et ignore l'erreur si la carte n'a pas encore sa taille finale.
Future<void> fitPoints(
  GoogleMapController? controller,
  List<LatLng> points, {
  double padding = 72,
}) async {
  if (controller == null || points.isEmpty) return;

  try {
    if (points.length == 1) {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(points.first, 16),
      );
      return;
    }

    var minLat = points.first.latitude;
    var maxLat = minLat;
    var minLng = points.first.longitude;
    var maxLng = minLng;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        padding,
      ),
    );
  } catch (_) {
    // Carte pas encore prête : le bouton « vue d'ensemble » permet de recadrer.
  }
}

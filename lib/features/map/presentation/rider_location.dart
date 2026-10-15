import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum RiderSource {
  /// Vraie position GPS du téléphone.
  real,

  /// Aucune position exploitable.
  none,
}

/// Position du livreur prête à afficher.
class RiderFix {
  const RiderFix(this.point, this.source, {this.farAway = false});

  final LatLng? point;
  final RiderSource source;

  /// Le GPS donne une position à plus de 100 km des arrêts (typiquement le
  /// simulateur iPhone, réglé sur la Californie) : elle n'est pas affichée,
  /// pour ne pas dézoomer la carte sur la planète entière.
  final bool farAway;
}

/// Position réelle du livreur, telle que donnée par le GPS du téléphone.
/// Aucune position n'est inventée.
RiderFix resolveRider(Position? raw, LatLng? anchor) {
  if (raw == null) return const RiderFix(null, RiderSource.none);

  final point = LatLng(raw.latitude, raw.longitude);
  final far =
      anchor != null &&
      Geolocator.distanceBetween(
            point.latitude,
            point.longitude,
            anchor.latitude,
            anchor.longitude,
          ) >=
          100000;
  if (far) return const RiderFix(null, RiderSource.none, farAway: true);
  return RiderFix(point, RiderSource.real);
}

/// Cap du GPS quand le livreur roule ; null à l'arrêt (le capteur donne alors
/// un cap sans valeur).
double? riderHeadingOf(Position? position) {
  if (position == null) return null;
  if (position.speed > 1.5 && position.heading >= 0) return position.heading;
  return null;
}

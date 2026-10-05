import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Ce que l'app peut faire avec la position du téléphone.
enum LocationAccess {
  granted,

  /// Permission refusée (on peut la redemander).
  denied,

  /// Refusée définitivement : seul l'écran Réglages du téléphone peut
  /// la rétablir.
  deniedForever,

  /// Le GPS / la localisation est coupé sur le téléphone.
  serviceDisabled,
}

class LocationRepository {
  /// Vérifie l'accès à la position. Avec [request], affiche la fenêtre
  /// d'autorisation du système si la permission n'a pas encore été
  /// décidée.
  Future<LocationAccess> check({bool request = false}) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAccess.serviceDisabled;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && request) {
      permission = await Geolocator.requestPermission();
    }

    return switch (permission) {
      LocationPermission.whileInUse ||
      LocationPermission.always => LocationAccess.granted,
      LocationPermission.deniedForever => LocationAccess.deniedForever,
      _ => LocationAccess.denied,
    };
  }

  /// Dernière position connue : instantanée, pour ne pas attendre le
  /// premier relevé GPS.
  Future<Position?> lastKnown() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  /// Position en direct, app ouverte. `distanceFilter` : pas de nouvelle
  /// position tant que le motard n'a pas bougé de 10 m (économise la
  /// batterie et les rafraîchissements de l'écran).
  Stream<Position> watchPosition() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    );
  }

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();
}

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository();
});

class LocationAccessNotifier extends AsyncNotifier<LocationAccess> {
  @override
  Future<LocationAccess> build() {
    // Ouvrir la carte est le bon moment pour demander l'autorisation.
    return ref.read(locationRepositoryProvider).check(request: true);
  }

  /// À rappeler quand le motard revient des Réglages, ou pour redemander.
  Future<void> recheck({bool request = true}) async {
    final repository = ref.read(locationRepositoryProvider);
    final access = await repository.check(request: request);
    if (!ref.mounted) return;
    state = AsyncData(access);
  }
}

final locationAccessProvider =
    AsyncNotifierProvider.autoDispose<LocationAccessNotifier, LocationAccess>(
      LocationAccessNotifier.new,
    );

/// Position du motard en direct. Vide tant que la localisation n'est pas
/// autorisée.
final riderPositionProvider = StreamProvider.autoDispose<Position>((
  ref,
) async* {
  final access = await ref.watch(locationAccessProvider.future);
  if (access != LocationAccess.granted) return;

  final repository = ref.read(locationRepositoryProvider);

  final last = await repository.lastKnown();
  if (last != null) yield last;

  yield* repository.watchPosition();
});

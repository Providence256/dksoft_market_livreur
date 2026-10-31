import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dksoft_market_livreur/core/data/livreur_repository.dart';
import 'package:dksoft_market_livreur/features/deliveries/data/deliveries_repository.dart';
import 'package:dksoft_market_livreur/features/map/data/location_repository.dart';
import 'package:dksoft_market_livreur/features/settings/data/preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Partage la position du motard sur sa course en cours
/// (`deliveries/{id}.livreurLocation`) : le dealer et l'administration le
/// suivent en direct. Seulement app ouverte (pas de suivi en arrière-plan).
class LiveTrackingRepository {
  LiveTrackingRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Future<void> publish(String deliveryId, Position position) {
    return _firestore
        .collection(DeliveriesRepository.deliveriesPath)
        .doc(deliveryId)
        .update({
          'livreurLocation': {
            'position': GeoPoint(position.latitude, position.longitude),
            'heading': position.heading >= 0 ? position.heading : null,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        });
  }
}

final liveTrackingRepositoryProvider = Provider<LiveTrackingRepository>((ref) {
  return LiveTrackingRepository(FirebaseFirestore.instance);
});

/// Pas plus d'un envoi toutes les [_minInterval], et seulement si le
/// motard a bougé de [_minDistance] — sauf au bout de [_heartbeat], pour
/// que le suivi sache qu'il est toujours là. Ménage batterie et données.
const _minInterval = Duration(seconds: 10);
const _minDistance = 25.0;
const _heartbeat = Duration(seconds: 60);

/// Actif tant qu'une course est en cours : à observer depuis l'écran
/// principal (`ref.watch(liveTrackingProvider)`).
final liveTrackingProvider = Provider.autoDispose<void>((ref) {
  final deliveryId = ref.watch(
    currentLivreurProvider.select((value) => value.value?.activeDeliveryId),
  );
  // Le motard peut couper le partage dans les Paramètres.
  final enabled = ref.watch(liveTrackingEnabledProvider);
  if (deliveryId == null || !enabled) return;

  final repository = ref.read(liveTrackingRepositoryProvider);
  Position? lastSent;
  DateTime? lastSentAt;

  ref.listen<AsyncValue<Position>>(riderPositionProvider, (_, next) {
    final position = next.value;
    if (position == null) return;

    final now = DateTime.now();
    final previous = lastSent;
    final elapsed = lastSentAt == null
        ? _heartbeat
        : now.difference(lastSentAt!);
    final moved = previous == null
        ? double.infinity
        : Geolocator.distanceBetween(
            previous.latitude,
            previous.longitude,
            position.latitude,
            position.longitude,
          );

    if (elapsed < _minInterval) return;
    if (moved < _minDistance && elapsed < _heartbeat) return;

    lastSent = position;
    lastSentAt = now;
    // Hors connexion ou course terminée entre-temps : la prochaine
    // position réessaiera, rien à signaler au motard.
    repository.publish(deliveryId, position).catchError((Object _) {});
  }, fireImmediately: true);
});

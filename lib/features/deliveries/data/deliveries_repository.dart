import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dksoft_market_livreur/core/data/livreur_repository.dart';
import 'package:dksoft_market_livreur/core/domain/livreur_model.dart';
import 'package:dksoft_market_livreur/features/authentication/data/auth_repository.dart';
import 'package:dksoft_market_livreur/features/deliveries/domain/delivery_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Erreur métier avec un message prêt à afficher au motard.
class DeliveryException implements Exception {
  const DeliveryException(this.message);
  final String message;

  @override
  String toString() => message;
}

class DeliveriesRepository {
  DeliveriesRepository(this._firestore);

  final FirebaseFirestore _firestore;

  static const deliveriesPath = 'deliveries';

  DocumentReference<Map<String, dynamic>> _deliveryDoc(String id) =>
      _firestore.collection(deliveriesPath).doc(id);

  /// Courses que ce motard peut prendre, en temps réel, sans celles qu'il
  /// a déjà refusées.
  ///
  /// Le tri se fait côté app (les plus récentes d'abord) pour éviter un
  /// index composite Firestore à créer à la main.
  Stream<List<DeliveryModel>> watchAvailableDeliveries(String uid) {
    return _firestore
        .collection(deliveriesPath)
        .where('status', isEqualTo: DeliveryStatus.pendingAssignment.name)
        .snapshots()
        .map((snapshot) {
          final deliveries = snapshot.docs
              .map(DeliveryModel.fromSnapshot)
              .where((delivery) => !delivery.refusedBy.contains(uid))
              .toList();

          final now = DateTime.now();
          deliveries.sort(
            (a, b) => (b.createdAt ?? now).compareTo(a.createdAt ?? now),
          );
          return deliveries;
        });
  }

  /// Toutes les courses de ce motard (en cours et terminées), en temps
  /// réel. Sert à l'historique et aux gains de la semaine.
  Stream<List<DeliveryModel>> watchMyDeliveries(String uid) {
    return _firestore
        .collection(deliveriesPath)
        .where('livreurId', isEqualTo: uid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(DeliveryModel.fromSnapshot).toList(),
        );
  }

  Stream<DeliveryModel?> watchDelivery(String id) {
    return _deliveryDoc(id).snapshots().map(
      (doc) => doc.exists ? DeliveryModel.fromSnapshot(doc) : null,
    );
  }

  /// Le motard prend la course : premier arrivé, premier servi.
  ///
  /// Tout se passe dans une transaction : Firestore la rejoue si deux
  /// motards acceptent en même temps, et le second voit alors la course
  /// déjà affectée et reçoit une [DeliveryException]. Elle vérifie aussi
  /// que le motard est validé, disponible et sans autre course en cours.
  Future<void> acceptDelivery({
    required String deliveryId,
    required String uid,
  }) {
    final deliveryRef = _deliveryDoc(deliveryId);
    final livreurRef = _firestore
        .collection(AuthRepository.livreursPath)
        .doc(uid);

    return _firestore.runTransaction((transaction) async {
      final deliverySnap = await transaction.get(deliveryRef);
      final livreurSnap = await transaction.get(livreurRef);

      if (!deliverySnap.exists) {
        throw const DeliveryException("Cette course n'existe plus.");
      }

      final delivery = DeliveryModel.fromSnapshot(deliverySnap);
      final livreur = LivreurModel.fromSnapshot(livreurSnap);

      if (delivery.status != DeliveryStatus.pendingAssignment ||
          delivery.livreurId != null) {
        throw const DeliveryException(
          "Cette course vient d'être prise par un autre motard.",
        );
      }
      if (!livreurSnap.exists || livreur.status != LivreurStatus.valide) {
        throw const DeliveryException("Votre compte n'est pas validé.");
      }
      if (!livreur.disponible) {
        throw const DeliveryException(
          'Passez disponible pour prendre une course.',
        );
      }
      if (livreur.activeDeliveryId != null) {
        throw const DeliveryException(
          "Terminez votre course en cours avant d'en prendre une autre.",
        );
      }

      transaction.update(deliveryRef, {
        'status': DeliveryStatus.assigned.name,
        'livreurId': uid,
        'livreurName': livreur.fullName,
        'livreurPhone': livreur.phone,
        'assignedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(livreurRef, {'activeDeliveryId': deliveryId});
    }, timeout: const Duration(seconds: 10));
  }

  /// Le motard a récupéré (ou ne peut pas récupérer) l'article d'un
  /// commerçant. Quand tous les arrêts sont traités, la course passe à
  /// « en route vers le dealer ».
  Future<void> markPickup({
    required String deliveryId,
    required String uid,
    required int index,
    required PickupStatus status,
  }) {
    final ref = _deliveryDoc(deliveryId);

    return _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(ref);
      if (!snap.exists) {
        throw const DeliveryException("Cette course n'existe plus.");
      }

      final delivery = DeliveryModel.fromSnapshot(snap);
      if (delivery.livreurId != uid) {
        throw const DeliveryException("Cette course ne vous est pas affectée.");
      }
      if (index < 0 || index >= delivery.pickups.length) {
        throw const DeliveryException('Arrêt introuvable.');
      }

      final now = Timestamp.now();
      final pickups = <Map<String, dynamic>>[
        for (final (i, stop) in delivery.pickups.indexed)
          if (i == index)
            {...stop.toMap(), 'status': status.name, 'collectedAt': now}
          else
            stop.toMap(),
      ];
      final allDone = delivery.pickups.indexed.every(
        (entry) => entry.$1 == index || entry.$2.status != PickupStatus.pending,
      );

      transaction.update(ref, {
        'pickups': pickups,
        'status': allDone
            ? DeliveryStatus.enRoute.name
            : DeliveryStatus.collecting.name,
      });
    }, timeout: const Duration(seconds: 10));
  }

  /// Le colis est remis au dealer : la course est terminée et le motard
  /// redevient libre. Les gains sont crédités côté serveur.
  Future<void> completeDelivery({
    required String deliveryId,
    required String uid,
  }) {
    final ref = _deliveryDoc(deliveryId);
    final livreurRef = _firestore
        .collection(AuthRepository.livreursPath)
        .doc(uid);

    return _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(ref);
      if (!snap.exists) {
        throw const DeliveryException("Cette course n'existe plus.");
      }

      final delivery = DeliveryModel.fromSnapshot(snap);
      if (delivery.livreurId != uid) {
        throw const DeliveryException("Cette course ne vous est pas affectée.");
      }
      if (delivery.nextPickupIndex != null) {
        throw const DeliveryException(
          "Passez d'abord chez tous les commerçants.",
        );
      }

      transaction.update(ref, {
        'status': DeliveryStatus.delivered.name,
        'deliveredAt': FieldValue.serverTimestamp(),
      });
      transaction.update(livreurRef, {'activeDeliveryId': null});
    }, timeout: const Duration(seconds: 10));
  }

  /// Le motard refuse : la course ne lui est plus proposée mais reste
  /// disponible pour les autres.
  ///
  /// Un simple `update` suffit (pas de transaction) : ce n'est pas
  /// critique, et Firestore l'applique tout de suite en local, donc la
  /// course disparaît de la liste même sans réseau.
  Future<void> refuseDelivery({
    required String deliveryId,
    required String uid,
  }) {
    return _deliveryDoc(deliveryId).update({
      'refusedBy': FieldValue.arrayUnion([uid]),
    });
  }
}

final deliveriesRepositoryProvider = Provider<DeliveriesRepository>((ref) {
  return DeliveriesRepository(FirebaseFirestore.instance);
});

/// Courses proposées au motard connecté.
///
/// Vide si le motard est indisponible ou a déjà une course en cours (une
/// seule à la fois) : on ne s'abonne même pas au flux dans ces cas.
/// `select` évite de se réabonner à chaque modification sans rapport du
/// profil (gains, note…).
final availableDeliveriesProvider =
    StreamProvider.autoDispose<List<DeliveryModel>>((ref) {
      final disponible = ref.watch(
        currentLivreurProvider.select((value) => value.value?.disponible),
      );
      final hasActiveDelivery = ref.watch(
        currentLivreurProvider.select(
          (value) => value.value?.activeDeliveryId != null,
        ),
      );
      final uid = ref.watch(authStateChangesProvider).value?.uid;

      if (uid == null || disponible != true || hasActiveDelivery) {
        return Stream.value(const []);
      }

      return ref
          .watch(deliveriesRepositoryProvider)
          .watchAvailableDeliveries(uid);
    });

/// Historique du motard connecté : toutes ses courses.
final myDeliveriesProvider = StreamProvider.autoDispose<List<DeliveryModel>>((
  ref,
) {
  final uid = ref.watch(authStateChangesProvider).value?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(deliveriesRepositoryProvider).watchMyDeliveries(uid);
});

/// Une course précise, en temps réel (détail, course en cours).
final deliveryByIdProvider = StreamProvider.autoDispose
    .family<DeliveryModel?, String>((ref, id) {
      return ref.watch(deliveriesRepositoryProvider).watchDelivery(id);
    });

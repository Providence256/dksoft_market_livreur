import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dksoft_market_livreur/core/domain/livreur_model.dart';
import 'package:dksoft_market_livreur/features/authentication/data/auth_repository.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LivreurRepository {
  LivreurRepository(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection(AuthRepository.livreursPath).doc(uid);

  /// Profil du motard en temps réel : dès que l'administration passe le
  /// statut à `valide`, l'app réagit sans redémarrage.
  Stream<LivreurModel?> watchLivreur(String uid) {
    return _doc(uid).snapshots().map(
      (doc) => doc.exists ? LivreurModel.fromSnapshot(doc) : null,
    );
  }

  /// Envoie la photo de la pièce d'identité et enregistre son chemin
  /// Storage sur le profil. Une nouvelle photo remplace l'ancienne.
  Future<void> uploadIdentityPhoto({
    required String uid,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) async {
    final path = 'livreurs/$uid/identity';
    await _storage
        .ref(path)
        .putData(bytes, SettableMetadata(contentType: contentType));

    await _doc(uid).update({
      'idPhotoPath': path,
      'idPhotoUploadedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Met le motard disponible / indisponible.
  ///
  /// Volontairement dans une transaction : contrairement à un simple
  /// `update`, elle échoue hors connexion au lieu d'être mise en file
  /// d'attente. Sans ça, avec une connexion instable (§17), l'écran
  /// afficherait « disponible » alors que le serveur dit encore
  /// « indisponible » (ou l'inverse), et le motard raterait des courses
  /// sans le savoir.
  Future<void> setDisponible(String uid, bool disponible) {
    return _firestore.runTransaction((transaction) async {
      transaction.update(_doc(uid), {
        'disponible': disponible,
        'disponibleUpdatedAt': FieldValue.serverTimestamp(),
      });
    }, timeout: const Duration(seconds: 10));
  }

  Future<Uint8List?> readIdentityPhoto(String path) {
    return _storage.ref(path).getData(5 * 1024 * 1024);
  }
}

final livreurRepositoryProvider = Provider<LivreurRepository>((ref) {
  return LivreurRepository(
    FirebaseFirestore.instance,
    FirebaseStorage.instance,
  );
});

/// Profil du motard connecté (null s'il n'existe pas ou hors connexion).
final currentLivreurProvider = StreamProvider.autoDispose<LivreurModel?>((ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value(null);
  return ref.watch(livreurRepositoryProvider).watchLivreur(user.uid);
});

/// Octets de la photo d'identité, lus à la demande (pas d'URL publique).
final identityPhotoProvider = FutureProvider.autoDispose
    .family<Uint8List?, String>((ref, path) {
      return ref.watch(livreurRepositoryProvider).readIdentityPhoto(path);
    });

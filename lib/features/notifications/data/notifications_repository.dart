import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dksoft_market_livreur/features/authentication/data/auth_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifications push (FCM).
///
/// Le backend prévient les motards disponibles de chaque nouvelle course
/// en lisant `livreurs/{uid}.fcmToken` : cette classe tient ce token à jour.
class NotificationsRepository {
  NotificationsRepository(this._messaging, this._firestore);

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection(AuthRepository.livreursPath).doc(uid);

  /// Demande l'autorisation, puis enregistre le token de l'appareil.
  /// Ne lève jamais : sans notifications, l'app reste utilisable.
  Future<void> registerDevice(String uid) async {
    try {
      final settings = await _messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      // iOS : FCM a besoin du token APNs, absent tant que la capacité
      // « Push Notifications » n'est pas configurée (et sur simulateur).
      if (defaultTargetPlatform == TargetPlatform.iOS &&
          await _messaging.getAPNSToken() == null) {
        return;
      }

      final token = await _messaging.getToken();
      if (token != null) await saveToken(uid, token);
    } catch (error) {
      debugPrint('Notifications : enregistrement impossible ($error)');
    }
  }

  Future<void> saveToken(String uid, String token) =>
      _doc(uid).update({'fcmToken': token});

  /// Le motard coupe les notifications : le token est retiré de son
  /// profil (le backend ne lui écrit plus) et supprimé de l'appareil.
  Future<void> unregisterDevice(String uid) async {
    try {
      await _doc(uid)
          .update({'fcmToken': FieldValue.delete()})
          .timeout(const Duration(seconds: 5));
      await _messaging.deleteToken();
    } catch (error) {
      debugPrint('Notifications : désinscription incomplète ($error)');
    }
  }

  /// Nouveau token émis par FCM (réinstallation, rotation…).
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((
  ref,
) {
  return NotificationsRepository(
    FirebaseMessaging.instance,
    FirebaseFirestore.instance,
  );
});

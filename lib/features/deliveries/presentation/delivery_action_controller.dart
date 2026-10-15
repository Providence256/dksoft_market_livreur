import 'package:dksoft_market_livreur/features/authentication/data/auth_repository.dart';
import 'package:dksoft_market_livreur/features/deliveries/data/deliveries_repository.dart';
import 'package:dksoft_market_livreur/features/deliveries/domain/delivery_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeliveryActionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  String? get _uid => ref.read(authRepositoryProvider).currentUser?.uid;

  /// Renvoie true si la course a bien été affectée à ce motard.
  Future<bool> accept(String deliveryId) async {
    final uid = _uid;
    if (uid == null) return false;

    state = const AsyncLoading();

    try {
      await ref
          .read(deliveriesRepositoryProvider)
          .acceptDelivery(deliveryId: deliveryId, uid: uid);
      if (!ref.mounted) return true;
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      if (!ref.mounted) return false;
      state = AsyncError(
        error is DeliveryException
            ? error.message
            : "Impossible de prendre la course. Vérifiez votre connexion "
                  'et réessayez.',
        stackTrace,
      );
      return false;
    }
  }

  String _messageOf(Object error) => error is DeliveryException
      ? error.message
      : 'Action impossible. Vérifiez votre connexion et réessayez.';

  /// Arrêt traité chez un commerçant. Renvoie true si c'est enregistré.
  Future<bool> markPickup(
    String deliveryId,
    int index, {
    PickupStatus status = PickupStatus.collected,
  }) async {
    final uid = _uid;
    if (uid == null) return false;

    state = const AsyncLoading();
    try {
      await ref
          .read(deliveriesRepositoryProvider)
          .markPickup(
            deliveryId: deliveryId,
            uid: uid,
            index: index,
            status: status,
          );
      if (!ref.mounted) return true;
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      if (!ref.mounted) return false;
      state = AsyncError(_messageOf(error), stackTrace);
      return false;
    }
  }

  /// Colis remis au dealer. Renvoie true si la course est terminée.
  Future<bool> complete(String deliveryId) async {
    final uid = _uid;
    if (uid == null) return false;

    state = const AsyncLoading();
    try {
      await ref
          .read(deliveriesRepositoryProvider)
          .completeDelivery(deliveryId: deliveryId, uid: uid);
      if (!ref.mounted) return true;
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      if (!ref.mounted) return false;
      state = AsyncError(_messageOf(error), stackTrace);
      return false;
    }
  }

  /// Volontairement sans `await` : hors connexion, Firestore mettrait
  /// l'écriture en file d'attente et l'appel ne reviendrait jamais.
  /// La course disparaît de la liste immédiatement (cache local).
  void refuse(String deliveryId) {
    final uid = _uid;
    if (uid == null) return;

    ref
        .read(deliveriesRepositoryProvider)
        .refuseDelivery(deliveryId: deliveryId, uid: uid)
        .catchError((Object _) {});
  }
}

final deliveryActionControllerProvider =
    AsyncNotifierProvider.autoDispose<DeliveryActionController, void>(
      DeliveryActionController.new,
    );

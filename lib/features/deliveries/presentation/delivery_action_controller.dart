import 'package:dksoft_market_livreur/features/authentication/data/auth_repository.dart';
import 'package:dksoft_market_livreur/features/deliveries/data/deliveries_repository.dart';
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

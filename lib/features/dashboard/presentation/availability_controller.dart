import 'package:dksoft_market_livreur/core/data/livreur_repository.dart';
import 'package:dksoft_market_livreur/features/authentication/data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AvailabilityController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Renvoie true si le serveur a bien enregistré le changement.
  Future<bool> setDisponible(bool value) async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) return false;

    state = const AsyncLoading();

    try {
      await ref.read(livreurRepositoryProvider).setDisponible(uid, value);
      if (!ref.mounted) return true;
      state = const AsyncData(null);
      return true;
    } catch (_, stackTrace) {
      if (!ref.mounted) return false;
      state = AsyncError(
        'Impossible de changer votre disponibilité. Vérifiez votre '
        'connexion internet et réessayez.',
        stackTrace,
      );
      return false;
    }
  }
}

final availabilityControllerProvider =
    AsyncNotifierProvider.autoDispose<AvailabilityController, void>(
      AvailabilityController.new,
    );

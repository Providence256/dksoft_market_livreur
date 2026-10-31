import 'package:dksoft_market_livreur/features/earnings/data/payouts_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PayoutController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Renvoie true si la demande est enregistrée.
  Future<bool> request({
    required double amount,
    required String method,
    String? phone,
  }) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(payoutsRepositoryProvider)
          .requestPayout(amount: amount, method: method, phone: phone);
      if (!ref.mounted) return true;
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      if (!ref.mounted) return false;
      state = AsyncError(
        error is String
            ? error
            : "La demande n'a pas pu être envoyée. Vérifiez votre connexion.",
        stackTrace,
      );
      return false;
    }
  }
}

final payoutControllerProvider =
    AsyncNotifierProvider.autoDispose<PayoutController, void>(
      PayoutController.new,
    );

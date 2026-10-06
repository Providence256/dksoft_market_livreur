import 'package:dksoft_market_livreur/features/authentication/data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  /// Cette app est réservée aux motards : un compte sans le claim
  /// `livreur` (client ou dealer) est déconnecté aussitôt, avec un
  /// message clair.
  ///
  /// Un seul essai pour le claim : un compte existant l'a déjà. Les
  /// réessais ne servent que juste après une inscription.
  Future<bool> signIn({required String phone, required String password}) async {
    state = const AsyncLoading();

    try {
      await _repository.signInWithPhoneAndPassword(
        phone: phone,
        password: password,
      );

      final isLivreur = await _repository.currentUserIsLivreur(maxAttempts: 1);
      if (!isLivreur) {
        await _repository.signOut();
        if (!ref.mounted) return false;
        state = AsyncError(
          "Ce compte n'est pas un compte motard. Utilisez l'application "
          'correspondant à votre profil.',
          StackTrace.current,
        );
        return false;
      }

      if (!ref.mounted) return true;
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      if (!ref.mounted) return false;
      state = AsyncError(_repository.mapAuthError(error), stackTrace);
      return false;
    }
  }

  Future<bool> signUp({
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
    required String idCountry,
    required String idType,
    required String idNumber,
    required DateTime idIssueDate,
    required String motoMake,
    required String motoModel,
    required String motoColor,
    required int motoYear,
    String? plaque,
  }) async {
    state = const AsyncLoading();

    try {
      await _repository.signUp(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        password: password,
        idCountry: idCountry,
        idType: idType,
        idNumber: idNumber,
        idIssueDate: idIssueDate,
        motoMake: motoMake,
        motoModel: motoModel,
        motoColor: motoColor,
        motoYear: motoYear,
        plaque: plaque,
      );
      if (!ref.mounted) return false;
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      if (!ref.mounted) return false;
      state = AsyncError(_repository.mapAuthError(error), stackTrace);
      return false;
    }
  }
}

final authControllerProvider =
    AsyncNotifierProvider.autoDispose<AuthController, void>(AuthController.new);

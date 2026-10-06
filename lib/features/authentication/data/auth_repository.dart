import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dksoft_market_livreur/core/domain/livreur_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthRepository {
  AuthRepository(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const usersPath = 'users';
  static const livreursPath = 'livreurs';

  /// Affiché quand le numéro est déjà inscrit. L'assistant d'inscription
  /// s'en sert pour ramener l'utilisateur à l'étape du téléphone.
  static const phoneInUseMessage =
      'Un compte existe déjà avec ce numéro de téléphone.';

  /// Doit rester identique à LIVREUR_EMAIL_DOMAIN dans
  /// functions/src/index.ts : c'est ce domaine qui permet à la Cloud
  /// Function de poser le claim `role: livreur`.
  static const _pseudoEmailDomain = '@dksoft-market-livreur.app';

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  String _pseudoEmailFor(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return '$digits$_pseudoEmailDomain';
  }

  Future<void> signInWithPhoneAndPassword({
    required String phone,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: _pseudoEmailFor(phone),
      password: password,
    );
  }

  /// Crée le compte Auth puis les documents `users/{uid}` et
  /// `livreurs/{uid}`. Le motard démarre en statut `pending` : il ne
  /// recevra aucune course tant que l'administration ne l'a pas validé.
  ///
  /// Si l'écriture Firestore échoue, le compte Auth tout juste créé est
  /// supprimé pour ne pas laisser un compte à moitié inscrit (le numéro
  /// resterait « déjà utilisé » sans profil).
  Future<void> signUp({
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
    final fullName = '$firstName $lastName'.trim();

    final credential = await _auth.createUserWithEmailAndPassword(
      email: _pseudoEmailFor(phone),
      password: password,
    );

    final user = credential.user;
    if (user == null) return;

    try {
      await user.updateDisplayName(fullName);

      final livreur = LivreurModel(
        id: user.uid,
        fullName: fullName,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        motoType: '$motoMake $motoModel',
        motoMake: motoMake,
        motoModel: motoModel,
        motoColor: motoColor,
        motoYear: motoYear,
        plaque: plaque,
        idCountry: idCountry,
        idType: idType,
        idNumber: idNumber,
        idIssueDate: idIssueDate,
      );

      final batch = _firestore.batch();

      batch.set(_firestore.collection(usersPath).doc(user.uid), {
        'fullName': fullName,
        'phone': phone,
        'role': 'livreur',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      batch.set(_firestore.collection(livreursPath).doc(user.uid), {
        ...livreur.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (_) {
      await user.delete();
      rethrow;
    }
  }

  /// Source de vérité pour « est-ce un compte motard » : le claim `role`
  /// posé par la Cloud Function setLivreurRoleClaim.
  ///
  /// La fonction s'exécute de façon asynchrone après la création du
  /// compte, donc juste après l'inscription le claim peut manquer
  /// quelques secondes. [maxAttempts] permet de réessayer en forçant un
  /// nouveau jeton à chaque fois (même logique que l'app dealer).
  Future<bool> currentUserIsLivreur({
    int maxAttempts = 6,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final tokenResult = await user.getIdTokenResult(true);
      if (tokenResult.claims?['role'] == 'livreur') return true;

      final isLastAttempt = attempt == maxAttempts - 1;
      if (!isLastAttempt) await Future.delayed(retryDelay);
    }
    return false;
  }

  Future<void> signOut() => _auth.signOut();

  String mapAuthError(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
        case 'invalid-credential':
        case 'wrong-password':
          return 'Numéro de téléphone ou mot de passe incorrect.';
        case 'email-already-in-use':
          return phoneInUseMessage;
        case 'weak-password':
          return 'Le mot de passe doit contenir au moins 6 caractères.';
        case 'too-many-requests':
          return 'Trop de tentatives. Réessayez dans quelques minutes.';
        case 'network-request-failed':
          return 'Vérifiez votre connexion internet et réessayez.';
      }
    }
    return 'Une erreur est survenue. Réessayez.';
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(FirebaseAuth.instance, FirebaseFirestore.instance);
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

import 'package:dksoft_market_livreur/features/authentication/data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Vrai si le compte connecté porte le claim `livreur` posé par la
/// Cloud Function setLivreurRoleClaim (faux hors connexion). Réessaie
/// quelques secondes : juste après l'inscription, le claim peut ne pas
/// être encore posé.
final currentUserIsLivreurProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  final user = await ref.watch(authStateChangesProvider.future);
  if (user == null) return false;
  return ref.watch(authRepositoryProvider).currentUserIsLivreur();
});

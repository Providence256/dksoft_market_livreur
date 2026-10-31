import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dksoft_market_livreur/features/authentication/data/auth_repository.dart';
import 'package:dksoft_market_livreur/features/earnings/domain/payout_request.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Retraits des gains. Les demandes sont créées par le backend
/// (`requestLivreurPayout`), qui réserve le montant sur le solde ; l'app ne
/// fait que les demander et les afficher.
class PayoutsRepository {
  PayoutsRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  /// Lève un message prêt à afficher si la demande est refusée.
  Future<void> requestPayout({
    required double amount,
    required String method,
    String? phone,
  }) async {
    try {
      await _functions.httpsCallable('requestLivreurPayout').call({
        'amount': amount,
        'method': method,
        'phone': ?phone,
      });
    } on FirebaseFunctionsException catch (error) {
      throw error.message ?? "La demande n'a pas pu être envoyée.";
    }
  }

  Stream<List<PayoutRequest>> watchRequests(String uid) {
    return _firestore
        .collection(AuthRepository.livreursPath)
        .doc(uid)
        .collection('payoutRequests')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PayoutRequest.fromDoc(doc.id, doc.data()))
              .toList(),
        );
  }
}

final payoutsRepositoryProvider = Provider<PayoutsRepository>((ref) {
  return PayoutsRepository(
    FirebaseFirestore.instance,
    FirebaseFunctions.instance,
  );
});

/// Dernières demandes de retrait du motard connecté.
final payoutRequestsProvider = StreamProvider.autoDispose<List<PayoutRequest>>((
  ref,
) {
  final uid = ref.watch(authStateChangesProvider).value?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(payoutsRepositoryProvider).watchRequests(uid);
});

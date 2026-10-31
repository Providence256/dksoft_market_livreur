import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dksoft_market_livreur/features/authentication/data/auth_repository.dart';
import 'package:dksoft_market_livreur/features/reviews/domain/livreur_review.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReviewsRepository {
  ReviewsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  /// Les avis les plus récents du motard, en temps réel.
  Stream<List<LivreurReview>> watchReviews(String uid) {
    return _firestore
        .collection(AuthRepository.livreursPath)
        .doc(uid)
        .collection('ratings')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LivreurReview.fromDoc(doc.id, doc.data()))
              .toList(),
        );
  }

  /// Nom affiché du dealer, depuis son profil public.
  Future<String?> dealerName(String dealerId) async {
    if (dealerId.isEmpty) return null;
    final doc = await _firestore.doc('dealerProfiles/$dealerId').get();
    final name = (doc.data()?['fullName'] as String?)?.trim();
    return name == null || name.isEmpty ? null : name;
  }
}

final reviewsRepositoryProvider = Provider<ReviewsRepository>((ref) {
  return ReviewsRepository(FirebaseFirestore.instance);
});

final myReviewsProvider = StreamProvider.autoDispose<List<LivreurReview>>((
  ref,
) {
  final uid = ref.watch(authStateChangesProvider).value?.uid;
  if (uid == null) return Stream.value(const []);
  return ref.watch(reviewsRepositoryProvider).watchReviews(uid);
});

/// Nom du dealer, gardé en mémoire pendant la session.
final dealerNameProvider = FutureProvider.family<String?, String>((
  ref,
  dealerId,
) {
  return ref.watch(reviewsRepositoryProvider).dealerName(dealerId);
});

import 'package:cloud_firestore/cloud_firestore.dart';

/// Avis laissé par un dealer après une course livrée
/// (`livreurs/{uid}/ratings/{deliveryId}`).
class LivreurReview {
  const LivreurReview({
    required this.deliveryId,
    required this.dealerId,
    required this.rating,
    this.comment = '',
    this.createdAt,
  });

  final String deliveryId;
  final String dealerId;

  /// De 1 à 5 étoiles.
  final int rating;
  final String comment;
  final DateTime? createdAt;

  factory LivreurReview.fromDoc(String id, Map<String, dynamic> data) {
    return LivreurReview(
      deliveryId: id,
      dealerId: data['dealerId'] as String? ?? '',
      rating: ((data['rating'] as num?)?.toInt() ?? 0).clamp(0, 5),
      comment: (data['comment'] as String? ?? '').trim(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// Résumé des avis : moyenne et répartition par nombre d'étoiles.
class ReviewsSummary {
  const ReviewsSummary(this.reviews);

  final List<LivreurReview> reviews;

  int get count => reviews.length;

  double get average => reviews.isEmpty
      ? 0
      : reviews.fold<int>(0, (total, r) => total + r.rating) / reviews.length;

  /// Nombre d'avis pour [stars] étoiles.
  int countFor(int stars) => reviews.where((r) => r.rating == stars).length;
}

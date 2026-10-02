import 'package:cloud_firestore/cloud_firestore.dart';

/// Statut de validation du motard (§6.4 : un motard doit être validé par
/// l'administration avant de recevoir des livraisons).
enum LivreurStatus { pending, valide, suspendu }

extension LivreurStatusX on LivreurStatus {
  static LivreurStatus fromString(String? value) {
    return LivreurStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => LivreurStatus.pending,
    );
  }

  String get label => switch (this) {
    LivreurStatus.pending => 'En attente de validation',
    LivreurStatus.valide => 'Validé',
    LivreurStatus.suspendu => 'Suspendu',
  };
}

/// Document `livreurs/{uid}` — profil du motard (§13, « Compte motard »).
class LivreurModel {
  const LivreurModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.commune,
    required this.motoType,
    required this.idType,
    required this.idNumber,
    this.email,
    this.plaque,
    this.idPhotoPath,
    this.status = LivreurStatus.pending,
    this.disponible = false,
    this.rating = 0,
    this.livraisonsEffectuees = 0,
    this.gains = 0,
    this.activeDeliveryId,
  });

  final String id;
  final String fullName;
  final String phone;
  final String? email;
  final String commune;
  final String motoType;
  final String? plaque;
  final String idType;
  final String idNumber;

  /// Chemin Storage de la photo de la pièce d'identité (et non une URL
  /// publique : c'est un document sensible, seul l'admin doit le lire).
  final String? idPhotoPath;
  final LivreurStatus status;
  final bool disponible;
  final double rating;
  final int livraisonsEffectuees;
  final double gains;

  /// Course en cours (une seule à la fois). Posée à l'acceptation, retirée
  /// à la fin de la livraison.
  final String? activeDeliveryId;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'fullName': fullName,
      'phone': phone,
      'email': email,
      'commune': commune,
      'motoType': motoType,
      'plaque': plaque,
      'idType': idType,
      'idNumber': idNumber,
      'idPhotoPath': idPhotoPath,
      'status': status.name,
      'disponible': disponible,
      'rating': rating,
      'livraisonsEffectuees': livraisonsEffectuees,
      'gains': gains,
      'activeDeliveryId': activeDeliveryId,
    };
  }

  factory LivreurModel.fromMap(Map<String, dynamic> map) {
    return LivreurModel(
      id: map['id']?.toString() ?? '',
      fullName: map['fullName']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      email: map['email']?.toString(),
      commune: map['commune']?.toString() ?? '',
      motoType: map['motoType']?.toString() ?? '',
      plaque: map['plaque']?.toString(),
      idType: map['idType']?.toString() ?? '',
      idNumber: map['idNumber']?.toString() ?? '',
      idPhotoPath: map['idPhotoPath']?.toString(),
      status: LivreurStatusX.fromString(map['status']?.toString()),
      disponible: map['disponible'] as bool? ?? false,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      livraisonsEffectuees: (map['livraisonsEffectuees'] as num?)?.toInt() ?? 0,
      gains: (map['gains'] as num?)?.toDouble() ?? 0,
      activeDeliveryId: map['activeDeliveryId']?.toString(),
    );
  }

  /// Utilitaire pour les écrans qui lisent directement un snapshot.
  factory LivreurModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return LivreurModel.fromMap({...?doc.data(), 'id': doc.id});
  }
}

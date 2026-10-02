import 'package:cloud_firestore/cloud_firestore.dart';

/// Statuts de livraison (cahier des charges §5.7), adaptés au parcours
/// « commerçants → motard → dealer ».
enum DeliveryStatus {
  /// En attente d'affectation : visible par tous les motards disponibles.
  pendingAssignment,

  /// Motard affecté (il a pris la course).
  assigned,

  /// Collecte en cours : au moins un commerçant a été visité.
  collecting,

  /// Tous les colis sont récupérés, le motard roule vers le dealer.
  enRoute,

  /// Colis remis au dealer.
  delivered,

  dealerAbsent,
  wrongAddress,
  cancelled,
  returned,
}

extension DeliveryStatusX on DeliveryStatus {
  static DeliveryStatus fromString(String? value) {
    return DeliveryStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => DeliveryStatus.pendingAssignment,
    );
  }

  String get label => switch (this) {
    DeliveryStatus.pendingAssignment => "En attente d'affectation",
    DeliveryStatus.assigned => 'Motard affecté',
    DeliveryStatus.collecting => 'Collecte en cours',
    DeliveryStatus.enRoute => 'En route vers le dealer',
    DeliveryStatus.delivered => 'Livré au dealer',
    DeliveryStatus.dealerAbsent => 'Dealer absent',
    DeliveryStatus.wrongAddress => 'Adresse incorrecte',
    DeliveryStatus.cancelled => 'Livraison annulée',
    DeliveryStatus.returned => 'Colis retourné',
  };
}

/// État d'un arrêt de récupération chez un commerçant.
enum PickupStatus {
  pending,
  collected,

  /// Rupture de stock, commerçant fermé ou introuvable (§11).
  unavailable,
}

extension PickupStatusX on PickupStatus {
  static PickupStatus fromString(String? value) {
    return PickupStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => PickupStatus.pending,
    );
  }

  String get label => switch (this) {
    PickupStatus.pending => 'À récupérer',
    PickupStatus.collected => 'Récupéré',
    PickupStatus.unavailable => 'Indisponible',
  };
}

/// Un lieu de la course : commerçant ou dealer.
///
/// Les adresses kinoises sont souvent imprécises (§17) : [reference]
/// porte l'indication complémentaire, et [latitude]/[longitude] (le pin
/// posé sur la carte) font foi pour l'itinéraire.
class DeliveryPlace {
  const DeliveryPlace({
    required this.name,
    required this.address,
    required this.commune,
    this.reference = '',
    this.phone,
    this.latitude,
    this.longitude,
  });

  final String name;
  final String address;
  final String commune;
  final String reference;
  final String? phone;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'name': name,
    'address': address,
    'commune': commune,
    'reference': reference,
    'phone': phone,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory DeliveryPlace.fromMap(Map<String, dynamic>? map) {
    final data = map ?? const <String, dynamic>{};
    return DeliveryPlace(
      name: data['name']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      commune: data['commune']?.toString() ?? '',
      reference: data['reference']?.toString() ?? '',
      phone: data['phone']?.toString(),
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
    );
  }
}

/// Un article à récupérer chez un commerçant.
class PickupItem {
  const PickupItem({required this.name, required this.quantity});

  final String name;
  final int quantity;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'name': name,
    'quantity': quantity,
  };

  factory PickupItem.fromMap(Map<String, dynamic> map) {
    return PickupItem(
      name: map['name']?.toString() ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}

/// Un arrêt de récupération : un commerçant et les articles à y prendre.
class PickupStop {
  const PickupStop({
    required this.merchantId,
    required this.place,
    required this.items,
    this.status = PickupStatus.pending,
    this.collectedAt,
  });

  final String merchantId;
  final DeliveryPlace place;
  final List<PickupItem> items;
  final PickupStatus status;
  final DateTime? collectedAt;

  int get itemsCount => items.fold(0, (total, item) => total + item.quantity);

  Map<String, dynamic> toMap() => <String, dynamic>{
    'merchantId': merchantId,
    'place': place.toMap(),
    'items': items.map((item) => item.toMap()).toList(),
    'status': status.name,
    'collectedAt': collectedAt == null
        ? null
        : Timestamp.fromDate(collectedAt!),
  };

  factory PickupStop.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'];
    final rawCollectedAt = map['collectedAt'];

    return PickupStop(
      merchantId: map['merchantId']?.toString() ?? '',
      place: DeliveryPlace.fromMap(DeliveryModel._asMap(map['place'])),
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(
                  (item) => PickupItem.fromMap(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
      status: PickupStatusX.fromString(map['status']?.toString()),
      collectedAt: rawCollectedAt is Timestamp ? rawCollectedAt.toDate() : null,
    );
  }
}

/// Document `deliveries/{id}` — une course de livraison.
///
/// Le motard récupère les articles d'une commande chez un ou plusieurs
/// commerçants ([pickups]), puis livre le tout au dealer ([dropoff]). Le
/// dealer remet ensuite la commande au client : le motard n'a jamais
/// besoin des coordonnées du client.
///
/// C'est un instantané autonome : le motard n'a pas besoin de lire la
/// commande ni le commerçant pour livrer.
class DeliveryModel {
  const DeliveryModel({
    required this.id,
    required this.orderId,
    required this.dealerId,
    required this.status,
    required this.pickups,
    required this.dropoff,
    required this.deliveryFee,
    this.urgent = false,
    this.note,
    this.livreurId,
    this.livreurName,
    this.livreurPhone,
    this.assignedAt,
    this.refusedBy = const [],
    this.createdAt,
  });

  final String id;
  final String orderId;
  final String dealerId;
  final DeliveryStatus status;

  /// Arrêts chez les commerçants, dans l'ordre de passage (l'ordre
  /// optimal est calculé plus tard avec l'itinéraire).
  final List<PickupStop> pickups;

  /// Le dealer, destination finale de la course.
  final DeliveryPlace dropoff;

  /// Ce que le motard gagne pour cette course (§4.4).
  final double deliveryFee;
  final bool urgent;
  final String? note;
  final String? livreurId;
  final String? livreurName;
  final String? livreurPhone;
  final DateTime? assignedAt;

  /// Motards qui ont refusé cette course : elle ne leur est plus proposée.
  final List<String> refusedBy;

  /// Null tant que l'horodatage serveur n'est pas revenu.
  final DateTime? createdAt;

  int get itemsCount =>
      pickups.fold(0, (total, stop) => total + stop.itemsCount);

  int get collectedCount =>
      pickups.where((stop) => stop.status == PickupStatus.collected).length;

  Map<String, dynamic> toMap() => <String, dynamic>{
    'orderId': orderId,
    'dealerId': dealerId,
    'status': status.name,
    'pickups': pickups.map((stop) => stop.toMap()).toList(),
    'dropoff': dropoff.toMap(),
    'deliveryFee': deliveryFee,
    'urgent': urgent,
    'note': note,
    'livreurId': livreurId,
    'livreurName': livreurName,
    'livreurPhone': livreurPhone,
    'refusedBy': refusedBy,
  };

  factory DeliveryModel.fromMap(Map<String, dynamic> map) {
    final rawCreatedAt = map['createdAt'];
    final rawAssignedAt = map['assignedAt'];
    final rawRefusedBy = map['refusedBy'];
    final rawPickups = map['pickups'];

    return DeliveryModel(
      id: map['id']?.toString() ?? '',
      orderId: map['orderId']?.toString() ?? '',
      dealerId: map['dealerId']?.toString() ?? '',
      status: DeliveryStatusX.fromString(map['status']?.toString()),
      pickups: rawPickups is List
          ? rawPickups
                .whereType<Map>()
                .map(
                  (stop) => PickupStop.fromMap(Map<String, dynamic>.from(stop)),
                )
                .toList()
          : const [],
      dropoff: DeliveryPlace.fromMap(_asMap(map['dropoff'])),
      deliveryFee: (map['deliveryFee'] as num?)?.toDouble() ?? 0,
      urgent: map['urgent'] as bool? ?? false,
      note: map['note']?.toString(),
      livreurId: map['livreurId']?.toString(),
      livreurName: map['livreurName']?.toString(),
      livreurPhone: map['livreurPhone']?.toString(),
      assignedAt: rawAssignedAt is Timestamp ? rawAssignedAt.toDate() : null,
      refusedBy: rawRefusedBy is List
          ? rawRefusedBy.map((e) => e.toString()).toList()
          : const [],
      createdAt: rawCreatedAt is Timestamp ? rawCreatedAt.toDate() : null,
    );
  }

  factory DeliveryModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return DeliveryModel.fromMap({...?doc.data(), 'id': doc.id});
  }

  static Map<String, dynamic>? _asMap(Object? value) {
    return value is Map ? Map<String, dynamic>.from(value) : null;
  }
}

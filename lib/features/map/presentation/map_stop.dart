import 'package:dksoft_market_livreur/features/deliveries/domain/delivery_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Un arrêt du trajet : un commerçant à visiter, ou le dealer (dernier
/// arrêt). Vue simplifiée d'une [DeliveryModel] pour la carte.
class MapStop {
  const MapStop({
    required this.order,
    required this.place,
    required this.isDealer,
    this.status,
    this.itemsCount = 0,
  });

  /// Rang dans le trajet (0 = premier arrêt).
  final int order;
  final DeliveryPlace place;
  final bool isDealer;

  /// État de la récupération (null pour le dealer).
  final PickupStatus? status;
  final int itemsCount;

  /// Reste à faire : un commerçant non récupéré, ou le dealer.
  bool get isPending => isDealer || status == PickupStatus.pending;

  LatLng? get position =>
      place.hasCoordinates ? LatLng(place.latitude!, place.longitude!) : null;

  /// Les commerçants dans l'ordre, puis le dealer.
  static List<MapStop> fromDelivery(DeliveryModel delivery) {
    final stops = <MapStop>[
      for (final (index, pickup) in delivery.pickups.indexed)
        MapStop(
          order: index,
          place: pickup.place,
          isDealer: false,
          status: pickup.status,
          itemsCount: pickup.itemsCount,
        ),
    ];

    stops.add(
      MapStop(
        order: delivery.pickups.length,
        place: delivery.dropoff,
        isDealer: true,
      ),
    );
    return stops;
  }

  /// Prochain arrêt à faire : le premier commerçant non récupéré, sinon
  /// le dealer.
  static MapStop? next(List<MapStop> stops) {
    for (final stop in stops) {
      if (stop.isPending) return stop;
    }
    return null;
  }
}

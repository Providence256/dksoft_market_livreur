import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dksoft_market_livreur/features/deliveries/domain/delivery_model.dart';

Map<String, dynamic> placeMap(
  String name, {
  Object? latitude = -4.31,
  Object? longitude = 15.30,
}) => {
  'name': name,
  'address': 'Av. Test',
  'commune': 'Gombe',
  'reference': '',
  'phone': null,
  'latitude': latitude,
  'longitude': longitude,
};

Map<String, dynamic> stopMap(String name, {String status = 'pending'}) => {
  'merchantId': 'm-$name',
  'place': placeMap(name),
  'items': [
    {'name': 'Article', 'quantity': 2},
  ],
  'status': status,
};

/// Course telle que le backend l'écrit (orders.ts).
DeliveryModel delivery({
  String id = 'D1',
  String status = 'delivered',
  double fee = 4,
  DateTime? deliveredAt,
  List<Map<String, dynamic>>? pickups,
}) {
  return DeliveryModel.fromMap({
    'id': id,
    'orderId': 'order-abc123',
    'dealerId': 'dealer1',
    'status': status,
    'pickups': pickups ?? [stopMap('A'), stopMap('B')],
    'dropoff': placeMap('Dealer'),
    'deliveryFee': fee,
    'refusedBy': ['L9'],
    'deliveredAt': deliveredAt == null ? null : Timestamp.fromDate(deliveredAt),
  });
}

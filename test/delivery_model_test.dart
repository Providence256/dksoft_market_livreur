import 'package:dksoft_market_livreur/features/deliveries/domain/delivery_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'delivery_fixtures.dart';

void main() {
  group('DeliveryModel.fromMap', () {
    test('lit une course écrite par le backend', () {
      final d = delivery(status: 'pendingAssignment');

      expect(d.status, DeliveryStatus.pendingAssignment);
      expect(d.pickups, hasLength(2));
      expect(d.itemsCount, 4);
      expect(d.refusedBy, ['L9']);
      expect(d.shortRef, '#ABC123');
      expect(d.nextPickupIndex, 0);
    });

    test('statut inconnu ou champs absents : valeurs par défaut', () {
      final d = DeliveryModel.fromMap({'id': 'X', 'status': 'nimporte'});

      expect(d.pickups, isEmpty);
      expect(d.deliveryFee, 0);
      expect(d.dropoff.name, isEmpty);
    });

    test("prochain arrêt : le premier pas encore traité", () {
      final d = delivery(
        status: 'collecting',
        pickups: [
          stopMap('A', status: 'collected'),
          stopMap('B'),
        ],
      );
      expect(d.nextPickupIndex, 1);
      expect(d.collectedCount, 1);
    });
  });

  group('DeliveryPlace.hasCoordinates', () {
    DeliveryPlace place(Object? lat, Object? lng) =>
        DeliveryPlace.fromMap(placeMap('P', latitude: lat, longitude: lng));

    test('position réelle', () {
      expect(place(-4.31, 15.30).hasCoordinates, isTrue);
    });

    test('pas de position', () {
      expect(place(null, 15.30).hasCoordinates, isFalse);
      expect(place(-4.31, null).hasCoordinates, isFalse);
    });

    test('(0, 0) = épingle jamais posée, ignorée', () {
      expect(place(0, 0).hasCoordinates, isFalse);
      expect(place(0.0, 15.3).hasCoordinates, isTrue);
    });
  });
}

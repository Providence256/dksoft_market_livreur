import 'package:dksoft_market_livreur/features/map/presentation/map_stop.dart';
import 'package:flutter_test/flutter_test.dart';

import 'delivery_fixtures.dart';

void main() {
  test('les commerçants dans l’ordre, puis le dealer', () {
    final stops = MapStop.fromDelivery(delivery(status: 'assigned'));

    expect(stops.map((s) => s.place.name), ['A', 'B', 'Dealer']);
    expect(stops.last.isDealer, isTrue);
    expect(MapStop.next(stops)?.place.name, 'A');
  });

  test('prochain arrêt : le dealer quand la collecte est finie', () {
    final stops = MapStop.fromDelivery(
      delivery(
        status: 'enRoute',
        pickups: [
          stopMap('A', status: 'collected'),
          stopMap('B', status: 'unavailable'),
        ],
      ),
    );
    expect(MapStop.next(stops)?.isDealer, isTrue);
  });
}

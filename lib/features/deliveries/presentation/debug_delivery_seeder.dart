import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dksoft_market_livreur/features/deliveries/data/deliveries_repository.dart';
import 'package:dksoft_market_livreur/features/deliveries/domain/delivery_model.dart';

// ============================================================
// OUTIL DE TEST — À SUPPRIMER.
// Crée de fausses courses (plusieurs commerçants -> un dealer) pour
// développer l'app motard tant que l'app client / dealer n'écrit pas
// encore dans `deliveries`.
// Supprimer ce fichier + le bouton dans available_deliveries_screen.dart.
// ============================================================

/// Centres approximatifs des communes (latitude, longitude). Valeurs de
/// TEST uniquement : assez proches pour voir un trajet sur la carte, pas
/// assez précises pour de vraies adresses.
const _communeCenters = <String, (double, double)>{
  'Gombe': (-4.3095, 15.3000),
  'Limete': (-4.3333, 15.3500),
  'Lemba': (-4.3833, 15.3167),
  'Ngaliema': (-4.3667, 15.2500),
  'Matete': (-4.3833, 15.3333),
  'Masina': (-4.3833, 15.4000),
  'Kintambo': (-4.3167, 15.2667),
  'Bandalungwa': (-4.3417, 15.2833),
  'Kasa-Vubu': (-4.3417, 15.3083),
  'Kalamu': (-4.3500, 15.3150),
};

class _Merchant {
  const _Merchant(this.name, this.address, this.commune, this.items);

  final String name;
  final String address;
  final String commune;
  final List<(String, int)> items;
}

class _Scenario {
  const _Scenario({
    required this.dealerName,
    required this.dealerAddress,
    required this.dealerCommune,
    required this.dealerReference,
    required this.fee,
    required this.merchants,
    this.urgent = false,
  });

  final String dealerName;
  final String dealerAddress;
  final String dealerCommune;
  final String dealerReference;
  final double fee;
  final bool urgent;
  final List<_Merchant> merchants;
}

const _scenarios = <_Scenario>[
  // Deux commerçants -> dealer à Kasa-Vubu.
  _Scenario(
    dealerName: 'Dealer Patrick',
    dealerAddress: 'Avenue Kasa-Vubu n°21',
    dealerCommune: 'Kasa-Vubu',
    dealerReference: 'En face de la pharmacie',
    fee: 6.0,
    merchants: [
      _Merchant('TechHub Store', '12, Avenue de la Justice', 'Limete', [
        ('Téléphone Samsung A15', 1),
      ]),
      _Merchant('Accessoires Mobile', '45, Avenue du Commerce', 'Gombe', [
        ('Coque de protection', 1),
        ('Chargeur rapide', 2),
      ]),
    ],
  ),
  // Trois commerçants -> dealer à Ngaliema, urgent.
  _Scenario(
    dealerName: 'Dealer Grâce',
    dealerAddress: 'Avenue de la Libération n°8',
    dealerCommune: 'Ngaliema',
    dealerReference: 'Près du rond-point',
    fee: 9.0,
    urgent: true,
    merchants: [
      _Merchant('iZone Boutique', '3, Boulevard du 30 Juin', 'Gombe', [
        ('Écouteurs Bluetooth', 2),
      ]),
      _Merchant('Maison Déco Kin', '3, Avenue Kimbuta', 'Matete', [
        ('Lampe de chevet', 1),
        ('Coussins', 4),
      ]),
      _Merchant('Chaussures Élégance', '18, Avenue Kabasele', 'Kintambo', [
        ('Baskets taille 42', 1),
      ]),
    ],
  ),
  // Un seul commerçant -> dealer à Masina.
  _Scenario(
    dealerName: 'Dealer Joël',
    dealerAddress: 'Quartier Camp Luka, 5e rue',
    dealerCommune: 'Masina',
    dealerReference: 'Appeler en arrivant',
    fee: 4.0,
    merchants: [
      _Merchant('Électro Plus', '27, Avenue Bokassa', 'Kalamu', [
        ('Ventilateur', 1),
      ]),
    ],
  ),
];

final _random = Random();

/// Point proche du centre de la commune, décalé au hasard (~300 m) pour
/// que deux lieux de la même commune n'aient pas les mêmes coordonnées.
(double, double) _coordsFor(String commune) {
  final center = _communeCenters[commune] ?? (-4.3250, 15.3222);
  return (
    center.$1 + (_random.nextDouble() - 0.5) * 0.006,
    center.$2 + (_random.nextDouble() - 0.5) * 0.006,
  );
}

DeliveryPlace _place({
  required String name,
  required String address,
  required String commune,
  String reference = '',
  String? phone,
}) {
  final coords = _coordsFor(commune);
  return DeliveryPlace(
    name: name,
    address: address,
    commune: commune,
    reference: reference,
    phone: phone,
    latitude: coords.$1,
    longitude: coords.$2,
  );
}

/// Crée une course de test en attente d'affectation.
Future<void> createTestDelivery() async {
  final scenario = _scenarios[_random.nextInt(_scenarios.length)];

  final delivery = DeliveryModel(
    id: '',
    orderId: 'TEST-${_random.nextInt(90000) + 10000}',
    dealerId: 'test-dealer',
    status: DeliveryStatus.pendingAssignment,
    pickups: [
      for (final (index, merchant) in scenario.merchants.indexed)
        PickupStop(
          merchantId: 'test-merchant-$index',
          place: _place(
            name: merchant.name,
            address: merchant.address,
            commune: merchant.commune,
            phone: '+24399000010$index',
          ),
          items: [
            for (final (name, quantity) in merchant.items)
              PickupItem(name: name, quantity: quantity),
          ],
        ),
    ],
    dropoff: _place(
      name: scenario.dealerName,
      address: scenario.dealerAddress,
      commune: scenario.dealerCommune,
      reference: scenario.dealerReference,
      phone: '+243990000099',
    ),
    deliveryFee: scenario.fee,
    urgent: scenario.urgent,
  );

  await FirebaseFirestore.instance
      .collection(DeliveriesRepository.deliveriesPath)
      .add({...delivery.toMap(), 'createdAt': FieldValue.serverTimestamp()});
}

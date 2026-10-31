import 'package:dksoft_market_livreur/features/deliveries/domain/delivery_model.dart';
import 'package:dksoft_market_livreur/features/map/data/location_repository.dart';
import 'package:dksoft_market_livreur/features/routing/domain/route_info.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Briques communes aux trois cartes (aperçu, détail d'une course,
/// navigation).

/// Vue de départ, avant que la carte ne s'ajuste aux arrêts.
const kKinshasaCenter = LatLng(-4.325, 15.322);

/// Les commerçants localisés puis le dealer, dans l'ordre de passage.
List<LatLng> deliveryPoints(DeliveryModel delivery) => [
  for (final p in delivery.pickups)
    if (p.place.hasCoordinates) LatLng(p.place.latitude!, p.place.longitude!),
  if (delivery.dropoff.hasCoordinates)
    LatLng(delivery.dropoff.latitude!, delivery.dropoff.longitude!),
];

/// Tracé de l'itinéraire : trait marine liseré de blanc qui suit les rues,
/// ou pointillés en ligne droite entre [fallback] tant que la route n'est
/// pas connue.
Set<Polyline> routePolylines(RouteInfo? route, List<LatLng> fallback) {
  if (route != null) {
    return {
      Polyline(
        polylineId: const PolylineId('route-casing'),
        points: route.points,
        width: 9,
        color: Colors.white,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
      Polyline(
        polylineId: const PolylineId('route'),
        points: route.points,
        width: 5,
        color: AppColors.primary,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
        zIndex: 1,
      ),
    };
  }
  if (fallback.length < 2) return const {};
  return {
    Polyline(
      polylineId: const PolylineId('fallback'),
      points: fallback,
      width: 4,
      color: AppColors.primary.withValues(alpha: 0.7),
      patterns: [PatternItem.dash(14), PatternItem.gap(10)],
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    ),
  };
}

/// Halo léger autour de la moto du livreur.
Set<Circle> riderHalo(LatLng? point, {double radius = 150}) {
  if (point == null) return const {};
  return {
    Circle(
      circleId: const CircleId('rider-halo'),
      center: point,
      radius: radius,
      fillColor: AppColors.primary.withValues(alpha: 0.08),
      strokeColor: AppColors.primary.withValues(alpha: 0.2),
      strokeWidth: 1,
    ),
  };
}

/// Ouvre le bon réglage (ou redemande la permission) pour rétablir l'accès
/// à la position.
Future<void> fixLocationAccess(WidgetRef ref, LocationAccess access) async {
  final repository = ref.read(locationRepositoryProvider);
  switch (access) {
    case LocationAccess.serviceDisabled:
      await repository.openLocationSettings();
    case LocationAccess.deniedForever:
      await repository.openAppSettings();
    case LocationAccess.denied || LocationAccess.granted:
      await ref.read(locationAccessProvider.notifier).recheck();
  }
}

/// Interpolation d'un cap par le plus court chemin (350° -> 10° passe par
/// 0°, sans refaire le tour).
class AngleTween extends Tween<double> {
  AngleTween({required double end}) : super(begin: end, end: end);

  @override
  double lerp(double t) {
    final a = begin!;
    final b = end!;
    final delta = ((b - a + 540) % 360) - 180;
    return a + delta * t;
  }
}

/// Interpolation d'une position : fait glisser la moto.
class LatLngTween extends Tween<LatLng> {
  LatLngTween({required LatLng end}) : super(begin: end, end: end);

  @override
  LatLng lerp(double t) {
    final a = begin!;
    final b = end!;
    return LatLng(
      a.latitude + (b.latitude - a.latitude) * t,
      a.longitude + (b.longitude - a.longitude) * t,
    );
  }
}

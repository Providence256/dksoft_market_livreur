import 'package:dksoft_market_livreur/features/map/presentation/widgets/map_skeleton.dart';
import 'dart:ui' as ui;
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';

import 'package:dksoft_market_livreur/core/data/livreur_repository.dart';
import 'package:dksoft_market_livreur/core/widgets/app_button.dart';
import 'package:dksoft_market_livreur/core/widgets/empty_state.dart';
import 'package:dksoft_market_livreur/core/widgets/pill.dart';
import 'package:dksoft_market_livreur/features/deliveries/data/deliveries_repository.dart';
import 'package:dksoft_market_livreur/features/deliveries/domain/delivery_model.dart';
import 'package:dksoft_market_livreur/features/deliveries/presentation/widgets/offer_card.dart';
import 'package:dksoft_market_livreur/features/map/data/location_repository.dart';
import 'package:dksoft_market_livreur/features/map/presentation/map_camera.dart';
import 'package:dksoft_market_livreur/features/map/presentation/map_layers.dart';
import 'package:dksoft_market_livreur/features/map/presentation/map_style.dart';
import 'package:dksoft_market_livreur/features/map/presentation/marker_icon_factory.dart';
import 'package:dksoft_market_livreur/features/map/presentation/moto_color.dart';
import 'package:dksoft_market_livreur/features/map/presentation/rider_location.dart';
import 'package:dksoft_market_livreur/features/map/presentation/widgets/map_round_button.dart';
import 'package:dksoft_market_livreur/features/routing/data/routing_repository.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Proposition de course : la carte avec le trajet complet (position du
/// livreur, commerçants, dealer, durée) et, en bas, le gain, le détail du
/// parcours et les boutons Refuser / Accepter.
class DeliveryDetailScreen extends ConsumerWidget {
  const DeliveryDetailScreen({super.key, required this.deliveryId});

  final String deliveryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deliveryAsync = ref.watch(deliveryByIdProvider(deliveryId));

    return Scaffold(
      body: deliveryAsync.when(
        loading: () => const MapSkeleton(),
        error: (_, _) => const EmptyState(
          icon: AppIcons.offline,
          title: 'Impossible de charger la course',
          message: 'Vérifiez votre connexion internet.',
        ),
        data: (delivery) => delivery == null
            ? EmptyState(
                icon: AppIcons.searchOff,
                title: "Cette course n'existe plus",
                message: 'Elle a été annulée ou retirée.',
                action: AppButton(
                  label: 'Retour',
                  expand: false,
                  onPressed: () => context.pop(),
                ),
              )
            : _OfferView(delivery: delivery),
      ),
    );
  }
}

class _OfferView extends ConsumerStatefulWidget {
  const _OfferView({required this.delivery});

  final DeliveryModel delivery;

  @override
  ConsumerState<_OfferView> createState() => _OfferViewState();
}

class _OfferViewState extends ConsumerState<_OfferView> {
  final _icons = MarkerIconFactory();
  final _ratio = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;

  GoogleMapController? _map;
  BitmapDescriptor? _riderIcon;
  BitmapDescriptor? _dealerIcon;
  final Map<int, BitmapDescriptor> _pickupIcons = {};
  BitmapDescriptor? _etaIcon;
  int? _etaMinutes;

  bool _fitted = false;
  bool _fittedWithRoute = false;

  @override
  void initState() {
    super.initState();
    _loadIcons();
  }

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }

  Future<void> _loadIcons() async {
    final rider = await _icons.buildRider(
      _ratio,
      color: motoColorOf(ref.read(currentLivreurProvider).value?.motoColor),
    );
    final dealer = await _icons.buildPin(
      icon: Icons.flag_rounded,
      color: AppColors.primary,
      pixelRatio: _ratio,
      width: 40,
    );
    for (var i = 0; i < widget.delivery.pickups.length; i++) {
      _pickupIcons[i] = await _icons.buildPin(
        label: '${i + 1}',
        color: AppColors.secondary,
        pixelRatio: _ratio,
        width: 38,
      );
    }
    if (!mounted) return;
    setState(() {
      _riderIcon = rider;
      _dealerIcon = dealer;
    });
  }

  void _loadEta(int minutes) {
    _etaMinutes = minutes;
    _icons.buildEta(minutes, _ratio).then((icon) {
      if (mounted) setState(() => _etaIcon = icon);
    });
  }

  /// Cadre le trajet une fois sur les points, puis une seconde fois quand
  /// l'itinéraire routier arrive.
  void _maybeFit(List<LatLng> points) {
    if (_map == null || points.isEmpty) return;
    _fitted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) fitPoints(_map, points, padding: 70);
    });
  }

  @override
  Widget build(BuildContext context) {
    final delivery = widget.delivery;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final stopPoints = deliveryPoints(delivery);

    final position = ref.watch(riderPositionProvider).value;
    final fix = resolveRider(
      position,
      stopPoints.isEmpty ? null : stopPoints.first,
    );
    final riderPoint = fix.point;

    final waypoints = <LatLng>[?riderPoint, ...stopPoints];
    final routeAsync = waypoints.length >= 2
        ? ref.watch(
            routeProvider(routeKey(waypoints, roundFirst: riderPoint != null)),
          )
        : null;
    final route = routeAsync?.value;

    if (route != null && _etaMinutes != route.minutes) _loadEta(route.minutes);

    if (_map != null) {
      if (route != null && !_fittedWithRoute) {
        _fittedWithRoute = true;
        _maybeFit([...route.points, ?riderPoint]);
      } else if (!_fitted && waypoints.isNotEmpty) {
        _maybeFit(waypoints);
      }
    }

    final markers = <Marker>{
      for (final (i, p) in delivery.pickups.indexed)
        if (p.place.hasCoordinates && _pickupIcons[i] != null)
          Marker(
            markerId: MarkerId('pickup-$i'),
            position: LatLng(p.place.latitude!, p.place.longitude!),
            icon: _pickupIcons[i]!,
            anchor: kPinAnchor,
            zIndexInt: 2,
            infoWindow: InfoWindow(
              title: p.place.name,
              snippet: p.place.commune,
            ),
          ),
      if (delivery.dropoff.hasCoordinates && _dealerIcon != null)
        Marker(
          markerId: const MarkerId('dealer'),
          position: LatLng(
            delivery.dropoff.latitude!,
            delivery.dropoff.longitude!,
          ),
          icon: _dealerIcon!,
          anchor: kPinAnchor,
          zIndexInt: 2,
          infoWindow: InfoWindow(
            title: delivery.dropoff.name,
            snippet: 'Dealer · ${delivery.dropoff.commune}',
          ),
        ),
      if (route != null && _etaIcon != null)
        Marker(
          markerId: const MarkerId('eta'),
          position: route.midPoint,
          icon: _etaIcon!,
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 5,
        ),
      if (riderPoint != null && _riderIcon != null)
        Marker(
          markerId: const MarkerId('rider'),
          position: riderPoint,
          icon: _riderIcon!,
          anchor: const Offset(0.5, 0.5),
          flat: true,
          rotation: riderHeadingOf(position) ?? 0,
          zIndexInt: 10,
          infoWindow: const InfoWindow(title: 'Vous êtes ici'),
        ),
    };

    return Stack(
      children: [
        GoogleMap(
          style: mapStyleFor(context.isDark),
          initialCameraPosition: CameraPosition(
            target: stopPoints.isEmpty ? kKinshasaCenter : stopPoints.first,
            zoom: 13,
          ),
          markers: markers,
          polylines: routePolylines(route, waypoints),
          circles: riderHalo(riderPoint),
          buildingsEnabled: true,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          padding: EdgeInsets.only(bottom: screenHeight * 0.46, top: 90),
          onMapCreated: (controller) {
            _map = controller;
            // La carte n'a pas encore sa taille finale : on cadre juste après.
            Future.delayed(const Duration(milliseconds: 350), () {
              if (mounted) setState(() {});
            });
          },
        ),

        // ---- Retour + notices ----
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Sizes.p12,
                Sizes.p8,
                Sizes.p12,
                0,
              ),
              child: Row(
                children: [
                  MapRoundButton(
                    icon: AppIcons.back,
                    tooltip: 'Retour',
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  if (fix.farAway)
                    const Pill(
                      label: 'Position hors de Kinshasa',
                      tone: PillTone.warning,
                      icon: AppIcons.locationOff,
                    ),
                  const Spacer(),
                  MapRoundButton(
                    icon: AppIcons.fitAll,
                    tooltip: "Vue d'ensemble",
                    onPressed: () => fitPoints(
                      _map,
                      route != null ? route.points : waypoints,
                      padding: 70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ---- Carte du bas ----
        Align(
          alignment: Alignment.bottomCenter,
          child: OfferCard(
            delivery: delivery,
            distanceMeters: route?.distanceMeters,
            durationSeconds: route?.durationSeconds,
            routeLoading: routeAsync?.isLoading ?? false,
            maxHeight: screenHeight * 0.58,
          ),
        ),
      ],
    );
  }
}

import 'dart:ui' as ui;

import 'package:dksoft_market_livreur/features/deliveries/data/deliveries_repository.dart';
import 'package:dksoft_market_livreur/features/deliveries/domain/delivery_model.dart';
import 'package:dksoft_market_livreur/features/map/data/location_repository.dart';
import 'package:dksoft_market_livreur/features/map/presentation/map_stop.dart';
import 'package:dksoft_market_livreur/features/map/presentation/marker_icon_factory.dart';
import 'package:dksoft_market_livreur/features/map/presentation/widgets/location_banner.dart';
import 'package:dksoft_market_livreur/features/map/presentation/widgets/stops_sheet.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/helpers/external_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Carte d'une course : position du motard, commerçants numérotés dans
/// l'ordre de passage, et dealer (arrivée).
///
/// Les traits pointillés relient les arrêts restants en ligne droite :
/// c'est un aperçu. Le vrai itinéraire routier (distance, durée) arrive à
/// l'étape suivante.
class DeliveryMapScreen extends ConsumerStatefulWidget {
  const DeliveryMapScreen({super.key, required this.deliveryId});

  final String deliveryId;

  @override
  ConsumerState<DeliveryMapScreen> createState() => _DeliveryMapScreenState();
}

class _DeliveryMapScreenState extends ConsumerState<DeliveryMapScreen>
    with WidgetsBindingObserver {
  /// Vue de départ : Kinshasa, avant que la carte ne s'ajuste aux arrêts.
  static const _kinshasa = LatLng(-4.325, 15.322);

  final _icons = MarkerIconFactory();
  GoogleMapController? _controller;
  Set<Marker> _markers = const {};
  String? _signature;
  bool _hasFitted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    ref.listenManual<AsyncValue<DeliveryModel?>>(
      deliveryByIdProvider(widget.deliveryId),
      (_, next) => _syncMarkers(next.value),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  /// Le motard revient des Réglages du téléphone : on revérifie l'accès
  /// à la position (sans redemander la permission).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(locationAccessProvider.notifier).recheck(request: false);
    }
  }

  // ---------------------------------------------------------------
  // Marqueurs
  // ---------------------------------------------------------------

  String _signatureOf(DeliveryModel delivery) {
    return MapStop.fromDelivery(delivery)
        .map(
          (stop) =>
              '${stop.order}:${stop.status?.name}:'
              '${stop.place.latitude}:${stop.place.longitude}',
        )
        .join('|');
  }

  Future<void> _syncMarkers(DeliveryModel? delivery) async {
    if (delivery == null) return;

    final signature = _signatureOf(delivery);
    if (signature == _signature) return;
    _signature = signature;

    final ratio = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    final markers = <Marker>{};

    for (final stop in MapStop.fromDelivery(delivery)) {
      final position = stop.position;
      if (position == null) continue;

      final icon = stop.isDealer
          ? await _icons.build(
              icon: Icons.flag,
              color: AppColors.secondary,
              pixelRatio: ratio,
            )
          : switch (stop.status) {
              PickupStatus.collected => await _icons.build(
                icon: Icons.check,
                color: AppColors.success,
                pixelRatio: ratio,
              ),
              PickupStatus.unavailable => await _icons.build(
                icon: Icons.close,
                color: AppColors.error,
                pixelRatio: ratio,
              ),
              _ => await _icons.build(
                label: '${stop.order + 1}',
                color: AppColors.primary,
                pixelRatio: ratio,
              ),
            };

      markers.add(
        Marker(
          markerId: MarkerId('stop-${stop.order}'),
          position: position,
          icon: icon,
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(
            title: stop.place.name,
            snippet: stop.isDealer
                ? 'Remise au dealer · ${stop.place.commune}'
                : stop.place.commune,
          ),
        ),
      );
    }

    if (!mounted) return;
    setState(() => _markers = markers);

    if (!_hasFitted && _controller != null) {
      _hasFitted = true;
      await Future.delayed(const Duration(milliseconds: 250));
      if (mounted) await _fitAll();
    }
  }

  // ---------------------------------------------------------------
  // Caméra
  // ---------------------------------------------------------------

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;

    // La carte n'a pas encore sa taille finale : on attend un instant
    // avant de cadrer, sinon Google Maps refuse l'ajustement.
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted || _hasFitted || _markers.isEmpty) return;
      _hasFitted = true;
      _fitAll();
    });
  }

  /// Cadre les arrêts restants (et le motard s'il est localisé).
  Future<void> _fitAll() async {
    final controller = _controller;
    final delivery = ref.read(deliveryByIdProvider(widget.deliveryId)).value;
    if (controller == null || delivery == null) return;

    final points = <LatLng>[
      for (final stop in MapStop.fromDelivery(delivery))
        if (stop.isPending && stop.position != null) stop.position!,
    ];
    final rider = ref.read(riderPositionProvider).value;
    if (rider != null) points.add(LatLng(rider.latitude, rider.longitude));
    if (points.isEmpty) return;

    try {
      if (points.length == 1) {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(points.first, 15),
        );
        return;
      }

      final lats = points.map((p) => p.latitude);
      final lngs = points.map((p) => p.longitude);
      final bounds = LatLngBounds(
        southwest: LatLng(
          lats.reduce((a, b) => a < b ? a : b),
          lngs.reduce((a, b) => a < b ? a : b),
        ),
        northeast: LatLng(
          lats.reduce((a, b) => a > b ? a : b),
          lngs.reduce((a, b) => a > b ? a : b),
        ),
      );
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 72));
    } catch (_) {
      // Carte pas encore prête : l'utilisateur peut recadrer avec le bouton.
    }
  }

  Future<void> _focusOn(LatLng position) async {
    try {
      await _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(position, 16),
      );
    } catch (_) {}
  }

  Future<void> _centerOnRider() async {
    final rider = ref.read(riderPositionProvider).value;
    if (rider == null) {
      _showMessage('Votre position n\'est pas encore disponible.');
      return;
    }
    await _focusOn(LatLng(rider.latitude, rider.longitude));
  }

  // ---------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------

  Future<void> _navigateTo(MapStop stop) async {
    final ok = await openInMaps(stop.place);
    if (!ok) _showMessage("Impossible d'ouvrir l'application de cartes.");
  }

  Future<void> _fixLocation(LocationAccess access) async {
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

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------------------------------------------------------------
  // Interface
  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final deliveryAsync = ref.watch(deliveryByIdProvider(widget.deliveryId));

    return Scaffold(
      appBar: AppBar(title: const Text('Carte de la course')),
      body: deliveryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Impossible de charger la course.')),
        data: (delivery) => delivery == null
            ? const Center(child: Text("Cette course n'existe plus."))
            : _buildMap(context, delivery),
      ),
    );
  }

  Widget _buildMap(BuildContext context, DeliveryModel delivery) {
    final access = ref.watch(locationAccessProvider).value;
    final Position? rider = ref.watch(riderPositionProvider).value;

    final stops = MapStop.fromDelivery(delivery);
    final remaining = [
      for (final stop in stops)
        if (stop.isPending && stop.position != null) stop.position!,
    ];
    final mapHeight = MediaQuery.sizeOf(context).height;
    final missingGps = stops.where((s) => s.position == null).length;

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: _kinshasa,
            zoom: 11,
          ),
          markers: _markers,
          polylines: {
            if (remaining.length >= 2)
              Polyline(
                polylineId: const PolylineId('preview'),
                points: remaining,
                width: 4,
                color: AppColors.primary.withValues(alpha: 0.6),
                patterns: [PatternItem.dash(18), PatternItem.gap(10)],
              ),
          },
          // Le point bleu du motard : seulement si la permission est
          // accordée, sinon Android lève une exception.
          myLocationEnabled: access == LocationAccess.granted,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          // Réserve la place du panneau du bas pour le logo Google et le cadrage.
          padding: EdgeInsets.only(bottom: mapHeight * 0.28),
          onMapCreated: _onMapCreated,
        ),

        // ---- Bandeaux et boutons en haut ----
        Positioned(
          top: Sizes.p12,
          left: Sizes.p12,
          right: Sizes.p12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (access != null && access != LocationAccess.granted) ...[
                LocationBanner(
                  access: access,
                  onAction: () => _fixLocation(access),
                ),
                gapH8,
              ],
              if (missingGps > 0) ...[
                Material(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(16),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(Sizes.p12),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.warning,
                        ),
                        gapW8,
                        Expanded(
                          child: Text(
                            '$missingGps arrêt${missingGps > 1 ? 's' : ''} '
                            'sans position GPS : non affiché sur la carte.',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                gapH8,
              ],
              _RoundButton(
                icon: Icons.zoom_out_map_rounded,
                tooltip: "Vue d'ensemble",
                onPressed: _fitAll,
              ),
              gapH8,
              _RoundButton(
                icon: Icons.my_location_rounded,
                tooltip: 'Ma position',
                onPressed: _centerOnRider,
              ),
            ],
          ),
        ),

        // ---- Panneau des étapes ----
        StopsSheet(
          stops: stops,
          riderPosition: rider,
          onNavigate: _navigateTo,
          onFocus: (stop) {
            final position = stop.position;
            if (position != null) _focusOn(position);
          },
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, color: AppColors.primary),
        onPressed: onPressed,
      ),
    );
  }
}

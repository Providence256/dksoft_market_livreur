import 'dart:async';
import 'dart:ui' as ui;

import 'package:dksoft_market_livreur/core/data/livreur_repository.dart';
import 'package:dksoft_market_livreur/features/deliveries/data/deliveries_repository.dart';
import 'package:dksoft_market_livreur/features/deliveries/domain/delivery_model.dart';
import 'package:dksoft_market_livreur/features/map/data/location_repository.dart';
import 'package:dksoft_market_livreur/features/deliveries/presentation/delivery_action_controller.dart';
import 'package:dksoft_market_livreur/features/map/presentation/map_camera.dart';
import 'package:dksoft_market_livreur/features/map/presentation/map_stop.dart';
import 'package:dksoft_market_livreur/features/map/presentation/rider_location.dart';
import 'package:dksoft_market_livreur/features/map/presentation/moto_color.dart';
import 'package:dksoft_market_livreur/features/map/presentation/route_snap.dart';
import 'package:dksoft_market_livreur/features/routing/data/routing_repository.dart';
import 'package:dksoft_market_livreur/features/routing/domain/route_info.dart';
import 'package:dksoft_market_livreur/core/widgets/pill.dart';
import 'package:dksoft_market_livreur/utils/helpers/duration_format.dart';
import 'package:dksoft_market_livreur/features/map/presentation/marker_icon_factory.dart';
import 'package:dksoft_market_livreur/features/map/presentation/widgets/elapsed_timer_pill.dart';
import 'package:dksoft_market_livreur/features/map/presentation/widgets/location_banner.dart';
import 'package:dksoft_market_livreur/features/map/presentation/widgets/map_round_button.dart';
import 'package:dksoft_market_livreur/features/map/presentation/widgets/stops_sheet.dart';
import 'package:dksoft_market_livreur/features/shell/presentation/main_shell.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/helpers/distance_format.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Carte d'une course : position du motard, commerçants numérotés dans
/// l'ordre de passage, et dealer (arrivée).
///
/// Le tracé suit les rues (itinéraire routier) du livreur jusqu'au dernier
/// arrêt, avec la durée sur le trajet. Sans réseau de routage, un trait
/// pointillé relie les arrêts en ligne droite.
class DeliveryMapScreen extends ConsumerStatefulWidget {
  const DeliveryMapScreen({
    super.key,
    required this.deliveryId,
    this.embedded = false,
  });

  final String deliveryId;

  /// Affichée comme onglet (sans bouton retour).
  final bool embedded;

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

  /// Icône de la moto du livreur (dessinée au démarrage).
  BitmapDescriptor? _riderIcon;

  /// Fond satellite à la place du plan.
  bool _satellite = false;

  /// Dernière position du livreur retenue pour l'affichage.
  RiderFix _fix = const RiderFix(null, RiderSource.none);

  /// Dernier itinéraire connu : évite de faire clignoter le tracé pendant
  /// que le suivant se calcule.
  RouteInfo? _lastRoute;
  int? _lastNextOrder;
  BitmapDescriptor? _etaIcon;
  int? _etaMinutes;

  /// Navigation dans l'application : la caméra suit le livreur et un
  /// bandeau annonce la prochaine manœuvre.
  bool _navigating = false;
  double _bearing = 0;

  /// Dernier cap connu de la moto (conservé quand le GPS n'en donne pas).
  double _riderHeading = 0;
  bool _hasHeading = false;

  /// Mode test (debug seulement) : le livreur « roule » le long du tracé,
  /// une nouvelle position chaque seconde.
  Timer? _simTimer;
  Position? _simPosition;
  List<LatLng> _simPath = const [];
  int _simSeg = 0;
  String? _simPathFor;
  bool _simFetching = false;
  static const _simSpeed = 13.0; // m/s, environ 47 km/h

  late final FullScreenMap _fullScreen;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fullScreen = ref.read(fullScreenMapProvider.notifier);

    final ratio = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    // Moto de la couleur choisie par le livreur à l'inscription.
    ref.listenManual(currentLivreurProvider, (_, next) {
      _icons.buildRider(ratio, color: motoColorOf(next.value?.motoColor)).then((
        icon,
      ) {
        if (mounted) setState(() => _riderIcon = icon);
      });
    }, fireImmediately: true);

    ref.listenManual<AsyncValue<Position>>(riderPositionProvider, (_, next) {
      final position = next.value;
      if (_navigating && position != null && _simPosition == null) {
        _followRider(position);
      }
    });

    ref.listenManual<AsyncValue<DeliveryModel?>>(
      deliveryByIdProvider(widget.deliveryId),
      (_, next) => _syncMarkers(next.value),
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    final fullScreen = _fullScreen;
    Future.microtask(() => fullScreen.set(false));
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

    final allStops = MapStop.fromDelivery(delivery);
    final nextStop = MapStop.next(allStops);

    for (final stop in allStops) {
      final position = stop.position;
      if (position == null) continue;

      final isNext = identical(stop, nextStop);
      final badge = isNext ? 52.0 : 40.0;

      final (
        IconData? glyph,
        String? number,
        Color color,
        String subtitle,
      ) = stop.isDealer
          ? (Icons.flag_rounded, null, AppColors.primary, 'Dealer')
          : switch (stop.status) {
              PickupStatus.collected => (
                Icons.check_rounded,
                null,
                AppColors.success,
                'Récupéré',
              ),
              PickupStatus.unavailable => (
                Icons.close_rounded,
                null,
                AppColors.error,
                'Indisponible',
              ),
              _ => (
                null,
                '${stop.order + 1}',
                AppColors.secondary,
                '${stop.itemsCount} article${stop.itemsCount > 1 ? 's' : ''}',
              ),
            };

      final pin = await _icons.buildPin(
        icon: glyph,
        label: number,
        color: color,
        pixelRatio: ratio,
        width: badge * 0.85,
      );

      markers.add(
        Marker(
          markerId: MarkerId('stop-${stop.order}'),
          position: position,
          icon: pin,
          anchor: kPinAnchor,
          zIndexInt: isNext ? 3 : 1,
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

    // Premier cadrage, puis un nouveau à chaque changement d'arrêt.
    final nextOrder = nextStop?.order;
    final changed = _lastNextOrder != nextOrder;
    _lastNextOrder = nextOrder;
    if (_controller != null && (!_hasFitted || changed)) {
      _hasFitted = true;
      await Future.delayed(const Duration(milliseconds: 250));
      if (mounted) await _fitNext();
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
      _fitNext();
    });
  }

  /// Cadre le livreur et son prochain arrêt : assez près pour lire les rues.
  Future<void> _fitNext() async {
    final delivery = ref.read(deliveryByIdProvider(widget.deliveryId)).value;
    if (delivery == null) return;

    final target = MapStop.next(MapStop.fromDelivery(delivery))?.position;
    if (target == null) return;

    await fitPoints(_controller, [
      if (_fix.point != null) _fix.point!,
      target,
    ], padding: 90);
  }

  /// Vue d'ensemble : tout le trajet restant.
  Future<void> _fitAll() async {
    final delivery = ref.read(deliveryByIdProvider(widget.deliveryId)).value;
    if (delivery == null) return;

    final route = _lastRoute;
    final points = <LatLng>[
      if (route != null)
        ...route.points
      else
        for (final stop in MapStop.fromDelivery(delivery))
          if (stop.isPending && stop.position != null) stop.position!,
      if (_fix.point != null) _fix.point!,
    ];

    await fitPoints(_controller, points, padding: 90);
  }

  Future<void> _focusOn(LatLng position) async {
    try {
      await _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(position, 16.5),
      );
    } catch (_) {}
  }

  Future<void> _centerOnRider() async {
    final point = _fix.point;
    if (point == null) {
      _showMessage("Votre position n'est pas encore disponible.");
      return;
    }
    if (_navigating) {
      await _animateFollow(point);
      return;
    }
    await _focusOn(point);
  }

  void _loadEta(int minutes) {
    _etaMinutes = minutes;
    final ratio = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    _icons.buildEta(minutes, ratio).then((icon) {
      if (mounted) setState(() => _etaIcon = icon);
    });
  }

  // ---------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------

  /// Lance la navigation dans l'application : on reste sur la carte, le
  /// tracé suit les rues et la caméra accompagne le livreur.
  Future<void> _navigateTo(MapStop stop) async {
    final point = _fix.point;
    if (point == null) {
      _showMessage(
        "Position introuvable : activez la localisation pour naviguer.",
      );
      return;
    }
    setState(() => _navigating = true);
    _fullScreen.set(true);
    await _animateFollow(point);
  }

  // ---------------------------------------------------------------
  // Simulation de déplacement (test)
  // ---------------------------------------------------------------

  Position _positionOf(LatLng point, double heading) => Position(
    longitude: point.longitude,
    latitude: point.latitude,
    timestamp: DateTime.now(),
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: heading,
    headingAccuracy: 0,
    speed: _simSpeed,
    speedAccuracy: 0,
  );

  void _toggleSimulation() {
    if (_simTimer != null) {
      _simTimer!.cancel();
      setState(() {
        _simTimer = null;
        _simPosition = null;
      });
      return;
    }

    final delivery = ref.read(deliveryByIdProvider(widget.deliveryId)).value;
    final target = delivery == null
        ? null
        : MapStop.next(MapStop.fromDelivery(delivery))?.position;
    final start =
        _fix.point ??
        (target == null
            ? null
            : LatLng(target.latitude + 0.007, target.longitude - 0.006));
    if (start == null) {
      _showMessage('Aucun arrêt avec position GPS pour simuler.');
      return;
    }

    _simPath = const [];
    _simSeg = 0;
    _simPathFor = null;
    setState(() {
      _simPosition = _positionOf(start, 0);
      _simTimer = Timer.periodic(const Duration(seconds: 1), (_) => _simTick());
    });
  }

  void _simTick() {
    if (!mounted) return;
    final current = _simPosition;
    final delivery = ref.read(deliveryByIdProvider(widget.deliveryId)).value;
    if (current == null || delivery == null) return;

    final nextStop = MapStop.next(MapStop.fromDelivery(delivery));
    final target = nextStop?.position;
    if (nextStop == null || target == null) {
      // Course terminée (ou plus d'arrêt localisé) : fin de la simulation.
      _toggleSimulation();
      return;
    }

    final here = LatLng(current.latitude, current.longitude);
    final toTarget = Geolocator.distanceBetween(
      here.latitude,
      here.longitude,
      target.latitude,
      target.longitude,
    );

    // Déjà posé sur l'arrêt : le livreur attend qu'on valide.
    if (toTarget < 1) return;

    LatLng next;
    if (toTarget <= _simSpeed * 3) {
      // Dernière ligne droite : on se gare pile sur l'arrêt (le tracé
      // routier s'arrête souvent à la rue, à quelques dizaines de mètres).
      next = target;
      _showMessage(
        nextStop.isDealer
            ? 'Arrivé chez le dealer (simulation).'
            : 'Arrivé chez ${nextStop.place.name} (simulation).',
      );
    } else {
      // Chemin propre à cette destination : du point où l'on est jusqu'à
      // l'arrêt. On le suit dans l'ordre, sans jamais chercher « le point le
      // plus proche » (c'est ce qui faisait tourner en rond).
      final key = '${target.latitude},${target.longitude}';
      if (_simPathFor != key) {
        if (!_simFetching) _fetchSimPath(here, target, key);
        return;
      }
      next = _walk(here, target, _simSpeed);
    }

    final heading = Geolocator.bearingBetween(
      here.latitude,
      here.longitude,
      next.latitude,
      next.longitude,
    );
    final position = _positionOf(next, heading < 0 ? heading + 360 : heading);
    setState(() => _simPosition = position);
    if (_navigating) _followRider(position);
  }

  /// Pas en ligne droite vers [target].
  LatLng _stepToward(LatLng from, LatLng target, double meters) {
    final distance = Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      target.latitude,
      target.longitude,
    );
    if (distance <= meters) return target;
    final t = meters / distance;
    return LatLng(
      from.latitude + (target.latitude - from.latitude) * t,
      from.longitude + (target.longitude - from.longitude) * t,
    );
  }

  Future<void> _fetchSimPath(LatLng from, LatLng target, String key) async {
    _simFetching = true;
    final route = await ref.read(routingRepositoryProvider).route([
      from,
      target,
    ]);
    _simFetching = false;
    if (!mounted) return;
    _simPath = route?.points ?? const [];
    _simSeg = 0;
    _simPathFor = key;
  }

  /// Avance de [meters] le long du chemin simulé, puis tout droit vers
  /// l'arrêt quand le chemin est épuisé.
  LatLng _walk(LatLng from, LatLng target, double meters) {
    var current = from;
    var remaining = meters;

    while (remaining > 0 && _simSeg < _simPath.length) {
      final point = _simPath[_simSeg];
      final d = Geolocator.distanceBetween(
        current.latitude,
        current.longitude,
        point.latitude,
        point.longitude,
      );
      if (d <= remaining) {
        remaining -= d;
        current = point;
        _simSeg++;
      } else {
        return _stepToward(current, point, remaining);
      }
    }
    return remaining > 0 ? _stepToward(current, target, remaining) : current;
  }

  Future<void> _stopNavigation() async {
    setState(() => _navigating = false);
    _fullScreen.set(false);
    await _fitNext();
  }

  Future<void> _followRider(Position position) async {
    // On ne garde le cap que si le livreur roule : à l'arrêt, le GPS donne
    // un cap aléatoire qui ferait tourner la carte.
    if (position.speed > 1.5 && position.heading >= 0) {
      _bearing = position.heading;
    }
    final point = _fix.point;
    if (point == null) return;
    await _animateFollow(LatLng(position.latitude, position.longitude));
  }

  Future<void> _animateFollow(LatLng target) async {
    try {
      await _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: target,
            zoom: 17.3,
            tilt: 50,
            bearing: _bearing,
          ),
        ),
      );
    } catch (_) {}
  }

  /// Message d'erreur de la dernière action (course déjà modifiée, hors
  /// connexion…).
  void _showActionError() {
    final error = ref.read(deliveryActionControllerProvider).error;
    _showMessage(error?.toString() ?? 'Action impossible.');
  }

  Future<void> _collect(DeliveryModel delivery, MapStop stop) async {
    final ok = await ref
        .read(deliveryActionControllerProvider.notifier)
        .markPickup(delivery.id, stop.order);
    if (!ok) {
      _showActionError();
      return;
    }
    _showMessage('Récupéré chez ${stop.place.name}.');
  }

  Future<void> _markUnavailable(DeliveryModel delivery, MapStop stop) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Article indisponible ?'),
        content: Text(
          'Rupture de stock, commerçant fermé ou introuvable : '
          '${stop.place.name} sera marqué comme non récupéré.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await ref
        .read(deliveryActionControllerProvider.notifier)
        .markPickup(delivery.id, stop.order, status: PickupStatus.unavailable);
    if (!ok) _showActionError();
  }

  Future<void> _complete(DeliveryModel delivery) async {
    final ok = await ref
        .read(deliveryActionControllerProvider.notifier)
        .complete(delivery.id);
    if (!mounted) return;

    if (!ok) {
      _showActionError();
      return;
    }

    _simTimer?.cancel();
    _simTimer = null;
    _simPosition = null;
    _navigating = false;
    _fullScreen.set(false);
    _showMessage('Livraison terminée. Merci !');
    // Ouverte depuis l'écran de détail : on revient en arrière. Dans
    // l'onglet, la carte repasse seule aux demandes (plus de course active).
    if (!widget.embedded && context.canPop()) context.pop();
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
    final theme = Theme.of(context);
    final access = ref.watch(locationAccessProvider).value;
    final realRider = ref.watch(riderPositionProvider).value;
    final rawRider = _simPosition ?? realRider;
    final busy = ref.watch(deliveryActionControllerProvider).isLoading;

    final stops = MapStop.fromDelivery(delivery);
    final next = MapStop.next(stops);
    final pendingPoints = <LatLng>[
      for (final stop in stops)
        if (stop.isPending && stop.position != null) stop.position!,
    ];

    final fix = resolveRider(
      rawRider,
      pendingPoints.isEmpty ? null : pendingPoints.first,
    );
    _fix = fix;
    final riderPoint = fix.point;

    // Itinéraire routier : du livreur jusqu'au dernier arrêt restant.
    final waypoints = <LatLng>[
      if (riderPoint != null) riderPoint,
      ...pendingPoints,
    ];
    final routeAsync = waypoints.length >= 2
        ? ref.watch(
            routeProvider(routeKey(waypoints, roundFirst: riderPoint != null)),
          )
        : null;
    final fresh = routeAsync?.value;
    if (fresh != null) _lastRoute = fresh;
    final route = fresh ?? (waypoints.length >= 2 ? _lastRoute : null);
    if (route != null && _etaMinutes != route.minutes) _loadEta(route.minutes);

    final screenHeight = MediaQuery.sizeOf(context).height;
    final sheetFraction = (350 / screenHeight).clamp(0.34, 0.66);
    final missingGps = stops.where((s) => s.position == null).length;

    // Distance et durée jusqu'au prochain arrêt : celles de la route si on
    // les a, sinon la distance à vol d'oiseau.
    final nextPosition = next?.position;
    final straight = (riderPoint != null && nextPosition != null)
        ? Geolocator.distanceBetween(
            riderPoint.latitude,
            riderPoint.longitude,
            nextPosition.latitude,
            nextPosition.longitude,
          )
        : null;
    final legMeters = route?.firstLegMeters ?? straight;
    final legSeconds = route?.firstLegSeconds;

    // Pendant la navigation la carte occupe tout l'écran ; le panneau
    // (appeler, valider la récupération) revient à l'arrivée.
    final arrivedAtNext =
        straight != null && straight <= StopsSheet.arrivalRadius;
    final showSheet = !_navigating || arrivedAtNext;

    final title = next == null
        ? 'Course terminée'
        : next.isDealer
        ? 'En route vers le dealer'
        : 'Collecte en cours';

    // Moto ramenée sur la route (le GPS dérive de quelques mètres) avec le
    // cap de la rue ; sinon position et cap bruts du GPS.
    final knownHeading = riderHeadingOf(rawRider) ?? _riderHeading;
    final snapped = riderPoint == null
        ? null
        : snapToRoute(
            riderPoint,
            route?.points,
            preferBearing: _hasHeading ? knownHeading : null,
          );
    final shownPoint = snapped?.point ?? riderPoint;
    final shownHeading = snapped?.bearing ?? knownHeading;
    _riderHeading = shownHeading;
    _hasHeading =
        _hasHeading || riderHeadingOf(rawRider) != null || snapped != null;

    Widget buildMap(LatLng? riderShown, [double angle = 0]) {
      return GoogleMap(
        mapType: _satellite ? MapType.hybrid : MapType.normal,
        trafficEnabled: false,
        buildingsEnabled: true,
        compassEnabled: false,
        initialCameraPosition: CameraPosition(
          target: nextPosition ?? _kinshasa,
          zoom: 13,
        ),
        markers: {
          ..._markers,
          if (route != null && _etaIcon != null)
            Marker(
              markerId: const MarkerId('eta'),
              position: route.midPoint,
              icon: _etaIcon!,
              anchor: const Offset(0.5, 0.5),
              zIndexInt: 5,
            ),
          if (riderShown != null && _riderIcon != null)
            Marker(
              markerId: const MarkerId('rider'),
              position: riderShown,
              icon: _riderIcon!,
              anchor: const Offset(0.5, 0.5),
              flat: true,
              rotation: angle % 360,
              zIndexInt: 11,
              infoWindow: const InfoWindow(title: 'Vous êtes ici'),
            ),
        },
        polylines: {
          if (route != null) ...[
            Polyline(
              polylineId: const PolylineId('route-casing'),
              points: route.points,
              width: 8,
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
          ] else if (waypoints.length >= 2)
            Polyline(
              polylineId: const PolylineId('fallback'),
              points: waypoints,
              width: 4,
              color: AppColors.primary,
              patterns: [PatternItem.dash(16), PatternItem.gap(10)],
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            ),
        },
        circles: {
          if (riderShown != null)
            Circle(
              circleId: const CircleId('rider-halo'),
              center: riderShown,
              radius: 150,
              fillColor: AppColors.primary.withValues(alpha: 0.10),
              strokeColor: AppColors.primary.withValues(alpha: 0.25),
              strokeWidth: 1,
            ),
        },
        // La position du livreur est dessinée par notre marqueur moto,
        // pas par le point bleu de Google.
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        padding: EdgeInsets.only(
          bottom: showSheet ? screenHeight * sheetFraction : 24,
          top: _navigating ? 140 : 160,
        ),
        onMapCreated: _onMapCreated,
      );
    }

    return Stack(
      children: [
        // La moto glisse d'une position à la suivante, posée sur la route et
        // tournée dans le sens de la marche.
        if (riderPoint == null)
          buildMap(null)
        else
          TweenAnimationBuilder<LatLng>(
            tween: _LatLngTween(end: shownPoint!),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeInOut,
            builder: (context, shown, _) => TweenAnimationBuilder<double>(
              tween: _AngleTween(end: shownHeading),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOut,
              builder: (context, angle, _) => buildMap(shown, angle),
            ),
          ),

        // ---- Haut : titre, chrono, distance, bandeaux ----
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
              child: Column(
                children: [
                  if (_navigating && next != null)
                    _NavBanner(
                      route: route,
                      rider: riderPoint,
                      stop: next,
                      legMeters: legMeters,
                      legSeconds: legSeconds,
                      onQuit: _stopNavigation,
                    ),
                  if (!_navigating) ...[
                    Row(
                      children: [
                        if (!widget.embedded)
                          MapRoundButton(
                            icon: Icons.arrow_back_rounded,
                            tooltip: 'Retour',
                            onPressed: () => context.pop(),
                          )
                        else
                          const SizedBox(width: 48),
                        Expanded(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.94),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Text(
                                title,
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    gapH16,
                    ElapsedTimerPill(since: delivery.assignedAt),
                    if (legMeters != null) ...[
                      gapH12,
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.textPrimaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.navigation_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                            gapW8,
                            Text(
                              legSeconds == null
                                  ? 'À ${formatDistance(legMeters)}'
                                  : 'À ${formatDistance(legMeters)}'
                                        ' · ${formatDuration(legSeconds)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                  if (_simTimer != null) ...[
                    gapH8,
                    const Pill(
                      label: 'Déplacement simulé (test)',
                      foreground: AppColors.warning,
                      background: AppColors.warningLight,
                      icon: Icons.science_outlined,
                    ),
                  ] else if (fix.farAway) ...[
                    gapH8,
                    const Pill(
                      label: 'Position hors de Kinshasa',
                      foreground: AppColors.warning,
                      background: AppColors.warningLight,
                      icon: Icons.location_off_outlined,
                    ),
                  ],
                  if (access != null && access != LocationAccess.granted) ...[
                    gapH8,
                    LocationBanner(
                      access: access,
                      onAction: () => _fixLocation(access),
                    ),
                  ],
                  if (missingGps > 0) ...[
                    gapH8,
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
                                style: theme.textTheme.labelMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // ---- Boutons orange, au-dessus du panneau ----
        Positioned(
          right: Sizes.p12,
          bottom: (showSheet ? screenHeight * sheetFraction : 24) + Sizes.p12,
          child: Column(
            children: [
              MapRoundButton(
                icon: Icons.zoom_out_map_rounded,
                tooltip: "Vue d'ensemble",
                onPressed: _fitAll,
                filled: true,
              ),
              gapH8,
              MapRoundButton(
                icon: _satellite ? Icons.map_rounded : Icons.layers_rounded,
                tooltip: _satellite ? 'Plan' : 'Satellite',
                onPressed: () => setState(() => _satellite = !_satellite),
                filled: true,
              ),
              if (kDebugMode) ...[
                gapH8,
                MapRoundButton(
                  icon: _simTimer == null
                      ? Icons.play_arrow_rounded
                      : Icons.stop_rounded,
                  tooltip: _simTimer == null
                      ? 'Simuler un déplacement (test)'
                      : 'Arrêter la simulation',
                  onPressed: _toggleSimulation,
                  filled: true,
                ),
              ],
              gapH8,
              MapRoundButton(
                icon: Icons.my_location_rounded,
                tooltip: 'Ma position',
                onPressed: _centerOnRider,
                filled: true,
              ),
            ],
          ),
        ),

        // ---- Panneau du bas ----
        if (showSheet)
          StopsSheet(
            stops: stops,
            riderPoint: riderPoint,
            nextLegMeters: route?.firstLegMeters,
            nextLegSeconds: legSeconds,
            initialFraction: sheetFraction,
            busy: busy,
            onNavigate: _navigateTo,
            onFocus: (stop) {
              final position = stop.position;
              if (position != null) _focusOn(position);
            },
            onCollected: (stop) => _collect(delivery, stop),
            onUnavailable: (stop) => _markUnavailable(delivery, stop),
            onComplete: () => _complete(delivery),
          ),
      ],
    );
  }
}

/// Interpolation d'un cap par le plus court chemin (350° -> 10° passe par
/// 0°, sans refaire le tour).
class _AngleTween extends Tween<double> {
  _AngleTween({required double end}) : super(begin: end, end: end);

  @override
  double lerp(double t) {
    final a = begin!;
    final b = end!;
    final delta = ((b - a + 540) % 360) - 180;
    return a + delta * t;
  }
}

/// Interpolation d'une position : fait glisser la moto.
class _LatLngTween extends Tween<LatLng> {
  _LatLngTween({required LatLng end}) : super(begin: end, end: end);

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

/// Bandeau de navigation : prochaine manœuvre, rue, distance restante.
class _NavBanner extends StatelessWidget {
  const _NavBanner({
    required this.route,
    required this.rider,
    required this.stop,
    required this.legMeters,
    required this.legSeconds,
    required this.onQuit,
  });

  final RouteInfo? route;
  final LatLng? rider;
  final MapStop stop;
  final double? legMeters;
  final double? legSeconds;
  final VoidCallback onQuit;

  static IconData _iconOf(RouteStep step) {
    if (step.isArrive) return Icons.flag_rounded;
    if (step.type.contains('round')) return Icons.roundabout_left_rounded;
    final m = step.modifier;
    if (m == 'uturn') return Icons.u_turn_left_rounded;
    if (m.startsWith('slight')) {
      return m.contains('left')
          ? Icons.turn_slight_left_rounded
          : Icons.turn_slight_right_rounded;
    }
    if (m.contains('left')) return Icons.turn_left_rounded;
    if (m.contains('right')) return Icons.turn_right_rounded;
    return Icons.straight_rounded;
  }

  /// Première manœuvre encore devant nous (on ignore le départ et celles
  /// qu'on vient de passer).
  RouteStep? _nextStep() {
    final here = rider;
    for (final step in route?.firstLegSteps ?? const <RouteStep>[]) {
      if (step.isDepart) continue;
      if (here == null) return step;
      final d = Geolocator.distanceBetween(
        here.latitude,
        here.longitude,
        step.location.latitude,
        step.location.longitude,
      );
      if (d > 25 || step.isArrive) return step;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final here = rider;
    final target = stop.position;
    final toStop = (here != null && target != null)
        ? Geolocator.distanceBetween(
            here.latitude,
            here.longitude,
            target.latitude,
            target.longitude,
          )
        : null;
    final arrived = toStop != null && toStop <= StopsSheet.arrivalRadius;

    final step = arrived ? null : _nextStep();
    final distToStep = (step != null && here != null)
        ? Geolocator.distanceBetween(
            here.latitude,
            here.longitude,
            step.location.latitude,
            step.location.longitude,
          )
        : null;

    final String headline;
    final String? sub;
    final IconData icon;
    if (arrived) {
      icon = Icons.flag_rounded;
      headline = 'Vous êtes arrivé';
      sub = stop.isDealer ? stop.place.name : 'Chez ${stop.place.name}';
    } else if (step != null) {
      icon = _iconOf(step);
      headline = distToStep == null
          ? step.instruction
          : 'Dans ${formatDistance(distToStep)}';
      sub = distToStep == null
          ? (step.street.isEmpty ? null : step.street)
          : step.street.isEmpty
          ? step.instruction
          : '${step.instruction} · ${step.street}';
    } else {
      icon = Icons.straight_rounded;
      headline = 'Suivez le tracé';
      sub = 'Direction ${stop.place.name}';
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: Colors.white),
          gapW12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5),
                  ),
                if (legMeters != null) ...[
                  gapH4,
                  Text(
                    legSeconds == null
                        ? '${formatDistance(legMeters!)} restants'
                        : '${formatDistance(legMeters!)} · '
                              '${formatDuration(legSeconds!)} restants',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Quitter la navigation',
            onPressed: onQuit,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

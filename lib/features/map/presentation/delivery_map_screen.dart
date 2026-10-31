import 'package:dksoft_market_livreur/features/map/presentation/widgets/map_skeleton.dart';
import 'dart:ui' as ui;
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/core/widgets/toast.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';

import 'package:dksoft_market_livreur/core/data/livreur_repository.dart';
import 'package:dksoft_market_livreur/core/widgets/confirm_dialog.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/core/widgets/icon_tile.dart';
import 'package:dksoft_market_livreur/core/widgets/delivery_celebration.dart';
import 'package:dksoft_market_livreur/core/widgets/empty_state.dart';
import 'package:dksoft_market_livreur/features/deliveries/data/deliveries_repository.dart';
import 'package:dksoft_market_livreur/features/deliveries/domain/delivery_model.dart';
import 'package:dksoft_market_livreur/features/deliveries/presentation/delivery_action_controller.dart';
import 'package:dksoft_market_livreur/features/map/data/location_repository.dart';
import 'package:dksoft_market_livreur/features/map/presentation/map_camera.dart';
import 'package:dksoft_market_livreur/features/map/presentation/map_layers.dart';
import 'package:dksoft_market_livreur/features/map/presentation/map_stop.dart';
import 'package:dksoft_market_livreur/features/map/presentation/map_style.dart';
import 'package:dksoft_market_livreur/features/map/presentation/marker_icon_factory.dart';
import 'package:dksoft_market_livreur/features/map/presentation/moto_color.dart';
import 'package:dksoft_market_livreur/features/map/presentation/ride_simulator.dart';
import 'package:dksoft_market_livreur/features/map/presentation/rider_location.dart';
import 'package:dksoft_market_livreur/features/map/presentation/route_snap.dart';
import 'package:dksoft_market_livreur/features/map/presentation/widgets/delivery_map_header.dart';
import 'package:dksoft_market_livreur/features/map/presentation/widgets/map_round_button.dart';
import 'package:dksoft_market_livreur/features/map/presentation/widgets/nav_banner.dart';
import 'package:dksoft_market_livreur/features/map/presentation/widgets/stops_sheet.dart';
import 'package:dksoft_market_livreur/features/routing/data/routing_repository.dart';
import 'package:dksoft_market_livreur/features/routing/domain/route_info.dart';
import 'package:dksoft_market_livreur/features/shell/presentation/main_shell.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
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
  final _icons = MarkerIconFactory();
  final _ratio = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;

  GoogleMapController? _controller;
  Set<Marker> _markers = {};
  String? _signature;
  bool _hasFitted = false;

  /// Icône de la moto du livreur (dessinée au démarrage).
  BitmapDescriptor? _riderIcon;

  /// Fond satellite à la place du plan.
  bool _satellite = false;

  /// Dernière position du livreur retenue pour l'affichage.
  RiderFix _fix = RiderFix(null, RiderSource.none);

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

  late final RideSimulator _simulator;
  late final FullScreenMap _fullScreen;

  DeliveryModel? get _delivery =>
      ref.read(deliveryByIdProvider(widget.deliveryId)).value;

  MapStop? get _nextStop {
    final delivery = _delivery;
    if (delivery == null) return null;
    return MapStop.next(MapStop.fromDelivery(delivery));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fullScreen = ref.read(fullScreenMapProvider.notifier);

    _simulator = RideSimulator(
      routing: ref.read(routingRepositoryProvider),
      nextStop: () => _nextStop,
      onMove: (position) {
        if (!mounted) return;
        setState(() {});
        if (_navigating) _followRider(position);
      },
      onArrive: (stop) => _showMessage(
        stop.isDealer
            ? 'Arrivé chez le dealer (simulation).'
            : 'Arrivé chez ${stop.place.name} (simulation).',
      ),
      onFinished: () {
        if (mounted) setState(() {});
      },
    );

    // Moto de la couleur choisie par le livreur à l'inscription.
    ref.listenManual(currentLivreurProvider, (_, next) {
      _icons.buildRider(_ratio, color: motoColorOf(next.value?.motoColor)).then(
        (icon) {
          if (mounted) setState(() => _riderIcon = icon);
        },
      );
    }, fireImmediately: true);

    ref.listenManual<AsyncValue<Position>>(riderPositionProvider, (_, next) {
      final position = next.value;
      if (_navigating && position != null && !_simulator.isRunning) {
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
    _simulator.stop();
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

  Future<void> _syncMarkers(DeliveryModel? delivery) async {
    if (delivery == null) return;

    final allStops = MapStop.fromDelivery(delivery);
    final signature = allStops
        .map(
          (s) =>
              '${s.order}:${s.status?.name}:'
              '${s.place.latitude}:${s.place.longitude}',
        )
        .join('|');
    if (signature == _signature) return;
    _signature = signature;

    final nextStop = MapStop.next(allStops);
    final markers = <Marker>{};

    for (final stop in allStops) {
      final position = stop.position;
      if (position == null) continue;

      final isNext = identical(stop, nextStop);
      final (IconData? glyph, String? number) = stop.isDealer
          ? (Icons.flag_rounded, null)
          : switch (stop.status) {
              PickupStatus.collected => (Icons.check_rounded, null),
              PickupStatus.unavailable => (Icons.close_rounded, null),
              _ => (null, '${stop.order + 1}'),
            };

      final pin = await _icons.buildPin(
        icon: glyph,
        label: number,
        color: stop.color,
        pixelRatio: _ratio,
        width: isNext ? 44 : 34,
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
      await Future.delayed(Duration(milliseconds: 250));
      if (mounted) await _fitNext();
    }
  }

  void _loadEta(int minutes) {
    _etaMinutes = minutes;
    _icons.buildEta(minutes, _ratio).then((icon) {
      if (mounted) setState(() => _etaIcon = icon);
    });
  }

  // ---------------------------------------------------------------
  // Caméra
  // ---------------------------------------------------------------

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;

    // La carte n'a pas encore sa taille finale : on attend un instant
    // avant de cadrer, sinon Google Maps refuse l'ajustement.
    Future.delayed(Duration(milliseconds: 350), () {
      if (!mounted || _hasFitted || _markers.isEmpty) return;
      _hasFitted = true;
      _fitNext();
    });
  }

  /// Cadre le livreur et son prochain arrêt : assez près pour lire les rues.
  Future<void> _fitNext() async {
    final target = _nextStop?.position;
    if (target == null) return;
    await fitPoints(_controller, [?_fix.point, target], padding: 90);
  }

  /// Vue d'ensemble : tout le trajet restant.
  Future<void> _fitAll() async {
    final delivery = _delivery;
    if (delivery == null) return;

    final route = _lastRoute;
    await fitPoints(_controller, [
      if (route != null)
        ...route.points
      else
        for (final stop in MapStop.fromDelivery(delivery))
          if (stop.isPending) ?stop.position,
      ?_fix.point,
    ], padding: 90);
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
    await (_navigating ? _animateFollow(point) : _focusOn(point));
  }

  Future<void> _followRider(Position position) async {
    // On ne garde le cap que si le livreur roule : à l'arrêt, le GPS donne
    // un cap aléatoire qui ferait tourner la carte.
    if (position.speed > 1.5 && position.heading >= 0) {
      _bearing = position.heading;
    }
    if (_fix.point == null) return;
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

  // ---------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------

  /// Lance la navigation dans l'application : on reste sur la carte, le
  /// tracé suit les rues et la caméra accompagne le livreur.
  Future<void> _navigateTo(MapStop stop) async {
    final point = _fix.point;
    if (point == null) {
      _showMessage(
        'Position introuvable : activez la localisation pour naviguer.',
      );
      return;
    }
    setState(() => _navigating = true);
    _fullScreen.set(true);
    await _animateFollow(point);
  }

  Future<void> _stopNavigation() async {
    setState(() => _navigating = false);
    _fullScreen.set(false);
    await _fitNext();
  }

  void _toggleSimulation() {
    if (_simulator.isRunning) {
      setState(_simulator.stop);
      return;
    }

    final target = _nextStop?.position;
    final start =
        _fix.point ??
        (target == null
            ? null
            : LatLng(target.latitude + 0.007, target.longitude - 0.006));
    if (start == null) {
      _showMessage('Aucun arrêt avec position GPS pour simuler.');
      return;
    }
    setState(() => _simulator.start(start));
  }

  /// Message d'erreur de la dernière action (course déjà modifiée, hors
  /// connexion…).
  void _showActionError() {
    final error = ref.read(deliveryActionControllerProvider).error;
    if (!mounted) return;
    Toast.error(context, error?.toString() ?? 'Action impossible.');
  }

  Future<void> _collect(DeliveryModel delivery, MapStop stop) async {
    final ok = await ref
        .read(deliveryActionControllerProvider.notifier)
        .markPickup(delivery.id, stop.order);
    if (!ok) return _showActionError();
    _showMessage('Récupéré chez ${stop.place.name}.');
  }

  Future<void> _markUnavailable(DeliveryModel delivery, MapStop stop) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Article indisponible ?',
      message:
          'Rupture de stock, commerçant fermé ou introuvable : '
          '${stop.place.name} sera marqué comme non récupéré.',
      confirmLabel: 'Confirmer',
      icon: AppIcons.cartRemove,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    final ok = await ref
        .read(deliveryActionControllerProvider.notifier)
        .markPickup(delivery.id, stop.order, status: PickupStatus.unavailable);
    if (!ok) _showActionError();
  }

  Future<void> _complete(DeliveryModel delivery) async {
    // La carte disparaît dès que la course est terminée : on garde le
    // navigateur et le gain pour pouvoir fêter la fin malgré tout.
    final navigator = Navigator.of(context, rootNavigator: true);
    final fee = delivery.deliveryFee;

    final ok = await ref
        .read(deliveryActionControllerProvider.notifier)
        .complete(delivery.id);
    if (ok) showDeliveryCelebration(navigator, amount: fee);
    if (!mounted) return;
    if (!ok) return _showActionError();

    _simulator.stop();
    _navigating = false;
    _fullScreen.set(false);
    // Ouverte depuis l'écran de détail : on revient en arrière. Dans
    // l'onglet, la carte repasse seule aux demandes (plus de course active).
    if (!widget.embedded && context.canPop()) context.pop();
  }

  /// Impossible de remettre le colis : le motard choisit le motif,
  /// confirme, et la course se termine sur cet incident.
  Future<void> _reportIncident(DeliveryModel delivery) async {
    final incident = await showModalBottomSheet<DeliveryStatus>(
      context: context,
      builder: (context) => _IncidentSheet(),
    );
    if (incident == null || !mounted) return;

    final confirmed = await showConfirmDialog(
      context,
      title: '${incident.label} ?',
      message:
          "La course s'arrête ici et l'administration Dksoft Market vous "
          'contactera pour la suite du colis.',
      confirmLabel: 'Signaler',
      icon: AppIcons.alert,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    final ok = await ref
        .read(deliveryActionControllerProvider.notifier)
        .reportIncident(delivery.id, incident);
    if (!mounted) return;
    if (!ok) return _showActionError();

    _simulator.stop();
    _navigating = false;
    _fullScreen.set(false);
    _showMessage("Incident signalé. L'administration va vous contacter.");
    if (!widget.embedded && context.canPop()) context.pop();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    Toast.info(context, message);
  }

  // ---------------------------------------------------------------
  // Interface
  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final deliveryAsync = ref.watch(deliveryByIdProvider(widget.deliveryId));

    return Scaffold(
      body: deliveryAsync.when(
        loading: () => const MapSkeleton(),
        error: (_, _) => EmptyState(
          icon: AppIcons.offline,
          title: 'Impossible de charger la course',
          message: 'Vérifiez votre connexion internet.',
        ),
        data: (delivery) => delivery == null
            ? const EmptyState(
                icon: AppIcons.searchOff,
                title: "Cette course n'existe plus",
                message: "Elle a peut-être été annulée par l'administration.",
              )
            : _buildMap(context, delivery),
      ),
    );
  }

  Widget _buildMap(BuildContext context, DeliveryModel delivery) {
    final access = ref.watch(locationAccessProvider).value;
    final realRider = ref.watch(riderPositionProvider).value;
    final rawRider = _simulator.position ?? realRider;
    final busy = ref.watch(deliveryActionControllerProvider).isLoading;

    final stops = MapStop.fromDelivery(delivery);
    final next = MapStop.next(stops);
    final pendingPoints = <LatLng>[
      for (final stop in stops)
        if (stop.isPending) ?stop.position,
    ];

    final fix = resolveRider(
      rawRider,
      pendingPoints.isEmpty ? null : pendingPoints.first,
    );
    _fix = fix;
    final riderPoint = fix.point;

    // Itinéraire routier : du livreur jusqu'au dernier arrêt restant.
    final waypoints = <LatLng>[?riderPoint, ...pendingPoints];
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
    // Dans l'onglet Carte, la barre de navigation flotte sur le panneau.
    final navInset = MediaQuery.paddingOf(context).bottom;
    final sheetFraction = ((350 + navInset) / screenHeight).clamp(0.34, 0.75);
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
    final bottomInset = showSheet ? screenHeight * sheetFraction : 24.0;

    final title = next == null
        ? 'Course terminée'
        : next.isDealer
        ? 'En route vers le dealer'
        : 'Collecte · ${next.place.name}';

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
        style: _satellite ? null : mapStyleFor(context.isDark),
        buildingsEnabled: true,
        compassEnabled: false,
        initialCameraPosition: CameraPosition(
          target: nextPosition ?? kKinshasaCenter,
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
        polylines: routePolylines(route, waypoints),
        circles: riderHalo(riderShown),
        // La position du livreur est dessinée par notre marqueur moto,
        // pas par le point bleu de Google.
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        padding: EdgeInsets.only(
          bottom: bottomInset,
          top: _navigating ? 140 : 120,
        ),
        onMapCreated: _onMapCreated,
      );
    }

    return Stack(
      children: [
        // La moto glisse d'une position à la suivante, posée sur la route et
        // tournée dans le sens de la marche.
        if (shownPoint == null)
          buildMap(null)
        else
          TweenAnimationBuilder<LatLng>(
            tween: LatLngTween(end: shownPoint),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeInOut,
            builder: (context, shown, _) => TweenAnimationBuilder<double>(
              tween: AngleTween(end: shownHeading),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOut,
              builder: (context, angle, _) => buildMap(shown, angle),
            ),
          ),

        // ---- Haut : navigation, ou étape + chrono + avertissements ----
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
              child: _navigating && next != null
                  ? NavBanner(
                      route: route,
                      rider: riderPoint,
                      stop: next,
                      legMeters: legMeters,
                      legSeconds: legSeconds,
                      onQuit: _stopNavigation,
                    )
                  : DeliveryMapHeader(
                      title: title,
                      assignedAt: delivery.assignedAt,
                      legMeters: legMeters,
                      legSeconds: legSeconds,
                      onBack: widget.embedded ? null : () => context.pop(),
                      simulating: _simulator.isRunning,
                      farAway: fix.farAway,
                      access: access,
                      onFixLocation: () {
                        if (access != null) fixLocationAccess(ref, access);
                      },
                      missingGps: missingGps,
                    ),
            ),
          ),
        ),

        // ---- Boutons de carte, au-dessus du panneau ----
        Positioned(
          right: Sizes.p12,
          bottom: bottomInset + Sizes.p12,
          child: MapControlGroup(
            controls: [
              MapControl(
                icon: AppIcons.fitAll,
                tooltip: "Vue d'ensemble",
                onPressed: _fitAll,
              ),
              MapControl(
                icon: AppIcons.layers,
                tooltip: _satellite ? 'Plan' : 'Satellite',
                active: _satellite,
                onPressed: () => setState(() => _satellite = !_satellite),
              ),
              if (kDebugMode)
                MapControl(
                  icon: _simulator.isRunning ? AppIcons.stop : AppIcons.play,
                  tooltip: _simulator.isRunning
                      ? 'Arrêter la simulation'
                      : 'Simuler un déplacement (test)',
                  active: _simulator.isRunning,
                  onPressed: _toggleSimulation,
                ),
              MapControl(
                icon: AppIcons.myLocation,
                tooltip: 'Ma position',
                onPressed: _centerOnRider,
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
            onIncident: () => _reportIncident(delivery),
            bottomInset: navInset,
          ),
      ],
    );
  }
}

/// Choix du motif d'incident chez le dealer.
class _IncidentSheet extends StatelessWidget {
  const _IncidentSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget option(
      DeliveryStatus incident,
      AppIconData icon,
      String description,
    ) {
      return ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Sizes.p12,
          vertical: Sizes.p4,
        ),
        leading: IconTile(icon: icon, color: AppColors.error),
        title: Text(incident.label, style: theme.textTheme.titleSmall),
        subtitle: Text(description, style: theme.textTheme.bodySmall),
        onTap: () => Navigator.of(context).pop(incident),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Sizes.p12, 0, Sizes.p12, Sizes.p16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Sizes.p12,
                0,
                Sizes.p12,
                Sizes.p8,
              ),
              child: Text(
                'Quel est le problème ?',
                style: theme.textTheme.titleLarge,
              ),
            ),
            option(
              DeliveryStatus.dealerAbsent,
              AppIcons.userOff,
              "Personne pour recevoir le colis à l'adresse.",
            ),
            option(
              DeliveryStatus.wrongAddress,
              AppIcons.locationOff,
              "L'adresse n'existe pas ou ne correspond pas au dealer.",
            ),
          ],
        ),
      ),
    );
  }
}

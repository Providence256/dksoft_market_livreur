import 'dart:ui' as ui;
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/core/widgets/toast.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';

import 'package:dksoft_market_livreur/core/data/livreur_repository.dart';
import 'package:dksoft_market_livreur/features/deliveries/data/deliveries_repository.dart';
import 'package:dksoft_market_livreur/features/deliveries/domain/delivery_model.dart';
import 'package:dksoft_market_livreur/features/map/data/location_repository.dart';
import 'package:dksoft_market_livreur/features/map/presentation/delivery_map_screen.dart';
import 'package:dksoft_market_livreur/features/map/presentation/map_camera.dart';
import 'package:dksoft_market_livreur/features/map/presentation/map_layers.dart';
import 'package:dksoft_market_livreur/features/map/presentation/map_style.dart';
import 'package:dksoft_market_livreur/features/map/presentation/marker_icon_factory.dart';
import 'package:dksoft_market_livreur/features/map/presentation/moto_color.dart';
import 'package:dksoft_market_livreur/features/map/presentation/rider_location.dart';
import 'package:dksoft_market_livreur/features/map/presentation/widgets/location_banner.dart';
import 'package:dksoft_market_livreur/features/map/presentation/widgets/map_round_button.dart';
import 'package:dksoft_market_livreur/features/map/presentation/widgets/overview_cards.dart';
import 'package:dksoft_market_livreur/features/shell/presentation/main_shell.dart';
import 'package:dksoft_market_livreur/routing/app_router.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Onglet « Carte » : toutes les courses disponibles d'un coup d'œil.
///
/// Chaque course est dessinée par ses arrêts numérotés ; en haut une barre
/// flottante (état + profil), en bas un panneau déplaçable avec le
/// carrousel des courses. Quand une course est en cours, l'onglet affiche à
/// la place la carte de cette course.
class OverviewMapScreen extends ConsumerStatefulWidget {
  const OverviewMapScreen({super.key});

  @override
  ConsumerState<OverviewMapScreen> createState() => _OverviewMapScreenState();
}

class _OverviewMapScreenState extends ConsumerState<OverviewMapScreen>
    with WidgetsBindingObserver {
  static const _carouselHeight = 196.0;

  /// Hauteur visible du panneau (titre + carrousel), sans la barre de
  /// navigation qui flotte par-dessus.
  static const _sheetContent = 300.0;

  final _icons = MarkerIconFactory();
  final _ratio = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
  final _pageController = PageController(viewportFraction: 0.88);

  GoogleMapController? _map;
  Set<Marker> _markers = const {};
  List<DeliveryModel> _deliveries = const [];

  String? _selectedId;
  String? _signature;
  bool _hasFitted = false;
  bool _riderCentered = false;

  /// Position du livreur retenue pour l'affichage (voir [resolveRider]).
  RiderFix _fix = const RiderFix(null, RiderSource.none);
  BitmapDescriptor? _riderIcon;
  bool _satellite = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Moto de la couleur choisie par le livreur à l'inscription.
    ref.listenManual(currentLivreurProvider, (_, next) {
      _icons.buildRider(_ratio, color: motoColorOf(next.value?.motoColor)).then(
        (icon) {
          if (mounted) setState(() => _riderIcon = icon);
        },
      );
    }, fireImmediately: true);

    // Pas encore de course à cadrer : on se centre sur le livreur dès que
    // sa position arrive.
    ref.listenManual<AsyncValue<Position>>(riderPositionProvider, (_, next) {
      final fix = resolveRider(next.value, kKinshasaCenter);
      final point = fix.point;
      if (point == null || fix.source != RiderSource.real) return;
      if (_riderCentered || _hasFitted) return;
      _riderCentered = true;
      _map
          ?.animateCamera(CameraUpdate.newLatLngZoom(point, 15))
          .catchError((Object _) {});
    });

    ref.listenManual<AsyncValue<List<DeliveryModel>>>(
      availableDeliveriesProvider,
      (_, next) {
        final list = next.value;
        if (list != null) _onDeliveries(list);
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    _map?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(locationAccessProvider.notifier).recheck(request: false);
    }
  }

  // ---------------------------------------------------------------
  // Données -> marqueurs
  // ---------------------------------------------------------------

  DeliveryModel? get _selected {
    for (final d in _deliveries) {
      if (d.id == _selectedId) return d;
    }
    return null;
  }

  void _onDeliveries(List<DeliveryModel> list) {
    _deliveries = list;
    if (list.isEmpty) {
      _selectedId = null;
    } else if (!list.any((d) => d.id == _selectedId)) {
      _selectedId = list.first.id;
    }

    if (mounted) setState(() {});
    _rebuildMarkers();
    _fitFirstTime();
  }

  Future<void> _rebuildMarkers() async {
    final signature =
        '$_selectedId|'
        '${_deliveries.map((d) => '${d.id}:${d.pickups.length}').join(',')}';
    if (signature == _signature) return;
    _signature = signature;

    final markers = <Marker>{};

    for (final delivery in _deliveries) {
      final selected = delivery.id == _selectedId;

      for (final (index, pickup) in delivery.pickups.indexed) {
        final place = pickup.place;
        if (!place.hasCoordinates) continue;

        final pin = await _icons.buildPin(
          label: '${index + 1}',
          color: selected ? AppColors.secondary : AppColors.secondaryLight,
          pixelRatio: _ratio,
          width: selected ? 40 : 30,
        );
        markers.add(
          Marker(
            markerId: MarkerId('${delivery.id}-p$index'),
            position: LatLng(place.latitude!, place.longitude!),
            icon: pin,
            anchor: kPinAnchor,
            zIndexInt: selected ? 4 : 2,
            infoWindow: InfoWindow(title: place.name, snippet: place.commune),
            onTap: () => _select(delivery.id),
          ),
        );
      }

      final dealer = delivery.dropoff;
      if (dealer.hasCoordinates) {
        final pin = await _icons.buildPin(
          icon: Icons.flag_rounded,
          color: selected ? AppColors.primary : AppColors.primaryLight,
          pixelRatio: _ratio,
          width: selected ? 40 : 30,
        );
        markers.add(
          Marker(
            markerId: MarkerId('${delivery.id}-dealer'),
            position: LatLng(dealer.latitude!, dealer.longitude!),
            icon: pin,
            anchor: kPinAnchor,
            zIndexInt: selected ? 4 : 2,
            infoWindow: InfoWindow(
              title: dealer.name,
              snippet: 'Dealer · ${dealer.commune}',
            ),
            onTap: () => _select(delivery.id),
          ),
        );
      }
    }

    if (!mounted) return;
    setState(() => _markers = markers);
  }

  // ---------------------------------------------------------------
  // Sélection et caméra
  // ---------------------------------------------------------------

  void _select(String id, {bool movePage = true}) {
    if (_selectedId == id) return;
    setState(() => _selectedId = id);
    _rebuildMarkers();

    final selected = _selected;
    if (selected != null) fitPoints(_map, deliveryPoints(selected));

    if (movePage && _pageController.hasClients) {
      final index = _deliveries.indexWhere((d) => d.id == id);
      if (index >= 0) {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _map = controller;
    Future.delayed(const Duration(milliseconds: 350), _fitFirstTime);
  }

  /// Au premier affichage : cadre la course sélectionnée et le livreur.
  void _fitFirstTime() {
    if (_hasFitted || _map == null) return;
    final selected = _selected;
    if (selected == null) return;
    final points = deliveryPoints(selected);
    if (points.isEmpty) return;
    _hasFitted = true;
    fitPoints(_map, [...points, ?_fix.point]);
  }

  void _fitEverything() {
    fitPoints(_map, [
      for (final d in _deliveries) ...deliveryPoints(d),
      ?_fix.point,
    ]);
  }

  Future<void> _centerOnRider() async {
    final point = _fix.point;
    if (point == null) {
      _toast("Votre position n'est pas encore disponible.");
      return;
    }
    try {
      await _map?.animateCamera(CameraUpdate.newLatLngZoom(point, 16));
    } catch (_) {}
  }

  void _toast(String message) {
    if (!mounted) return;
    Toast.info(context, message);
  }

  double? _distanceToStart(DeliveryModel delivery, LatLng? rider) {
    if (rider == null) return null;
    for (final p in delivery.pickups) {
      if (p.place.hasCoordinates) {
        return Geolocator.distanceBetween(
          rider.latitude,
          rider.longitude,
          p.place.latitude!,
          p.place.longitude!,
        );
      }
    }
    return null;
  }

  // ---------------------------------------------------------------
  // Interface
  // ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final livreur = ref.watch(currentLivreurProvider).value;
    final activeId = livreur?.activeDeliveryId;

    // Course en cours : l'onglet devient la carte de cette course.
    if (activeId != null) {
      return DeliveryMapScreen(deliveryId: activeId, embedded: true);
    }

    final disponible = livreur?.disponible ?? false;
    final access = ref.watch(locationAccessProvider).value;
    final selected = _selected;
    final selectedPoints = selected == null
        ? const <LatLng>[]
        : deliveryPoints(selected);
    final position = ref.watch(riderPositionProvider).value;
    final fix = resolveRider(
      position,
      selectedPoints.isEmpty ? kKinshasaCenter : selectedPoints.first,
    );
    _fix = fix;
    final rider = fix.point;
    final deliveries = disponible ? _deliveries : const <DeliveryModel>[];
    final screenHeight = MediaQuery.sizeOf(context).height;
    final navInset = MediaQuery.paddingOf(context).bottom;
    final sheetInitial = ((_sheetContent + navInset) / screenHeight).clamp(
      0.3,
      0.6,
    );
    final sheetMin = ((90 + navInset) / screenHeight).clamp(0.1, 0.3);

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: _satellite ? MapType.hybrid : MapType.normal,
            style: _satellite ? null : mapStyleFor(context.isDark),
            buildingsEnabled: true,
            compassEnabled: false,
            initialCameraPosition: const CameraPosition(
              target: kKinshasaCenter,
              zoom: 13,
            ),
            markers: {
              if (disponible) ..._markers,
              if (rider != null && _riderIcon != null)
                Marker(
                  markerId: const MarkerId('rider'),
                  position: rider,
                  icon: _riderIcon!,
                  anchor: const Offset(0.5, 0.5),
                  flat: true,
                  rotation: riderHeadingOf(position) ?? 0,
                  zIndexInt: 10,
                  infoWindow: const InfoWindow(title: 'Vous êtes ici'),
                ),
            },
            circles: riderHalo(rider, radius: 160),
            polylines: disponible ? routePolylines(null, selectedPoints) : {},
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            padding: EdgeInsets.only(
              bottom: screenHeight * sheetInitial,
              top: 100,
            ),
            onMapCreated: _onMapCreated,
          ),

          // ---- Haut : barre d'état + boutons de carte ----
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
                  crossAxisAlignment: CrossAxisAlignment.end,
                  spacing: Sizes.p8,
                  children: [
                    OverviewTopBar(
                      disponible: disponible,
                      count: deliveries.length,
                      name: livreur?.fullName ?? '',
                      onProfile: () => ref
                          .read(shellIndexProvider.notifier)
                          .select(kTabProfile),
                    ),
                    if (access != null && access != LocationAccess.granted)
                      LocationBanner(
                        access: access,
                        onAction: () => fixLocationAccess(ref, access),
                      ),
                    gapH4,
                    MapControlGroup(
                      controls: [
                        MapControl(
                          icon: AppIcons.fitAll,
                          tooltip: "Vue d'ensemble",
                          onPressed: _fitEverything,
                        ),
                        MapControl(
                          icon: AppIcons.layers,
                          tooltip: _satellite ? 'Plan' : 'Satellite',
                          active: _satellite,
                          onPressed: () =>
                              setState(() => _satellite = !_satellite),
                        ),
                        MapControl(
                          icon: AppIcons.myLocation,
                          tooltip: 'Ma position',
                          onPressed: _centerOnRider,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ---- Panneau déplaçable : courses autour de vous ----
          DraggableScrollableSheet(
            initialChildSize: sheetInitial,
            minChildSize: sheetMin,
            maxChildSize: 0.7,
            snap: true,
            snapSizes: [sheetMin, sheetInitial, 0.7],
            builder: (context, scrollController) => _CoursesSheet(
              scrollController: scrollController,
              disponible: disponible,
              count: deliveries.length,
              onRefresh: () {
                ref.invalidate(availableDeliveriesProvider);
                _toast('Courses actualisées');
              },
              carousel: SizedBox(
                height: _carouselHeight,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: deliveries.length,
                  onPageChanged: (index) =>
                      _select(deliveries[index].id, movePage: false),
                  itemBuilder: (context, index) {
                    final delivery = deliveries[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: MapDeliveryCard(
                        delivery: delivery,
                        selected: delivery.id == _selectedId,
                        distance: _distanceToStart(delivery, rider),
                        onOpen: () => context.pushNamed(
                          AppRoute.delivery.name,
                          pathParameters: {'id': delivery.id},
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Contenu du panneau du bas : titre, bouton d'actualisation, puis le
/// carrousel (ou un message quand il n'y a rien à montrer).
class _CoursesSheet extends StatelessWidget {
  const _CoursesSheet({
    required this.scrollController,
    required this.disponible,
    required this.count,
    required this.onRefresh,
    required this.carousel,
  });

  final ScrollController scrollController;
  final bool disponible;
  final int count;
  final VoidCallback onRefresh;
  final Widget carousel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.xl)),
        boxShadow: AppShadows.sheet,
      ),
      child: ListView(
        controller: scrollController,
        padding: EdgeInsets.only(
          bottom: MediaQuery.paddingOf(context).bottom + Sizes.p16,
        ),
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.palette.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Sizes.screenPadding, 0, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Courses autour de vous',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Actualiser',
                  onPressed: onRefresh,
                  icon: const AppIcon(AppIcons.refresh),
                ),
              ],
            ),
          ),
          gapH8,
          if (!disponible)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: Sizes.screenPadding),
              child: UnavailableCard(),
            )
          else if (count == 0)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: Sizes.screenPadding),
              child: NoDeliveryCard(),
            )
          else
            carousel,
        ],
      ),
    );
  }
}

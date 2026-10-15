import 'dart:ui' as ui;

import 'package:dksoft_market_livreur/core/data/livreur_repository.dart';
import 'package:dksoft_market_livreur/core/widgets/app_card.dart';
import 'package:dksoft_market_livreur/core/widgets/pill.dart';
import 'package:dksoft_market_livreur/features/dashboard/presentation/availability_controller.dart';
import 'package:dksoft_market_livreur/features/dashboard/presentation/dashboard_screen.dart';
import 'package:dksoft_market_livreur/features/deliveries/data/deliveries_repository.dart';
import 'package:dksoft_market_livreur/features/deliveries/domain/delivery_model.dart';
import 'package:dksoft_market_livreur/features/map/data/location_repository.dart';
import 'package:dksoft_market_livreur/features/map/presentation/delivery_map_screen.dart';
import 'package:dksoft_market_livreur/features/map/presentation/map_camera.dart';
import 'package:dksoft_market_livreur/features/map/presentation/marker_icon_factory.dart';
import 'package:dksoft_market_livreur/features/map/presentation/rider_location.dart';
import 'package:dksoft_market_livreur/features/map/presentation/moto_color.dart';
import 'package:dksoft_market_livreur/features/map/presentation/widgets/location_banner.dart';
import 'package:dksoft_market_livreur/features/map/presentation/widgets/map_round_button.dart';
import 'package:dksoft_market_livreur/features/shell/presentation/main_shell.dart';
import 'package:dksoft_market_livreur/routing/app_router.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/formatters/currency_formatter.dart';
import 'package:dksoft_market_livreur/utils/helpers/distance_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Onglet « Carte » : toutes les courses disponibles d'un coup d'œil.
///
/// Carte claire avec les noms de rues, quartiers et communes ; chaque
/// course est une pastille de prix. En haut, une carte flottante (recherche
/// + filtre + profil) ; en bas, un panneau déplaçable avec les courses.
/// Quand une course est en cours, l'onglet affiche à la place la carte de
/// cette course.
class OverviewMapScreen extends ConsumerStatefulWidget {
  const OverviewMapScreen({super.key});

  @override
  ConsumerState<OverviewMapScreen> createState() => _OverviewMapScreenState();
}

class _OverviewMapScreenState extends ConsumerState<OverviewMapScreen>
    with WidgetsBindingObserver {
  static const _kinshasa = LatLng(-4.325, 15.322);
  static const _carouselHeight = 188.0;
  static const _sheetInitial = 0.40;
  static const _sheetMin = 0.13;
  static const _sheetMax = 0.62;

  final _icons = MarkerIconFactory();
  final _pageController = PageController(viewportFraction: 0.86);

  GoogleMapController? _map;
  Set<Marker> _markers = const {};

  /// Toutes les courses reçues, puis celles qui passent la recherche et
  /// les filtres.
  List<DeliveryModel> _all = const [];
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

    final ratio = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    // Moto de la couleur choisie par le livreur à l'inscription.
    ref.listenManual(currentLivreurProvider, (_, next) {
      _icons.buildRider(ratio, color: motoColorOf(next.value?.motoColor)).then((
        icon,
      ) {
        if (mounted) setState(() => _riderIcon = icon);
      });
    }, fireImmediately: true);

    // Pas encore de course à cadrer : on se centre sur le livreur dès que
    // sa position arrive.
    ref.listenManual<AsyncValue<Position>>(riderPositionProvider, (_, next) {
      final fix = resolveRider(next.value, _kinshasa);
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
        if (list != null) {
          _all = list;
          _applyFilters();
        }
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
  // Données -> filtres -> marqueurs
  // ---------------------------------------------------------------

  DeliveryModel? get _selected {
    for (final d in _deliveries) {
      if (d.id == _selectedId) return d;
    }
    return null;
  }

  List<LatLng> _pointsOf(DeliveryModel delivery) {
    return [
      for (final p in delivery.pickups)
        if (p.place.hasCoordinates)
          LatLng(p.place.latitude!, p.place.longitude!),
      if (delivery.dropoff.hasCoordinates)
        LatLng(delivery.dropoff.latitude!, delivery.dropoff.longitude!),
    ];
  }

  void _applyFilters() {
    final list = _all;
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
        '$_selectedId|${_deliveries.map((d) => '${d.id}:${d.pickups.length}').join(',')}';
    if (signature == _signature) return;
    _signature = signature;

    final ratio = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    final markers = <Marker>{};

    for (final delivery in _deliveries) {
      final selected = delivery.id == _selectedId;

      for (final (index, pickup) in delivery.pickups.indexed) {
        final place = pickup.place;
        if (!place.hasCoordinates) continue;

        final pin = await _icons.buildPin(
          label: '${index + 1}',
          color: selected ? AppColors.secondary : AppColors.secondaryLight,
          pixelRatio: ratio,
          width: selected ? 40 : 32,
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
          pixelRatio: ratio,
          width: selected ? 40 : 32,
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
    if (selected != null) fitPoints(_map, _pointsOf(selected));

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
    if (_hasFitted || _map == null || _deliveries.isEmpty) return;
    final selected = _selected;
    if (selected == null) return;
    final points = _pointsOf(selected);
    if (points.isEmpty) return;
    _hasFitted = true;
    final rider = _fix.point;
    fitPoints(_map, [...points, if (rider != null) rider]);
  }

  void _fitEverything() {
    final points = <LatLng>[for (final d in _deliveries) ..._pointsOf(d)];
    final point = _fix.point;
    if (point != null) points.add(point);
    fitPoints(_map, points);
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

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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

  void _refresh() {
    ref.invalidate(availableDeliveriesProvider);
    _toast('Courses actualisées');
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
    final selectedPoints = _selected == null
        ? const <LatLng>[]
        : _pointsOf(_selected!);
    final fix = resolveRider(
      ref.watch(riderPositionProvider).value,
      selectedPoints.isEmpty ? _kinshasa : selectedPoints.first,
    );
    _fix = fix;
    final rider = fix.point;
    final deliveries = disponible ? _deliveries : const <DeliveryModel>[];
    final selected = _selected;
    final screenHeight = MediaQuery.sizeOf(context).height;

    final polylines = <Polyline>{};
    if (disponible && selected != null) {
      final pts = _pointsOf(selected);
      if (pts.length >= 2) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('selected'),
            points: pts,
            width: 4,
            color: AppColors.primary.withValues(alpha: 0.8),
          ),
        );
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: _satellite ? MapType.hybrid : MapType.normal,
            trafficEnabled: false,
            buildingsEnabled: true,
            compassEnabled: false,
            initialCameraPosition: const CameraPosition(
              target: _kinshasa,
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
                  rotation:
                      riderHeadingOf(ref.watch(riderPositionProvider).value) ??
                      0,
                  zIndexInt: 10,
                  infoWindow: const InfoWindow(title: 'Vous êtes ici'),
                ),
            },
            circles: {
              if (rider != null)
                Circle(
                  circleId: const CircleId('rider-halo'),
                  center: rider,
                  radius: 160,
                  fillColor: AppColors.primary.withValues(alpha: 0.10),
                  strokeColor: AppColors.primary.withValues(alpha: 0.25),
                  strokeWidth: 1,
                ),
            },
            polylines: polylines,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            padding: EdgeInsets.only(
              bottom: screenHeight * _sheetInitial,
              top: 100,
            ),
            onMapCreated: _onMapCreated,
          ),

          // ---- Carte flottante : logo, recherche, filtre, profil ----
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
                  children: [
                    _TopCard(
                      disponible: disponible,
                      count: deliveries.length,
                      initials: initialsOf(livreur?.fullName ?? ''),
                      onProfile: () => ref
                          .read(shellIndexProvider.notifier)
                          .select(kTabProfile),
                    ),
                    if (access != null && access != LocationAccess.granted) ...[
                      gapH8,
                      LocationBanner(
                        access: access,
                        onAction: () => _fixLocation(access),
                      ),
                    ],
                    gapH12,
                    MapRoundButton(
                      icon: Icons.zoom_out_map_rounded,
                      tooltip: "Vue d'ensemble",
                      onPressed: _fitEverything,
                    ),
                    gapH8,
                    MapRoundButton(
                      icon: _satellite
                          ? Icons.map_rounded
                          : Icons.layers_rounded,
                      tooltip: _satellite ? 'Plan' : 'Satellite',
                      onPressed: () => setState(() => _satellite = !_satellite),
                    ),
                    gapH8,
                    MapRoundButton(
                      icon: Icons.my_location_rounded,
                      tooltip: 'Ma position',
                      onPressed: _centerOnRider,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ---- Panneau déplaçable : courses autour de vous ----
          DraggableScrollableSheet(
            initialChildSize: _sheetInitial,
            minChildSize: _sheetMin,
            maxChildSize: _sheetMax,
            snap: true,
            snapSizes: const [_sheetMin, _sheetInitial, _sheetMax],
            builder: (context, scrollController) {
              final theme = Theme.of(context);
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x26000000),
                      blurRadius: 18,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: Sizes.p16),
                  children: [
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.dividerLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Sizes.p16,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              !disponible
                                  ? 'Vous êtes indisponible'
                                  : 'Courses autour de vous'
                                        '${deliveries.isEmpty ? '' : ' (${deliveries.length})'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _refresh,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('Actualiser'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.secondary,
                              textStyle: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    gapH8,
                    if (!disponible)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: Sizes.p16),
                        child: _UnavailableCard(),
                      )
                    else if (deliveries.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: Sizes.p16),
                        child: _NoDeliveryCard(),
                      )
                    else
                      SizedBox(
                        height: _carouselHeight,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: deliveries.length,
                          onPageChanged: (index) =>
                              _select(deliveries[index].id, movePage: false),
                          itemBuilder: (context, index) {
                            final delivery = deliveries[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: _MapDeliveryCard(
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
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Carte flottante du haut : logo, état des courses, profil.
class _TopCard extends StatelessWidget {
  const _TopCard({
    required this.disponible,
    required this.count,
    required this.initials,
    required this.onProfile,
  });

  final bool disponible;
  final int count;
  final String initials;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.two_wheeler_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          gapW12,
          Expanded(
            child: Text(
              !disponible
                  ? 'Vous êtes indisponible'
                  : count == 0
                  ? 'Aucune course pour le moment'
                  : '$count course${count > 1 ? 's' : ''} disponible'
                        '${count > 1 ? 's' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          gapW8,
          InkWell(
            onTap: onProfile,
            customBorder: const CircleBorder(),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.secondary,
              child: Text(
                initials.isEmpty ? '?' : initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapDeliveryCard extends StatelessWidget {
  const _MapDeliveryCard({
    required this.delivery,
    required this.selected,
    required this.distance,
    required this.onOpen,
  });

  final DeliveryModel delivery;
  final bool selected;
  final double? distance;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = delivery.pickups.length;
    final route = [
      ...delivery.pickups.map((p) => p.place.name),
      delivery.dropoff.name,
    ].join('  →  ');

    return AppCard(
      onTap: onOpen,
      padding: const EdgeInsets.all(Sizes.p16),
      borderColor: selected ? AppColors.secondary : AppColors.dividerLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (delivery.urgent) ...[
                const Pill(
                  label: 'Urgent',
                  foreground: AppColors.warning,
                  background: AppColors.warningLight,
                  icon: Icons.bolt_rounded,
                ),
                gapW8,
              ],
              Pill(
                label:
                    '$count arrêt${count > 1 ? 's' : ''} · '
                    '${delivery.itemsCount} article'
                    '${delivery.itemsCount > 1 ? 's' : ''}',
                foreground: AppColors.primary,
                background: AppColors.primary.withValues(alpha: 0.08),
              ),
              const Spacer(),
              Text(
                CurrencyFormatter.formatUsd(delivery.deliveryFee),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          gapH12,
          Text(
            route,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
          gapH4,
          Text(
            delivery.pickups.map((p) => p.place.commune).toSet().join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              if (distance != null) ...[
                const Icon(
                  Icons.near_me_rounded,
                  size: 16,
                  color: AppColors.textHintLight,
                ),
                gapW4,
                Text(
                  '${formatDistance(distance!)} du 1er arrêt',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
              const Spacer(),
              SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed: onOpen,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  child: const Text('Voir la course'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoDeliveryCard extends StatelessWidget {
  const _NoDeliveryCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.two_wheeler, color: AppColors.primary, size: 32),
          gapW12,
          Expanded(
            child: Text(
              'Les nouvelles courses apparaîtront ici automatiquement. '
              "Gardez l'application ouverte.",
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondaryLight,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnavailableCard extends ConsumerWidget {
  const _UnavailableCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final loading = ref.watch(availabilityControllerProvider).isLoading;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Passez disponible', style: theme.textTheme.titleMedium),
          gapH4,
          Text(
            'Vous verrez ici toutes les courses et leurs destinations.',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
          gapH12,
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: loading
                  ? null
                  : () => ref
                        .read(availabilityControllerProvider.notifier)
                        .setDisponible(true),
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Me mettre disponible'),
            ),
          ),
        ],
      ),
    );
  }
}

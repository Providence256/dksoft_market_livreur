import 'dart:ui' as ui;

import 'package:dksoft_market_livreur/core/data/livreur_repository.dart';
import 'package:dksoft_market_livreur/core/widgets/pill.dart';
import 'package:dksoft_market_livreur/features/authentication/data/auth_repository.dart';
import 'package:dksoft_market_livreur/features/deliveries/data/deliveries_repository.dart';
import 'package:dksoft_market_livreur/features/deliveries/domain/delivery_model.dart';
import 'package:dksoft_market_livreur/features/deliveries/presentation/delivery_action_controller.dart';
import 'package:dksoft_market_livreur/features/deliveries/presentation/delivery_actions.dart';
import 'package:dksoft_market_livreur/features/map/data/location_repository.dart';
import 'package:dksoft_market_livreur/features/map/presentation/map_camera.dart';
import 'package:dksoft_market_livreur/features/map/presentation/marker_icon_factory.dart';
import 'package:dksoft_market_livreur/features/map/presentation/rider_location.dart';
import 'package:dksoft_market_livreur/features/map/presentation/moto_color.dart';
import 'package:dksoft_market_livreur/features/map/presentation/widgets/map_round_button.dart';
import 'package:dksoft_market_livreur/features/routing/data/routing_repository.dart';
import 'package:dksoft_market_livreur/features/shell/presentation/main_shell.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/formatters/currency_formatter.dart';
import 'package:dksoft_market_livreur/utils/helpers/distance_format.dart';
import 'package:dksoft_market_livreur/utils/helpers/duration_format.dart';
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            const Center(child: Text('Impossible de charger la course.')),
        data: (delivery) => delivery == null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Cette course n'existe plus."),
                    gapH12,
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Retour'),
                    ),
                  ],
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
  static const _kinshasa = LatLng(-4.325, 15.322);

  final _icons = MarkerIconFactory();
  late final double _ratio;

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
    _ratio = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
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

    final stopPoints = <LatLng>[
      for (final p in delivery.pickups)
        if (p.place.hasCoordinates)
          LatLng(p.place.latitude!, p.place.longitude!),
      if (delivery.dropoff.hasCoordinates)
        LatLng(delivery.dropoff.latitude!, delivery.dropoff.longitude!),
    ];

    final fix = resolveRider(
      ref.watch(riderPositionProvider).value,
      stopPoints.isEmpty ? null : stopPoints.first,
    );
    final riderPoint = fix.point;

    final waypoints = <LatLng>[
      if (riderPoint != null) riderPoint,
      ...stopPoints,
    ];
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
        _maybeFit([...route.points, if (riderPoint != null) riderPoint]);
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
          rotation: riderHeadingOf(ref.watch(riderPositionProvider).value) ?? 0,
          zIndexInt: 10,
          infoWindow: const InfoWindow(title: 'Vous êtes ici'),
        ),
    };

    final polylines = <Polyline>{
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
        ),
    };

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: stopPoints.isEmpty ? _kinshasa : stopPoints.first,
            zoom: 13,
          ),
          markers: markers,
          polylines: polylines,
          circles: {
            if (riderPoint != null)
              Circle(
                circleId: const CircleId('rider-halo'),
                center: riderPoint,
                radius: 150,
                fillColor: AppColors.primary.withValues(alpha: 0.10),
                strokeColor: AppColors.primary.withValues(alpha: 0.25),
                strokeWidth: 1,
              ),
          },
          buildingsEnabled: true,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          padding: EdgeInsets.only(bottom: screenHeight * 0.44, top: 90),
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
                Sizes.p16,
                Sizes.p8,
                Sizes.p16,
                0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MapRoundButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Retour',
                    onPressed: () => context.pop(),
                  ),
                  const Spacer(),
                  if (fix.farAway)
                    const Pill(
                      label: 'Position hors de Kinshasa',
                      foreground: AppColors.warning,
                      background: AppColors.warningLight,
                      icon: Icons.location_off_outlined,
                    ),
                  const Spacer(),
                  MapRoundButton(
                    icon: Icons.zoom_out_map_rounded,
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
          child: _OfferCard(
            delivery: delivery,
            distanceMeters: route?.distanceMeters,
            durationSeconds: route?.durationSeconds,
            routeLoading: routeAsync?.isLoading ?? false,
            maxHeight: screenHeight * 0.56,
          ),
        ),
      ],
    );
  }
}

class _OfferCard extends ConsumerWidget {
  const _OfferCard({
    required this.delivery,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.routeLoading,
    required this.maxHeight,
  });

  final DeliveryModel delivery;
  final double? distanceMeters;
  final double? durationSeconds;
  final bool routeLoading;
  final double maxHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final subtitle = distanceMeters != null && durationSeconds != null
        ? '${formatDistance(distanceMeters!)} · ${formatDuration(durationSeconds!)}'
              ' · arrivée vers ${formatArrival(durationSeconds!)}'
        : routeLoading
        ? "Calcul de l'itinéraire…"
        : '${delivery.pickups.length} arrêt'
              '${delivery.pickups.length > 1 ? 's' : ''}'
              ' · ${delivery.itemsCount} article'
              '${delivery.itemsCount > 1 ? 's' : ''}';

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      margin: EdgeInsets.fromLTRB(
        Sizes.p12,
        0,
        Sizes.p12,
        Sizes.p12 + (bottomInset > 0 ? bottomInset - 8 : 0),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Sizes.p20,
              Sizes.p20,
              Sizes.p20,
              Sizes.p12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          CurrencyFormatter.formatUsd(delivery.deliveryFee),
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontSize: 30,
                          ),
                        ),
                      ),
                    ),
                    if (delivery.urgent)
                      const Pill(
                        label: 'Urgent',
                        foreground: AppColors.warning,
                        background: AppColors.warningLight,
                        icon: Icons.bolt_rounded,
                      )
                    else
                      Text(
                        delivery.shortRef,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: AppColors.textHintLight,
                        ),
                      ),
                  ],
                ),
                gapH4,
                Text(
                  subtitle,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.textSecondaryLight,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                Sizes.p20,
                Sizes.p16,
                Sizes.p20,
                Sizes.p8,
              ),
              child: _TripTimeline(delivery: delivery),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Sizes.p16,
              Sizes.p4,
              Sizes.p16,
              Sizes.p16,
            ),
            child: _Actions(delivery: delivery),
          ),
        ],
      ),
    );
  }
}

/// Le parcours : chaque commerçant (point plein) puis le dealer (carré),
/// reliés par un trait.
class _TripTimeline extends StatelessWidget {
  const _TripTimeline({required this.delivery});

  final DeliveryModel delivery;

  @override
  Widget build(BuildContext context) {
    final pickups = delivery.pickups;

    return Column(
      children: [
        for (final (i, stop) in pickups.indexed)
          _TimelineRow(
            label: pickups.length > 1
                ? 'Récupération ${i + 1} sur ${pickups.length}'
                : 'Récupération',
            labelColor: AppColors.secondaryDark,
            name: stop.place.name,
            address: [
              stop.place.address,
              stop.place.commune,
            ].where((e) => e.isNotEmpty).join(', '),
            items: stop.items
                .map((e) => '${e.quantity} × ${e.name}')
                .join(', '),
            square: false,
            isLast: false,
          ),
        _TimelineRow(
          label: 'Remise au dealer',
          labelColor: AppColors.primary,
          name: delivery.dropoff.name,
          address: [
            delivery.dropoff.address,
            delivery.dropoff.commune,
          ].where((e) => e.isNotEmpty).join(', '),
          items: '',
          square: true,
          isLast: true,
        ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.label,
    required this.labelColor,
    required this.name,
    required this.address,
    required this.items,
    required this.square,
    required this.isLast,
  });

  final String label;
  final Color labelColor;
  final String name;
  final String address;
  final String items;
  final bool square;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 14,
            child: Column(
              children: [
                const SizedBox(height: 22),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimaryLight,
                    shape: square ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius: square ? BorderRadius.circular(2) : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
              ],
            ),
          ),
          gapW16,
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : Sizes.p16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: labelColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 18),
                  ),
                  if (address.isNotEmpty)
                    Text(
                      address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  if (items.isNotEmpty)
                    Text(
                      items,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.textHintLight,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Boutons du bas, selon l'état de la course.
class _Actions extends ConsumerWidget {
  const _Actions({required this.delivery});

  final DeliveryModel delivery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
    final isMine = uid != null && delivery.livreurId == uid;
    final isOpen =
        delivery.status == DeliveryStatus.pendingAssignment &&
        delivery.livreurId == null;
    final loading = ref.watch(deliveryActionControllerProvider).isLoading;
    final hasOtherActive = ref.watch(
      currentLivreurProvider.select(
        (value) => value.value?.activeDeliveryId != null,
      ),
    );

    Widget info(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: Sizes.p8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelLarge?.copyWith(
          color: AppColors.textSecondaryLight,
          fontWeight: FontWeight.w400,
        ),
      ),
    );

    if (isOpen && !hasOtherActive) {
      return Row(
        children: [
          Expanded(
            child: _BigButton(
              label: 'Refuser',
              color: AppColors.error,
              onPressed: loading
                  ? null
                  : () async {
                      final declined = await confirmDecline(
                        context,
                        ref,
                        delivery.id,
                      );
                      if (declined && context.mounted) context.pop();
                    },
            ),
          ),
          gapW12,
          Expanded(
            child: _BigButton(
              label: 'Accepter',
              color: AppColors.success,
              loading: loading,
              onPressed: loading
                  ? null
                  : () async {
                      final ok = await acceptAndOpenMap(
                        context,
                        ref,
                        delivery.id,
                      );
                      if (ok && context.mounted) context.pop();
                    },
            ),
          ),
        ],
      );
    }

    if (isOpen && hasOtherActive) {
      return info(
        "Terminez votre course en cours avant d'en prendre une autre.",
      );
    }

    if (isMine) {
      return _BigButton(
        label: 'Ouvrir la carte',
        color: AppColors.primary,
        onPressed: () {
          ref.read(shellIndexProvider.notifier).select(kTabMap);
          context.pop();
        },
      );
    }

    return Column(
      children: [
        info('Cette course a été prise par un autre motard.'),
        _BigButton(
          label: 'Retour aux demandes',
          color: AppColors.primary,
          onPressed: () => context.pop(),
        ),
      ],
    );
  }
}

class _BigButton extends StatelessWidget {
  const _BigButton({
    required this.label,
    required this.color,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: 0.5),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}

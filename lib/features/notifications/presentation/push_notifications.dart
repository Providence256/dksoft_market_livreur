import 'dart:async';

import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/features/authentication/data/auth_repository.dart';
import 'package:dksoft_market_livreur/features/notifications/data/notifications_repository.dart';
import 'package:dksoft_market_livreur/features/settings/data/preferences.dart';
import 'package:dksoft_market_livreur/routing/app_router.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:toastification/toastification.dart';

/// Reçu quand l'app est fermée ou en arrière-plan : le système affiche
/// déjà la notification, il n'y a rien d'autre à faire.
@pragma('vm:entry-point')
Future<void> onBackgroundPushMessage(RemoteMessage message) async {}

/// Branche les notifications push sur l'app :
/// - le token de l'appareil suit le motard connecté ;
/// - app ouverte : une bannière annonce la nouvelle course ;
/// - toucher la notification (ou la bannière) ouvre la course.
class PushNotifications extends ConsumerStatefulWidget {
  const PushNotifications({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PushNotifications> createState() => _PushNotificationsState();
}

class _PushNotificationsState extends ConsumerState<PushNotifications> {
  final _subscriptions = <StreamSubscription<Object?>>[];

  NotificationsRepository get _repository =>
      ref.read(notificationsRepositoryProvider);

  bool get _enabled => ref.read(notificationsEnabledProvider);

  @override
  void initState() {
    super.initState();

    // Chaque connexion (ou ouverture de l'app déjà connectée) enregistre
    // l'appareil pour ce motard.
    ref.listenManual(authStateChangesProvider, (previous, next) {
      final uid = next.value?.uid;
      if (uid != null && uid != previous?.value?.uid && _enabled) {
        _repository.registerDevice(uid);
      }
    }, fireImmediately: true);

    // Interrupteur des Paramètres : on (dés)inscrit l'appareil aussitôt.
    ref.listenManual<bool>(notificationsEnabledProvider, (previous, enabled) {
      final uid = ref.read(authRepositoryProvider).currentUser?.uid;
      if (uid == null || previous == enabled) return;
      enabled
          ? _repository.registerDevice(uid)
          : _repository.unregisterDevice(uid);
    });

    _subscriptions
      ..add(
        _repository.onTokenRefresh.listen((token) {
          final uid = ref.read(authRepositoryProvider).currentUser?.uid;
          if (uid != null && _enabled) {
            _repository.saveToken(uid, token).ignore();
          }
        }),
      )
      ..add(FirebaseMessaging.onMessage.listen(_showBanner))
      ..add(FirebaseMessaging.onMessageOpenedApp.listen(_open));

    // App lancée en touchant une notification : on attend que le routeur
    // soit prêt avant d'ouvrir la course.
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) => _open(message));
    });
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  String? _deliveryIdOf(RemoteMessage message) {
    if (message.data['type'] != 'new_delivery') return null;
    final id = message.data['deliveryId'];
    return id is String && id.isNotEmpty ? id : null;
  }

  void _open(RemoteMessage message) {
    final id = _deliveryIdOf(message);
    if (id == null || !mounted) return;
    ref
        .read(goRouterProvider)
        .pushNamed(AppRoute.delivery.name, pathParameters: {'id': id});
  }

  void _showBanner(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null || !_enabled) return;
    HapticFeedback.heavyImpact();

    toastification.show(
      type: ToastificationType.info,
      style: ToastificationStyle.flat,
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 8),
      primaryColor: AppColors.secondary,
      backgroundColor: context.palette.surface,
      foregroundColor: context.palette.textPrimary,
      borderRadius: BorderRadius.circular(18),
      showProgressBar: false,
      icon: const AppIcon(AppIcons.moto, color: AppColors.secondary),
      title: Text(
        notification.title ?? 'Nouvelle course',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      description: notification.body == null ? null : Text(notification.body!),
      callbacks: ToastificationCallbacks(
        onTap: (item) {
          toastification.dismiss(item);
          _open(message);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

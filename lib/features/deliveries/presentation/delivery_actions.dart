import 'package:dksoft_market_livreur/core/widgets/confirm_dialog.dart';
import 'package:dksoft_market_livreur/core/widgets/toast.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/features/deliveries/presentation/delivery_action_controller.dart';
import 'package:dksoft_market_livreur/features/shell/presentation/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Accepte une course puis envoie le motard sur la carte. En cas d'échec
/// (course déjà prise, hors connexion…) affiche la raison.
///
/// L'écran appelant doit observer [deliveryActionControllerProvider] pour
/// afficher le chargement et garder l'état en vie.
Future<bool> acceptAndOpenMap(
  BuildContext context,
  WidgetRef ref,
  String deliveryId,
) async {
  final success = await ref
      .read(deliveryActionControllerProvider.notifier)
      .accept(deliveryId);
  if (!context.mounted) return success;

  if (success) {
    Toast.success(context, 'Course acceptée !');
    ref.read(shellIndexProvider.notifier).select(kTabMap);
  } else {
    final error = ref.read(deliveryActionControllerProvider).error;
    Toast.error(context, error?.toString() ?? 'Course non acceptée.');
  }
  return success;
}

/// Demande confirmation puis refuse la course (elle ne sera plus proposée
/// à ce motard).
Future<bool> confirmDecline(
  BuildContext context,
  WidgetRef ref,
  String deliveryId,
) async {
  final confirmed = await showConfirmDialog(
    context,
    title: 'Refuser cette course ?',
    message:
        'Elle ne vous sera plus proposée, mais restera disponible pour les '
        'autres motards.',
    confirmLabel: 'Refuser',
    icon: AppIcons.decline,
    destructive: true,
  );

  if (confirmed) {
    ref.read(deliveryActionControllerProvider.notifier).refuse(deliveryId);
  }
  return confirmed;
}

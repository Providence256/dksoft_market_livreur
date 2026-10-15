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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Course acceptée !')));
    ref.read(shellIndexProvider.notifier).select(kTabMap);
  } else {
    final error = ref.read(deliveryActionControllerProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error?.toString() ?? 'Course non acceptée.')),
    );
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
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Refuser cette course ?'),
      content: const Text(
        'Elle ne vous sera plus proposée, mais restera disponible pour '
        'les autres motards.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Refuser'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    ref.read(deliveryActionControllerProvider.notifier).refuse(deliveryId);
    return true;
  }
  return false;
}

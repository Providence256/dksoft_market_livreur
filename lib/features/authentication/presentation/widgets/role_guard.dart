import 'package:dksoft_market_livreur/core/widgets/skeleton.dart';
import 'package:dksoft_market_livreur/core/data/livreur_repository.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/core/domain/livreur_model.dart';
import 'package:dksoft_market_livreur/core/widgets/app_button.dart';
import 'package:dksoft_market_livreur/core/widgets/empty_state.dart';
import 'package:dksoft_market_livreur/features/authentication/application/is_livreur_provider.dart';
import 'package:dksoft_market_livreur/features/authentication/data/auth_repository.dart';
import 'package:dksoft_market_livreur/features/validation/presentation/pending_validation_screen.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/sign_out_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Protège tout l'espace motard, en deux temps :
///
/// 1. le compte doit porter le claim `livreur` ;
/// 2. le profil `livreurs/{uid}` doit être `valide` (§6.4). En attente,
///    le motard voit l'écran de validation ; suspendu, un message clair.
///
/// Le statut est lu en temps réel : la validation par l'admin débloque
/// l'app sans que le motard ait à se reconnecter.
class RoleGuard extends ConsumerWidget {
  const RoleGuard({
    super.key,
    required this.child,
    this.skeleton = const SafeArea(child: PageSkeleton()),
  });

  final Widget child;

  /// Affiché pendant les vérifications : la silhouette de l'écran protégé.
  final Widget skeleton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pendant une déconnexion, le compte disparaît avant que l'écran de
    // connexion ne prenne la place : pas de message d'erreur entre-temps.
    if (ref.watch(authStateChangesProvider).value == null) {
      return _Loading(skeleton: skeleton);
    }
    final isLivreurAsync = ref.watch(currentUserIsLivreurProvider);

    return isLivreurAsync.when(
      loading: () => _Loading(skeleton: skeleton),
      error: (error, _) => _AccessMessage(
        title: 'Une erreur est survenue',
        message: 'Vérifiez votre connexion internet et réessayez.',
        icon: AppIcons.offline,
        onRetry: () => ref.invalidate(currentUserIsLivreurProvider),
      ),
      data: (isLivreur) {
        if (!isLivreur) {
          return _AccessMessage(
            icon: AppIcons.moto,
            title: 'Application réservée aux motards',
            message:
                "Ce compte n'est pas enregistré comme motard. Si vous venez "
                'de créer votre compte, patientez un instant puis réessayez.',
            onRetry: () => ref.invalidate(currentUserIsLivreurProvider),
          );
        }
        return _StatusGate(skeleton: skeleton, child: child);
      },
    );
  }
}

class _StatusGate extends ConsumerWidget {
  const _StatusGate({required this.child, required this.skeleton});

  final Widget child;
  final Widget skeleton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final livreurAsync = ref.watch(currentLivreurProvider);

    return livreurAsync.when(
      loading: () => _Loading(skeleton: skeleton),
      error: (error, _) => _AccessMessage(
        title: 'Une erreur est survenue',
        message: 'Impossible de charger votre profil. Réessayez.',
        onRetry: () => ref.invalidate(currentLivreurProvider),
      ),
      data: (livreur) {
        if (livreur == null) {
          return const _AccessMessage(
            icon: AppIcons.userOff,
            title: 'Profil introuvable',
            message:
                "Votre profil motard n'a pas été trouvé. Contactez "
                "l'administration Dksoft Market.",
          );
        }

        return switch (livreur.status) {
          LivreurStatus.valide => child,
          LivreurStatus.pending => PendingValidationScreen(livreur: livreur),
          LivreurStatus.suspendu => const _AccessMessage(
            icon: AppIcons.lock,
            title: 'Compte suspendu',
            message:
                "Votre compte a été suspendu par l'administration. Contactez "
                'le support Dksoft Market pour en savoir plus.',
          ),
        };
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading({required this.skeleton});

  final Widget skeleton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: skeleton);
  }
}

class _AccessMessage extends ConsumerWidget {
  const _AccessMessage({
    required this.title,
    required this.message,
    this.icon = AppIcons.block,
    this.onRetry,
  });

  final String title;
  final String message;
  final AppIconData icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: EmptyState(
          icon: icon,
          color: AppColors.error,
          title: title,
          message: message,
          action: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onRetry != null) ...[
                AppButton(
                  label: 'Réessayer',
                  icon: AppIcons.refresh,
                  expand: false,
                  onPressed: onRetry,
                ),
                gapH8,
              ],
              TextButton(
                onPressed: () =>
                    ref.read(signOutControllerProvider.notifier).signOut(),
                child: const Text('Se déconnecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

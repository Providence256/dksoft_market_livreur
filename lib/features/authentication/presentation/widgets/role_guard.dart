import 'package:dksoft_market_livreur/core/data/livreur_repository.dart';
import 'package:dksoft_market_livreur/core/domain/livreur_model.dart';
import 'package:dksoft_market_livreur/features/authentication/application/is_livreur_provider.dart';
import 'package:dksoft_market_livreur/features/authentication/data/auth_repository.dart';
import 'package:dksoft_market_livreur/features/validation/presentation/pending_validation_screen.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
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
  const RoleGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLivreurAsync = ref.watch(currentUserIsLivreurProvider);

    return isLivreurAsync.when(
      loading: () => const _Loading(),
      error: (error, _) => _AccessMessage(
        title: 'Une erreur est survenue',
        message: 'Vérifiez votre connexion internet et réessayez.',
        onRetry: () => ref.invalidate(currentUserIsLivreurProvider),
      ),
      data: (isLivreur) {
        if (!isLivreur) {
          return _AccessMessage(
            title: 'Application réservée aux motards',
            message:
                "Ce compte n'est pas enregistré comme motard. Si vous venez "
                'de créer votre compte, patientez un instant puis réessayez.',
            onRetry: () => ref.invalidate(currentUserIsLivreurProvider),
          );
        }
        return _StatusGate(child: child);
      },
    );
  }
}

class _StatusGate extends ConsumerWidget {
  const _StatusGate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final livreurAsync = ref.watch(currentLivreurProvider);

    return livreurAsync.when(
      loading: () => const _Loading(),
      error: (error, _) => _AccessMessage(
        title: 'Une erreur est survenue',
        message: 'Impossible de charger votre profil. Réessayez.',
        onRetry: () => ref.invalidate(currentLivreurProvider),
      ),
      data: (livreur) {
        if (livreur == null) {
          return const _AccessMessage(
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
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _AccessMessage extends ConsumerWidget {
  const _AccessMessage({
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(Sizes.p24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(Sizes.p20),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.block,
                    color: AppColors.error,
                    size: 40,
                  ),
                ),
                gapH12,
                Text(
                  title,
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                gapH8,
                Text(
                  message,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                gapH16,
                if (onRetry != null) ...[
                  ElevatedButton(
                    onPressed: onRetry,
                    child: Text(
                      'Réessayer',
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  gapH8,
                ],
                TextButton(
                  onPressed: () => ref.read(authRepositoryProvider).signOut(),
                  child: const Text('Se déconnecter'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

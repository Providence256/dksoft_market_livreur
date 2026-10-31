import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/core/widgets/loading_dots.dart';
import 'package:dksoft_market_livreur/features/authentication/data/auth_repository.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Vrai pendant une déconnexion : de la confirmation jusqu'à l'arrivée sur
/// l'écran de connexion.
class SignOutController extends Notifier<bool> {
  @override
  bool build() => false;

  /// Le token de notification est retiré du profil avant la déconnexion
  /// (jusqu'à 5 s hors connexion). Pendant ce temps, et le temps que les
  /// écrans du motard se vident, [SignOutOverlay] couvre l'app : pas
  /// d'écran « Profil introuvable » ni de chargement qui clignote.
  Future<void> signOut() async {
    if (state) return;
    state = true;
    try {
      await ref.read(authRepositoryProvider).signOut();
      // Laisse l'écran de connexion s'installer derrière le voile.
      await Future<void>.delayed(const Duration(milliseconds: 500));
    } finally {
      state = false;
    }
  }
}

final signOutControllerProvider = NotifierProvider<SignOutController, bool>(
  SignOutController.new,
);

/// Voile plein écran affiché pendant la déconnexion. Placé au-dessus du
/// routeur (MaterialApp.builder) : il couvre aussi les transitions.
class SignOutOverlay extends ConsumerWidget {
  const SignOutOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signingOut = ref.watch(signOutControllerProvider);

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !signingOut,
            child: AnimatedOpacity(
              opacity: signingOut ? 1 : 0,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              child: const _SigningOut(),
            ),
          ),
        ),
      ],
    );
  }
}

class _SigningOut extends StatelessWidget {
  const _SigningOut();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final theme = Theme.of(context);

    // Material : au-dessus du routeur, il n'y a pas encore de style de
    // texte par défaut.
    return Material(
      color: palette.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: palette.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: AppIcon(
                  AppIcons.logout,
                  size: 36,
                  color: palette.primary,
                ),
              ),
            ),
            gapH24,
            Text('Déconnexion…', style: theme.textTheme.titleLarge),
            gapH8,
            Text(
              'À bientôt sur la route !',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: palette.textSecondary,
              ),
            ),
            gapH24,
            LoadingDots(color: palette.primary, size: 9),
          ],
        ),
      ),
    );
  }
}

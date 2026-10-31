import 'package:dksoft_market_livreur/features/dashboard/presentation/widgets/dashboard_skeleton.dart';
import 'package:dksoft_market_livreur/core/animations/motion.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/core/data/livreur_repository.dart';
import 'package:dksoft_market_livreur/core/domain/livreur_model.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/core/widgets/empty_state.dart';
import 'package:dksoft_market_livreur/core/widgets/initials_avatar.dart';
import 'package:dksoft_market_livreur/features/dashboard/presentation/widgets/availability_card.dart';
import 'package:dksoft_market_livreur/features/dashboard/presentation/widgets/mission_section.dart';
import 'package:dksoft_market_livreur/features/dashboard/presentation/widgets/stat_tiles.dart';
import 'package:dksoft_market_livreur/features/deliveries/data/deliveries_repository.dart';
import 'package:dksoft_market_livreur/features/shell/presentation/main_shell.dart';
import 'package:dksoft_market_livreur/routing/app_router.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/formatters/date_formatter_fr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Accueil du motard : salutation, disponibilité, chiffres clés, course
/// en cours ou demandes à prendre. Les gains ont leur propre onglet.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final livreurAsync = ref.watch(currentLivreurProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: livreurAsync.when(
          loading: () => const DashboardSkeleton(),
          error: (_, _) => EmptyState(
            icon: AppIcons.offline,
            title: 'Impossible de charger votre profil',
            message: 'Vérifiez votre connexion internet.',
          ),
          data: (livreur) => livreur == null
              ? const EmptyState(
                  icon: AppIcons.userOff,
                  title: 'Profil introuvable',
                  message: "Contactez l'administration Dksoft Market.",
                )
              : _DashboardBody(livreur: livreur),
        ),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.livreur});

  final LivreurModel livreur;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availableCount =
        ref.watch(availableDeliveriesProvider).value?.length ?? 0;

    void openRequests() =>
        ref.read(shellIndexProvider.notifier).select(kTabDeliveries);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        Sizes.screenPadding,
        Sizes.p12,
        Sizes.screenPadding,
        // La barre de navigation flotte au-dessus de la fin de la liste.
        MediaQuery.paddingOf(context).bottom + Sizes.p24,
      ),
      children: staggerIn([
        _Header(livreur: livreur, onBell: openRequests),
        gapH20,
        AvailabilityCard(disponible: livreur.disponible),
        gapH16,
        StatTiles(
          deliveries: livreur.livraisonsEffectuees,
          rating: livreur.ratingCount == 0 ? null : livreur.rating,
          ratingCount: livreur.ratingCount,
          requests: availableCount,
          onRequestsTap: openRequests,
          onRatingTap: () => context.pushNamed(AppRoute.reviews.name),
        ),
        gapH24,
        MissionSection(livreur: livreur),
      ], step: 60),
    );
  }
}

/// Salutation, date du jour et accès rapide aux demandes.
class _Header extends StatelessWidget {
  const _Header({required this.livreur, required this.onBell});

  final LivreurModel livreur;
  final VoidCallback onBell;

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bonjour';
    if (hour < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstName = livreur.firstName.isNotEmpty
        ? livreur.firstName
        : livreur.fullName.split(' ').first;

    return Row(
      children: [
        InitialsAvatar(name: livreur.fullName, size: 50),
        gapW12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_greeting()}, $firstName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge,
              ),
              Row(
                children: [
                  AppIcon(
                    AppIcons.calendar,
                    size: 14,
                    color: context.palette.textMuted,
                  ),
                  gapW4,
                  Text(
                    DateFormatterFr.dayLabel(DateTime.now()),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
        Pressable(
          onTap: onBell,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.palette.surface,
              shape: BoxShape.circle,
              boxShadow: AppShadows.card,
            ),
            child: const Center(child: AppIcon(AppIcons.bell, size: 23)),
          ),
        ),
      ],
    );
  }
}

import 'package:dksoft_market_livreur/core/widgets/app_nav_bar.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/features/authentication/data/auth_repository.dart';
import 'package:dksoft_market_livreur/features/dashboard/presentation/dashboard_screen.dart';
import 'package:dksoft_market_livreur/features/deliveries/data/deliveries_repository.dart';
import 'package:dksoft_market_livreur/features/deliveries/presentation/available_deliveries_screen.dart';
import 'package:dksoft_market_livreur/features/earnings/presentation/earnings_screen.dart';
import 'package:dksoft_market_livreur/features/map/data/live_tracking.dart';
import 'package:dksoft_market_livreur/features/map/presentation/overview_map_screen.dart';
import 'package:dksoft_market_livreur/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onglet actif de la navigation principale. Les écrans (l'accueil par
/// exemple) peuvent le changer pour envoyer le motard sur la carte.
class ShellIndex extends Notifier<int> {
  /// Repart de l'accueil à chaque changement de compte (sinon on se
  /// reconnecte sur l'onglet Profil, d'où l'on s'est déconnecté).
  @override
  int build() {
    ref.watch(authStateChangesProvider.select((user) => user.value?.uid));
    return kTabHome;
  }

  void select(int index) => state = index;
}

final shellIndexProvider = NotifierProvider<ShellIndex, int>(ShellIndex.new);

/// La carte passe en plein écran pendant la navigation : la barre du bas
/// de l'application est alors masquée.
class FullScreenMap extends Notifier<bool> {
  @override
  bool build() {
    ref.watch(authStateChangesProvider.select((user) => user.value?.uid));
    return false;
  }

  void set(bool value) => state = value;
}

final fullScreenMapProvider = NotifierProvider<FullScreenMap, bool>(
  FullScreenMap.new,
);

const kTabHome = 0;
const kTabMap = 1;
const kTabDeliveries = 2;
const kTabEarnings = 3;
const kTabProfile = 4;

/// Navigation principale du motard : Accueil, Carte, Demandes, Gains,
/// Profil.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  /// La carte (et la demande de localisation) ne démarre qu'à la première
  /// visite de l'onglet.
  bool _mapVisited = false;

  @override
  Widget build(BuildContext context) {
    // Partage la position pendant une course (inactif sinon).
    ref.watch(liveTrackingProvider);

    final index = ref.watch(shellIndexProvider);
    final fullScreen = ref.watch(fullScreenMapProvider) && index == kTabMap;
    if (index == kTabMap) _mapVisited = true;

    // Nombre de courses à prendre : 0 tant que le motard est indisponible.
    final availableCount =
        ref.watch(availableDeliveriesProvider).value?.length ?? 0;

    return Scaffold(
      // La barre flotte au-dessus du contenu.
      extendBody: true,
      body: IndexedStack(
        index: index,
        children: [
          const DashboardScreen(),
          _mapVisited ? const OverviewMapScreen() : const SizedBox.shrink(),
          const AvailableDeliveriesScreen(),
          const EarningsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: fullScreen
          ? null
          : AppNavBar(
              index: index,
              onSelected: ref.read(shellIndexProvider.notifier).select,
              items: [
                const AppNavItem(icon: AppIcons.home, label: 'Accueil'),
                const AppNavItem(icon: AppIcons.map, label: 'Carte'),
                AppNavItem(
                  icon: AppIcons.requests,
                  label: 'Demandes',
                  badge: availableCount,
                ),
                const AppNavItem(icon: AppIcons.wallet, label: 'Gains'),
                const AppNavItem(icon: AppIcons.profile, label: 'Profil'),
              ],
            ),
    );
  }
}

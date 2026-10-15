import 'package:dksoft_market_livreur/features/dashboard/presentation/dashboard_screen.dart';
import 'package:dksoft_market_livreur/features/deliveries/data/deliveries_repository.dart';
import 'package:dksoft_market_livreur/features/deliveries/presentation/available_deliveries_screen.dart';
import 'package:dksoft_market_livreur/features/earnings/presentation/earnings_screen.dart';
import 'package:dksoft_market_livreur/features/map/presentation/overview_map_screen.dart';
import 'package:dksoft_market_livreur/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onglet actif de la navigation principale. Les écrans (l'accueil par
/// exemple) peuvent le changer pour envoyer le motard sur la carte.
class ShellIndex extends Notifier<int> {
  @override
  int build() => 0;

  void select(int index) => state = index;
}

final shellIndexProvider = NotifierProvider<ShellIndex, int>(ShellIndex.new);

/// La carte passe en plein écran pendant la navigation : la barre du bas
/// de l'application est alors masquée.
class FullScreenMap extends Notifier<bool> {
  @override
  bool build() => false;

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

/// Navigation principale du motard : Accueil, Carte, Courses.
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
    final index = ref.watch(shellIndexProvider);
    final fullScreen = ref.watch(fullScreenMapProvider) && index == kTabMap;
    if (index == kTabMap) _mapVisited = true;

    // Nombre de courses à prendre : 0 tant que le motard est indisponible.
    final availableCount =
        ref.watch(availableDeliveriesProvider).value?.length ?? 0;

    Widget badge(IconData icon) => Badge.count(
      count: availableCount,
      isLabelVisible: availableCount > 0,
      child: Icon(icon),
    );

    return Scaffold(
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
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: ref
                  .read(shellIndexProvider.notifier)
                  .select,
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.space_dashboard_outlined),
                  selectedIcon: Icon(Icons.space_dashboard_rounded),
                  label: 'Accueil',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.map_outlined),
                  selectedIcon: Icon(Icons.map_rounded),
                  label: 'Carte',
                ),
                NavigationDestination(
                  icon: badge(Icons.two_wheeler_outlined),
                  selectedIcon: badge(Icons.two_wheeler_rounded),
                  label: 'Demandes',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                  label: 'Gains',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Profil',
                ),
              ],
            ),
    );
  }
}

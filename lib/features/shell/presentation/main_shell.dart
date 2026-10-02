import 'package:dksoft_market_livreur/features/dashboard/presentation/dashboard_screen.dart';
import 'package:dksoft_market_livreur/features/deliveries/data/deliveries_repository.dart';
import 'package:dksoft_market_livreur/features/deliveries/presentation/available_deliveries_screen.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Navigation principale du motard. D'autres onglets (historique, gains)
/// s'ajouteront ici aux étapes suivantes.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    // Nombre de courses à prendre : 0 tant que le motard est indisponible.
    final availableCount =
        ref.watch(availableDeliveriesProvider).value?.length ?? 0;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [DashboardScreen(), AvailableDeliveriesScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Badge.count(
              count: availableCount,
              isLabelVisible: availableCount > 0,
              child: const Icon(Icons.local_shipping_outlined),
            ),
            selectedIcon: Badge.count(
              count: availableCount,
              isLabelVisible: availableCount > 0,
              child: const Icon(Icons.local_shipping_rounded),
            ),
            label: 'Courses',
          ),
        ],
      ),
    );
  }
}

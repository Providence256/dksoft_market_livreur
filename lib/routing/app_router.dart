import 'package:dksoft_market_livreur/features/dashboard/presentation/widgets/dashboard_skeleton.dart';
import 'package:dksoft_market_livreur/features/map/presentation/widgets/map_skeleton.dart';
import 'package:dksoft_market_livreur/features/authentication/data/auth_repository.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/login_screen.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/signup_screen.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/widgets/role_guard.dart';
import 'package:dksoft_market_livreur/features/deliveries/presentation/delivery_detail_screen.dart';
import 'package:dksoft_market_livreur/features/map/presentation/delivery_map_screen.dart';
import 'package:dksoft_market_livreur/features/reviews/presentation/reviews_screen.dart';
import 'package:dksoft_market_livreur/features/settings/presentation/settings_screen.dart';
import 'package:dksoft_market_livreur/features/shell/presentation/main_shell.dart';
import 'package:dksoft_market_livreur/routing/go_router_refresh_stream.dart';
import 'package:dksoft_market_livreur/core/animations/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum AppRoute { home, login, signup, delivery, deliveryMap, reviews, settings }

const _publicPaths = ['/login', '/signup'];

/// Transition commune : le nouvel écran monte en fondu pendant que l'ancien
/// recule et s'estompe légèrement.
/// [sheet] : l'écran monte du bas comme une feuille, sans fondu ni zoom
/// (les écrans qui contiennent une carte native n'aiment pas les fondus).
CustomTransitionPage<void> _page(
  GoRouterState state,
  Widget child, {
  bool sheet = false,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 480),
    reverseTransitionDuration: const Duration(milliseconds: 340),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Motion.emphasized,
        reverseCurve: Curves.easeInCubic,
      );
      if (sheet) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        );
      }
      final behind = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOut,
      );
      return ScaleTransition(
        scale: Tween<double>(begin: 1, end: 0.95).animate(behind),
        child: FadeTransition(
          opacity: Tween<double>(begin: 1, end: 0.55).animate(behind),
          child: FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.07),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          ),
        ),
      );
    },
  );
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: GoRouterRefreshStream(authRepository.authStateChanges()),
    redirect: (context, state) {
      final isLoggedIn = authRepository.currentUser != null;
      final path = state.matchedLocation;
      final isPublic = _publicPaths.contains(path);

      if (!isLoggedIn && !isPublic) return '/login';

      // Seul /login redirige automatiquement une fois connecté. /signup
      // est exclu volontairement : SignUpScreen navigue lui-même quand
      // l'inscription (écritures Firestore comprises) est terminée, et
      // non dès que Firebase Auth annonce un utilisateur.
      if (isLoggedIn && path == '/login') return '/home';

      return null;
    },
    routes: [
      GoRoute(
        path: '/home',
        name: AppRoute.home.name,
        pageBuilder: (context, state) => _page(
          state,
          const RoleGuard(
            skeleton: SafeArea(bottom: false, child: DashboardSkeleton()),
            child: MainShell(),
          ),
        ),
      ),
      GoRoute(
        path: '/delivery/:id',
        name: AppRoute.delivery.name,
        pageBuilder: (context, state) => _page(
          state,
          RoleGuard(
            skeleton: const MapSkeleton(),
            child: DeliveryDetailScreen(
              deliveryId: state.pathParameters['id']!,
            ),
          ),
          sheet: true,
        ),
      ),
      GoRoute(
        path: '/delivery/:id/map',
        name: AppRoute.deliveryMap.name,
        pageBuilder: (context, state) => _page(
          state,
          RoleGuard(
            skeleton: const MapSkeleton(),
            child: DeliveryMapScreen(deliveryId: state.pathParameters['id']!),
          ),
          sheet: true,
        ),
      ),
      GoRoute(
        path: '/reviews',
        name: AppRoute.reviews.name,
        pageBuilder: (context, state) =>
            _page(state, const RoleGuard(child: ReviewsScreen())),
      ),
      GoRoute(
        path: '/settings',
        name: AppRoute.settings.name,
        pageBuilder: (context, state) => _page(state, const SettingsScreen()),
      ),
      GoRoute(
        path: '/login',
        name: AppRoute.login.name,
        pageBuilder: (context, state) => _page(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/signup',
        name: AppRoute.signup.name,
        pageBuilder: (context, state) => _page(state, const SignUpScreen()),
      ),
    ],
  );
});

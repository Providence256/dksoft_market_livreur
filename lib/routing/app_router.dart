import 'package:dksoft_market_livreur/features/authentication/data/auth_repository.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/login_screen.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/signup_screen.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/widgets/role_guard.dart';
import 'package:dksoft_market_livreur/features/deliveries/presentation/delivery_detail_screen.dart';
import 'package:dksoft_market_livreur/features/map/presentation/delivery_map_screen.dart';
import 'package:dksoft_market_livreur/features/shell/presentation/main_shell.dart';
import 'package:dksoft_market_livreur/routing/go_router_refresh_stream.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum AppRoute { home, login, signup, delivery, deliveryMap }

const _publicPaths = ['/login', '/signup'];

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
        builder: (context, state) => const RoleGuard(child: MainShell()),
      ),
      GoRoute(
        path: '/delivery/:id',
        name: AppRoute.delivery.name,
        builder: (context, state) => RoleGuard(
          child: DeliveryDetailScreen(deliveryId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/delivery/:id/map',
        name: AppRoute.deliveryMap.name,
        builder: (context, state) => RoleGuard(
          child: DeliveryMapScreen(deliveryId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: '/login',
        name: AppRoute.login.name,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: AppRoute.signup.name,
        builder: (context, state) => const SignUpScreen(),
      ),
    ],
  );
});

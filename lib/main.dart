import 'package:dksoft_market_livreur/features/authentication/data/auth_repository.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/sign_out_controller.dart';
import 'package:dksoft_market_livreur/features/notifications/presentation/push_notifications.dart';
import 'package:dksoft_market_livreur/features/settings/data/preferences.dart';
import 'package:dksoft_market_livreur/firebase_options.dart';
import 'package:dksoft_market_livreur/routing/app_router.dart';
import 'package:dksoft_market_livreur/utils/themes/app_theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(onBackgroundPushMessage);

  // Plantages et erreurs non rattrapées remontés dans la console Firebase
  // (Crashlytics). Coupé en debug : les erreurs s'affichent déjà à l'écran
  // et dans la console, comme d'habitude.
  final crashlytics = FirebaseCrashlytics.instance;
  await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
  if (!kDebugMode) {
    FlutterError.onError = crashlytics.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }

  final preferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: const MainApp(),
    ),
  );
}

class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goRouter = ref.watch(goRouterProvider);

    // Chaque rapport de plantage indique le motard concerné.
    ref.listen(authStateChangesProvider, (_, next) {
      FirebaseCrashlytics.instance.setUserIdentifier(next.value?.uid ?? '');
    });

    return ToastificationWrapper(
      child: PushNotifications(
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Dksoft-Market-Livreur',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ref.watch(themeModeProvider),
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routerConfig: goRouter,
          builder: (context, child) => SignOutOverlay(child: child!),
        ),
      ),
    );
  }
}

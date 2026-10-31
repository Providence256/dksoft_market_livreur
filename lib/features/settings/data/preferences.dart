import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fourni dans `main` une fois l'instance chargée.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Surchargé dans main()'),
);

/// Apparence choisie par le motard (celle du téléphone par défaut),
/// mémorisée sur l'appareil.
class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'themeMode';

  @override
  ThemeMode build() {
    final saved = ref.watch(sharedPreferencesProvider).getString(_key);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == saved,
      orElse: () => ThemeMode.system,
    );
  }

  void select(ThemeMode mode) {
    state = mode;
    ref.read(sharedPreferencesProvider).setString(_key, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

/// Interrupteur booléen mémorisé sur l'appareil (activé par défaut).
class _SwitchPreference extends Notifier<bool> {
  _SwitchPreference(this._key);

  final String _key;

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? true;

  void set(bool value) {
    state = value;
    ref.read(sharedPreferencesProvider).setBool(_key, value);
  }
}

/// Recevoir les notifications de nouvelles courses sur ce téléphone.
final notificationsEnabledProvider = NotifierProvider<_SwitchPreference, bool>(
  () => _SwitchPreference('notificationsEnabled'),
);

/// Partager sa position pendant une course (suivi par le dealer).
final liveTrackingEnabledProvider = NotifierProvider<_SwitchPreference, bool>(
  () => _SwitchPreference('liveTrackingEnabled'),
);

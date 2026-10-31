import 'package:dksoft_market_livreur/core/animations/motion.dart';
import 'package:dksoft_market_livreur/core/widgets/app_card.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/core/widgets/icon_tile.dart';
import 'package:dksoft_market_livreur/core/widgets/section_title.dart';
import 'package:dksoft_market_livreur/features/map/data/location_repository.dart';
import 'package:dksoft_market_livreur/features/map/presentation/map_layers.dart';
import 'package:dksoft_market_livreur/features/settings/data/preferences.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

/// Paramètres de l'appareil : apparence, notifications, localisation.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Retour des Réglages du téléphone : on relit l'autorisation.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(locationAccessProvider.notifier).recheck(request: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final notifications = ref.watch(notificationsEnabledProvider);
    final tracking = ref.watch(liveTrackingEnabledProvider);
    final access = ref.watch(locationAccessProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Sizes.screenPadding,
            Sizes.p4,
            Sizes.screenPadding,
            Sizes.p32,
          ),
          children: staggerIn([
            // ---- Apparence ----
            const SectionTitle('Apparence'),
            gapH8,
            AppCard(
              padding: const EdgeInsets.all(Sizes.p8),
              child: Row(
                spacing: Sizes.p8,
                children: [
                  for (final (mode, label, icon) in const [
                    (
                      ThemeMode.system,
                      'Téléphone',
                      HugeIcons.strokeRoundedSmartPhone01,
                    ),
                    (ThemeMode.light, 'Clair', HugeIcons.strokeRoundedSun03),
                    (ThemeMode.dark, 'Sombre', HugeIcons.strokeRoundedMoon02),
                  ])
                    Expanded(
                      child: _ThemeChoice(
                        label: label,
                        icon: icon,
                        selected: themeMode == mode,
                        onTap: () =>
                            ref.read(themeModeProvider.notifier).select(mode),
                      ),
                    ),
                ],
              ),
            ),
            gapH24,

            // ---- Notifications ----
            const SectionTitle('Notifications'),
            gapH8,
            AppCard(
              padding: EdgeInsets.zero,
              child: _SwitchRow(
                icon: AppIcons.bell,
                color: AppColors.secondary,
                title: 'Nouvelles courses',
                subtitle: notifications
                    ? 'Vous êtes prévenu dès qu’une course est proposée.'
                    : 'Vous ne serez plus prévenu des nouvelles courses.',
                value: notifications,
                onChanged: ref.read(notificationsEnabledProvider.notifier).set,
              ),
            ),
            gapH24,

            // ---- Localisation ----
            const SectionTitle('Localisation'),
            gapH8,
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SwitchRow(
                    icon: AppIcons.nearMe,
                    color: context.palette.primary,
                    title: 'Partager ma position en course',
                    subtitle:
                        'Le dealer suit votre arrivée pendant une course. '
                        'Jamais en dehors.',
                    value: tracking,
                    onChanged: ref
                        .read(liveTrackingEnabledProvider.notifier)
                        .set,
                  ),
                  Divider(
                    indent: 68,
                    endIndent: Sizes.p16,
                    color: context.palette.border,
                  ),
                  _AccessRow(
                    access: access,
                    onFix: access == null || access == LocationAccess.granted
                        ? null
                        : () => fixLocationAccess(ref, access),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final AppIconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final color = selected ? palette.primary : palette.textSecondary;

    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Motion.fast,
        padding: const EdgeInsets.symmetric(vertical: Sizes.p12),
        decoration: BoxDecoration(
          color: selected ? palette.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Column(
          children: [
            AppIcon(icon, color: color, size: 22),
            gapH4,
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final AppIconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Sizes.p16,
        Sizes.p12,
        Sizes.p8,
        Sizes.p12,
      ),
      child: Row(
        children: [
          IconTile(icon: icon, color: color, size: 38, radius: Radii.sm),
          gapW16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          gapW8,
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// Autorisation de position du téléphone : l'app ne peut pas la changer
/// elle-même, elle ouvre les Réglages.
class _AccessRow extends StatelessWidget {
  const _AccessRow({required this.access, required this.onFix});

  final LocationAccess? access;
  final VoidCallback? onFix;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = switch (access) {
      LocationAccess.granted => ('Autorisée', AppColors.success),
      LocationAccess.serviceDisabled => (
        'GPS désactivé sur le téléphone',
        AppColors.error,
      ),
      LocationAccess.deniedForever ||
      LocationAccess.denied => ('Refusée', AppColors.error),
      null => ('Vérification…', context.palette.textMuted),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Sizes.p16,
        Sizes.p12,
        Sizes.p8,
        Sizes.p12,
      ),
      child: Row(
        children: [
          IconTile(
            icon: AppIcons.myLocation,
            color: color,
            size: 38,
            radius: Radii.sm,
          ),
          gapW16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Accès à la position', style: theme.textTheme.titleSmall),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(color: color),
                ),
              ],
            ),
          ),
          if (onFix != null)
            TextButton(onPressed: onFix, child: const Text('Réglages')),
        ],
      ),
    );
  }
}

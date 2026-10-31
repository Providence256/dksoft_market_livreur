import 'package:dksoft_market_livreur/features/profile/presentation/widgets/profile_skeleton.dart';
import 'package:dksoft_market_livreur/core/animations/motion.dart';
import 'package:dksoft_market_livreur/routing/app_router.dart';
import 'package:dksoft_market_livreur/core/widgets/toast.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/core/data/livreur_repository.dart';
import 'package:dksoft_market_livreur/core/domain/livreur_model.dart';
import 'package:dksoft_market_livreur/core/widgets/app_button.dart';
import 'package:dksoft_market_livreur/core/widgets/app_card.dart';
import 'package:dksoft_market_livreur/core/widgets/confirm_dialog.dart';
import 'package:dksoft_market_livreur/core/widgets/icon_tile.dart';
import 'package:dksoft_market_livreur/core/widgets/initials_avatar.dart';
import 'package:dksoft_market_livreur/core/widgets/hero_card.dart';
import 'package:dksoft_market_livreur/core/widgets/section_title.dart';
import 'package:dksoft_market_livreur/features/profile/presentation/widgets/change_password_sheet.dart';
import 'package:dksoft_market_livreur/features/profile/presentation/widgets/edit_moto_sheet.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/helpers/phone_format.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/sign_out_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onglet « Profil » : identité et statut du compte, moto, pièce
/// d'identité, déconnexion.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Se déconnecter ?',
      message: 'Vous ne recevrez plus de courses sur ce téléphone.',
      confirmLabel: 'Déconnexion',
      icon: AppIcons.logout,
      destructive: true,
    );
    if (confirmed) await ref.read(signOutControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final livreur = ref.watch(currentLivreurProvider).value;

    if (livreur == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mon profil')),
        body: const SafeArea(child: ProfileSkeleton()),
      );
    }

    final moto = [
      livreur.motoMake,
      livreur.motoModel,
    ].where((e) => e.isNotEmpty).join(' ');
    final plaque = livreur.plaque;

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Sizes.screenPadding,
            Sizes.p4,
            Sizes.screenPadding,
            Sizes.p32,
          ),
          children: staggerIn([
            // ---- Identité ----
            HeroBackground(
              child: Padding(
                padding: const EdgeInsets.all(Sizes.p20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                          width: 2,
                        ),
                      ),
                      child: InitialsAvatar(name: livreur.fullName, size: 66),
                    ),
                    gapW16,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            livreur.fullName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          gapH4,
                          Row(
                            children: [
                              AppIcon(
                                AppIcons.phone,
                                size: 14,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              gapW4,
                              Text(
                                formatPhoneDisplay(livreur.phone),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          gapH12,
                          _StatusPill(status: livreur.status),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            gapH24,

            // ---- Raccourcis ----
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _LinkRow(
                    icon: AppIcons.star,
                    color: AppColors.amber,
                    title: 'Mes avis',
                    trailing: livreur.ratingCount == 0
                        ? 'Aucun'
                        : '${livreur.rating.toStringAsFixed(1)} · '
                              '${livreur.ratingCount} avis',
                    onTap: () => context.pushNamed(AppRoute.reviews.name),
                  ),
                  Divider(
                    indent: 64,
                    endIndent: Sizes.p16,
                    color: context.palette.border,
                  ),
                  _LinkRow(
                    icon: AppIcons.settings,
                    color: context.palette.primary,
                    title: 'Paramètres',
                    trailing: 'Apparence, notifications…',
                    onTap: () => context.pushNamed(AppRoute.settings.name),
                  ),
                ],
              ),
            ),
            gapH24,

            // ---- Moto ----
            SectionTitle(
              'Ma moto',
              actionLabel: 'Modifier',
              onAction: () async {
                final saved = await showEditMotoSheet(context, livreur);
                if (saved && context.mounted) {
                  Toast.success(context, 'Moto mise à jour.');
                }
              },
            ),
            gapH8,
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: Sizes.p4),
              child: Column(
                children: [
                  _InfoRow(
                    icon: AppIcons.moto,
                    label: 'Modèle',
                    value: moto.isEmpty ? livreur.motoType : moto,
                  ),
                  if (livreur.motoColor.isNotEmpty) ...[
                    const _RowDivider(),
                    _InfoRow(
                      icon: AppIcons.palette,
                      label: 'Couleur',
                      value: livreur.motoColor,
                    ),
                  ],
                  if (livreur.motoYear != null) ...[
                    const _RowDivider(),
                    _InfoRow(
                      icon: AppIcons.calendar,
                      label: 'Année',
                      value: '${livreur.motoYear}',
                    ),
                  ],
                  if (plaque != null && plaque.isNotEmpty) ...[
                    const _RowDivider(),
                    _InfoRow(
                      icon: AppIcons.plate,
                      label: 'Plaque',
                      value: plaque,
                    ),
                  ],
                ],
              ),
            ),
            gapH24,

            // ---- Pièce d'identité ----
            const SectionTitle("Pièce d'identité"),
            gapH8,
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: Sizes.p4),
              child: Column(
                children: [
                  _InfoRow(
                    icon: AppIcons.idCard,
                    label: 'Type',
                    value: livreur.idType,
                  ),
                  const _RowDivider(),
                  _InfoRow(
                    icon: AppIcons.hash,
                    label: 'Numéro',
                    value: livreur.idNumber,
                  ),
                ],
              ),
            ),
            gapH24,

            // ---- Sécurité ----
            const SectionTitle('Sécurité'),
            gapH8,
            AppCard(
              padding: EdgeInsets.zero,
              onTap: () async {
                final changed = await showChangePasswordSheet(context);
                if (changed && context.mounted) {
                  Toast.success(context, 'Mot de passe changé.');
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Sizes.p16,
                  vertical: Sizes.p12,
                ),
                child: Row(
                  children: [
                    IconTile(
                      icon: AppIcons.lock,
                      color: context.palette.textSecondary,
                      size: 34,
                      radius: Radii.sm,
                      background: context.palette.surfaceMuted,
                    ),
                    gapW16,
                    Expanded(
                      child: Text(
                        'Changer mon mot de passe',
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    AppIcon(
                      AppIcons.forward,
                      size: 18,
                      color: context.palette.textMuted,
                    ),
                  ],
                ),
              ),
            ),
            gapH32,
            AppButton(
              label: 'Se déconnecter',
              icon: AppIcons.logout,
              variant: AppButtonVariant.outlined,
              onPressed: () => _confirmSignOut(context, ref),
            ),
          ]),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final LivreurStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch (status) {
      LivreurStatus.valide => (
        'Compte validé',
        AppIcons.verified,
        const Color(0xFF3DDC8B),
      ),
      LivreurStatus.suspendu => (
        'Compte suspendu',
        AppIcons.block,
        const Color(0xFFFF8A80),
      ),
      LivreurStatus.pending => (
        'En cours de validation',
        AppIcons.hourglass,
        AppColors.secondaryLight,
      ),
    };
    return HeroChip(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, color: color),
          gapW4,
          Text(label),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(indent: 64, endIndent: Sizes.p16);
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final AppIconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Sizes.p16,
        vertical: Sizes.p12,
      ),
      child: Row(
        children: [
          IconTile(
            icon: icon,
            color: context.palette.textSecondary,
            size: 34,
            radius: Radii.sm,
            background: context.palette.surfaceMuted,
          ),
          gapW16,
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
          gapW12,
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.trailing,
    required this.onTap,
  });

  final AppIconData icon;
  final Color color;
  final String title;
  final String trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Radii.lg),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Sizes.p16,
          vertical: Sizes.p12,
        ),
        child: Row(
          children: [
            IconTile(icon: icon, color: color, size: 34, radius: Radii.sm),
            gapW16,
            Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
            Text(trailing, style: theme.textTheme.bodySmall),
            gapW8,
            AppIcon(
              AppIcons.forward,
              size: 18,
              color: context.palette.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

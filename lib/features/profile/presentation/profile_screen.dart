import 'package:dksoft_market_livreur/core/data/livreur_repository.dart';
import 'package:dksoft_market_livreur/core/domain/livreur_model.dart';
import 'package:dksoft_market_livreur/core/widgets/app_card.dart';
import 'package:dksoft_market_livreur/core/widgets/pill.dart';
import 'package:dksoft_market_livreur/features/authentication/data/auth_repository.dart';
import 'package:dksoft_market_livreur/features/dashboard/presentation/dashboard_screen.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onglet « Profil » : identité, moto, statut du compte et déconnexion.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Se déconnecter ?'),
        content: const Text('Vous ne recevrez plus de courses.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authRepositoryProvider).signOut();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final livreur = ref.watch(currentLivreurProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Mon profil')),
      body: SafeArea(
        child: livreur == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(Sizes.p16),
                children: [
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: AppColors.secondary,
                        child: Text(
                          initialsOf(livreur.fullName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 28,
                          ),
                        ),
                      ),
                      gapH12,
                      Text(
                        livreur.fullName,
                        style: theme.textTheme.headlineSmall,
                      ),
                      gapH8,
                      _StatusPill(status: livreur.status),
                    ],
                  ),
                  gapH24,
                  AppCard(
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Téléphone',
                          value: livreur.phone,
                        ),
                        const _Divider(),
                        _InfoRow(
                          icon: Icons.two_wheeler_rounded,
                          label: 'Moto',
                          value:
                              [
                                    livreur.motoMake,
                                    livreur.motoModel,
                                    livreur.motoColor,
                                  ]
                                  .where((e) => e.isNotEmpty)
                                  .join(' ')
                                  .ifEmpty(livreur.motoType),
                        ),
                        if (livreur.plaque != null &&
                            livreur.plaque!.isNotEmpty) ...[
                          const _Divider(),
                          _InfoRow(
                            icon: Icons.pin_outlined,
                            label: 'Plaque',
                            value: livreur.plaque!,
                          ),
                        ],
                        const _Divider(),
                        _InfoRow(
                          icon: Icons.inventory_2_outlined,
                          label: 'Livraisons effectuées',
                          value: '${livreur.livraisonsEffectuees}',
                        ),
                        const _Divider(),
                        _InfoRow(
                          icon: Icons.star_rounded,
                          label: 'Note',
                          value: livreur.livraisonsEffectuees == 0
                              ? '—'
                              : livreur.rating.toStringAsFixed(1),
                        ),
                      ],
                    ),
                  ),
                  gapH24,
                  SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmSignOut(context, ref),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Se déconnecter'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final LivreurStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg) = switch (status) {
      LivreurStatus.valide => (
        'Compte validé',
        AppColors.success,
        AppColors.successLight,
      ),
      LivreurStatus.suspendu => (
        'Compte suspendu',
        AppColors.error,
        AppColors.errorLight,
      ),
      LivreurStatus.pending => (
        'En cours de validation',
        AppColors.warning,
        AppColors.warningLight,
      ),
    };
    return Pill(label: label, foreground: fg, background: bg);
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: Sizes.p12),
    child: Divider(),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 22, color: AppColors.primary),
        gapW12,
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.textSecondaryLight,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        gapW12,
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

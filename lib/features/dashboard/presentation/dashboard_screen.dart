import 'package:dksoft_market_livreur/core/data/livreur_repository.dart';
import 'package:dksoft_market_livreur/core/domain/livreur_model.dart';
import 'package:dksoft_market_livreur/features/authentication/data/auth_repository.dart';
import 'package:dksoft_market_livreur/features/dashboard/presentation/availability_controller.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/formatters/currency_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tableau de bord du motard (§3.4, §13) : disponibilité, statistiques et
/// résumé du profil. Les courses arrivent à l'étape 5.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final livreurAsync = ref.watch(currentLivreurProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dksoft Livreur'),
        actions: [
          IconButton(
            tooltip: 'Se déconnecter',
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
            icon: const Icon(Icons.logout_rounded),
            color: AppColors.textPrimaryLight,
          ),
        ],
      ),
      body: SafeArea(
        child: livreurAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) =>
              const Center(child: Text('Impossible de charger votre profil.')),
          data: (livreur) => livreur == null
              ? const Center(child: Text('Profil introuvable.'))
              : _DashboardBody(livreur: livreur),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.livreur});

  final LivreurModel livreur;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstName = livreur.fullName.split(' ').first;

    return ListView(
      padding: const EdgeInsets.all(Sizes.p20),
      children: [
        Text('Bonjour $firstName', style: theme.textTheme.headlineMedium),
        gapH20,
        _AvailabilityCard(disponible: livreur.disponible),
        gapH20,
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.local_shipping_outlined,
                label: 'Livraisons',
                value: '${livreur.livraisonsEffectuees}',
              ),
            ),
            gapW12,
            Expanded(
              child: _StatTile(
                icon: Icons.payments_outlined,
                label: 'Gains',
                value: CurrencyFormatter.formatUsd(livreur.gains),
              ),
            ),
            gapW12,
            Expanded(
              child: _StatTile(
                icon: Icons.star_outline_rounded,
                label: 'Note',
                value: livreur.livraisonsEffectuees == 0
                    ? '—'
                    : livreur.rating.toStringAsFixed(1),
              ),
            ),
          ],
        ),
        gapH20,
        _ProfileCard(livreur: livreur),
      ],
    );
  }
}

class _AvailabilityCard extends ConsumerWidget {
  const _AvailabilityCard({required this.disponible});

  final bool disponible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(availabilityControllerProvider).isLoading;

    ref.listen<AsyncValue<void>>(availabilityControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${next.error}')));
      }
    });

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(Sizes.p20),
      decoration: BoxDecoration(
        color: disponible ? AppColors.successLight : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: disponible ? AppColors.success : AppColors.dividerLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: disponible ? AppColors.success : AppColors.textHintLight,
            ),
          ),
          gapW12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  disponible
                      ? 'Vous êtes disponible'
                      : 'Vous êtes indisponible',
                  style: theme.textTheme.titleMedium,
                ),
                gapH4,
                Text(
                  disponible
                      ? 'Les nouvelles courses vous seront proposées.'
                      : 'Passez disponible pour recevoir des courses.',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          gapW8,
          if (isLoading)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            )
          else
            Switch.adaptive(
              value: disponible,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.success,
              onChanged: (value) => ref
                  .read(availabilityControllerProvider.notifier)
                  .setDisponible(value),
            ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
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

    return Container(
      padding: const EdgeInsets.all(Sizes.p12),
      decoration: BoxDecoration(
        color: AppColors.cardLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          gapH8,
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: theme.textTheme.titleMedium),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.livreur});

  final LivreurModel livreur;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final plaque = livreur.plaque;

    return Container(
      padding: const EdgeInsets.all(Sizes.p16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.dividerLight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mon profil', style: theme.textTheme.titleMedium),
          gapH12,
          _InfoRow(icon: Icons.phone_outlined, text: livreur.phone),
          gapH8,
          _InfoRow(
            icon: Icons.two_wheeler,
            text: plaque == null
                ? livreur.motoType
                : '${livreur.motoType} · $plaque',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondaryLight),
        gapW12,
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

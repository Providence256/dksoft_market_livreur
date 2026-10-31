import 'package:dksoft_market_livreur/core/widgets/icon_tile.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/signup/signup_draft.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/helpers/phone_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Étape 4 : récapitulatif, modifiable section par section, et acceptation
/// des conditions.
class ReviewStep extends ConsumerWidget {
  const ReviewStep({super.key, required this.onEdit});

  final void Function(int step) onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final draft = ref.watch(signUpDraftProvider);
    final notifier = ref.read(signUpDraftProvider.notifier);

    final phone = normalizeCongoPhone(draft.phone);
    final issueDate = draft.idIssueDate;
    final plaque = draft.plaque.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Section(
          icon: AppIcons.phone,
          title: 'Compte',
          onEdit: () => onEdit(0),
          rows: [
            (
              'Téléphone',
              phone == null ? draft.phone : formatPhoneDisplay(phone),
            ),
          ],
        ),
        _Section(
          icon: AppIcons.idCard,
          title: "Pièce d'identité",
          onEdit: () => onEdit(1),
          rows: [
            ('Nom complet', draft.fullName),
            ('Pièce', '${draft.idType ?? '—'} · ${draft.idCountry}'),
            ('Numéro', draft.idNumber.trim()),
            (
              'Délivrée le',
              issueDate == null ? '—' : formatIssueDate(issueDate),
            ),
          ],
        ),
        _Section(
          icon: AppIcons.moto,
          title: 'Moto',
          onEdit: () => onEdit(2),
          rows: [
            ('Modèle', '${draft.motoMake ?? ''} ${draft.motoModel.trim()}'),
            ('Couleur', draft.motoColor ?? '—'),
            ('Année', draft.motoYear),
            if (plaque.isNotEmpty) ('Plaque', plaque),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(Sizes.p16),
          decoration: BoxDecoration(
            color: context.palette.infoSoft,
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppIcon(AppIcons.info, size: 20, color: AppColors.info),
              gapW12,
              Expanded(
                child: Text(
                  "Après l'inscription, vous enverrez la photo de votre pièce "
                  "d'identité. L'administration vérifie ensuite votre profil "
                  'avant de vous donner accès aux courses.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.palette.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        gapH16,
        InkWell(
          borderRadius: BorderRadius.circular(Radii.sm),
          onTap: () => notifier.update(
            (d) => d.copyWith(acceptedTerms: !d.acceptedTerms),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Sizes.p4),
            child: Row(
              children: [
                Checkbox(
                  value: draft.acceptedTerms,
                  onChanged: (value) => notifier.update(
                    (d) => d.copyWith(acceptedTerms: value ?? false),
                  ),
                ),
                Expanded(
                  child: Text(
                    "J'accepte les conditions d'utilisation de Dksoft Market",
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.onEdit,
    required this.rows,
  });

  final AppIconData icon;
  final String title;
  final VoidCallback onEdit;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: Sizes.p12),
      padding: const EdgeInsets.fromLTRB(
        Sizes.p16,
        Sizes.p12,
        Sizes.p8,
        Sizes.p16,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: context.palette.border),
        borderRadius: BorderRadius.circular(Radii.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: icon, color: context.palette.primary, size: 36),
              gapW12,
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
              TextButton(onPressed: onEdit, child: const Text('Modifier')),
            ],
          ),
          gapH8,
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.only(top: 6, right: Sizes.p8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 104,
                    child: Text(label, style: theme.textTheme.bodySmall),
                  ),
                  Expanded(
                    child: Text(
                      value.trim().isEmpty ? '—' : value,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

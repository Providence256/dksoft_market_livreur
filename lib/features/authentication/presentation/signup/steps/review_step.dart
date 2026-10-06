import 'package:dksoft_market_livreur/features/authentication/presentation/signup/signup_draft.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/helpers/phone_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
          title: "Pièce d'identité",
          onEdit: () => onEdit(1),
          rows: [
            ('Nom complet', draft.fullName),
            ('Pièce', '${draft.idType ?? '—'} - ${draft.idCountry}'),
            ('Numéro', draft.idNumber.trim()),
            (
              'Délivrée le',
              issueDate == null ? '—' : formatIssueDate(issueDate),
            ),
          ],
        ),
        _Section(
          title: 'Moto',
          onEdit: () => onEdit(2),
          rows: [
            (
              'Véhicule',
              'Moto ${draft.motoMake ?? ''} ${draft.motoModel.trim()}',
            ),
            ('Couleur', draft.motoColor ?? '—'),
            ('Année', draft.motoYear),
            if (plaque.isNotEmpty) ('Plaque', plaque),
          ],
        ),
        gapH8,
        Container(
          padding: const EdgeInsets.all(Sizes.p12),
          decoration: BoxDecoration(
            color: AppColors.cardLight,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                size: 20,
                color: AppColors.primary,
              ),
              gapW8,
              Expanded(
                child: Text(
                  "Après l'inscription, vous enverrez la photo de votre pièce "
                  "d'identité. L'administration vérifie ensuite votre profil "
                  'avant de vous donner accès aux courses.',
                  style: theme.textTheme.labelMedium,
                ),
              ),
            ],
          ),
        ),
        gapH12,
        InkWell(
          onTap: () => notifier.update(
            (d) => d.copyWith(acceptedTerms: !d.acceptedTerms),
          ),
          child: Row(
            children: [
              Checkbox(
                value: draft.acceptedTerms,
                activeColor: AppColors.primary,
                onChanged: (value) => notifier.update(
                  (d) => d.copyWith(acceptedTerms: value ?? false),
                ),
              ),
              Expanded(
                child: Text(
                  "J'accepte les conditions d'utilisation de Dksoft Market",
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.onEdit,
    required this.rows,
  });

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
        Sizes.p8,
        Sizes.p8,
        Sizes.p12,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.dividerLight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
              TextButton(
                onPressed: onEdit,
                child: Text(
                  'Modifier',
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium!.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.only(top: 4, right: Sizes.p8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(value, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:dksoft_market_livreur/core/widgets/app_fields.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/signup/signup_draft.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/signup/signup_options.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Étape 2 : pièce d'identité (pays, type, nom, numéro, date).
class IdentityStep extends ConsumerStatefulWidget {
  const IdentityStep({super.key});

  @override
  ConsumerState<IdentityStep> createState() => _IdentityStepState();
}

class _IdentityStepState extends ConsumerState<IdentityStep> {
  late final TextEditingController _lastName;
  late final TextEditingController _firstName;
  late final TextEditingController _idNumber;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(signUpDraftProvider);
    _lastName = TextEditingController(text: draft.lastName);
    _firstName = TextEditingController(text: draft.firstName);
    _idNumber = TextEditingController(text: draft.idNumber);
  }

  @override
  void dispose() {
    _lastName.dispose();
    _firstName.dispose();
    _idNumber.dispose();
    super.dispose();
  }

  SignUpDraftNotifier get _notifier => ref.read(signUpDraftProvider.notifier);

  Future<void> _pickCountry() async {
    final selected = await showOptionsSheet(
      context,
      title: 'Pays de délivrance',
      options: kIdCountries,
      selected: ref.read(signUpDraftProvider).idCountry,
    );
    if (selected != null) {
      _notifier.update((draft) => draft.copyWith(idCountry: selected));
    }
  }

  Future<void> _pickType() async {
    final selected = await showOptionsSheet(
      context,
      title: 'Type de pièce',
      options: kIdTypes,
      selected: ref.read(signUpDraftProvider).idType,
    );
    if (selected != null) {
      _notifier.update((draft) => draft.copyWith(idType: selected));
    }
  }

  Future<void> _pickIssueDate() async {
    final now = DateTime.now();
    final current = ref.read(signUpDraftProvider).idIssueDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(1980),
      lastDate: now,
      helpText: 'Date de délivrance',
    );
    if (picked != null) {
      _notifier.update((draft) => draft.copyWith(idIssueDate: picked));
    }
  }

  String _numberLabel(String? idType) {
    return switch (idType) {
      'Permis de conduire' => 'Numéro du permis',
      "Carte d'électeur" => 'Numéro de la carte',
      'Passeport' => 'Numéro du passeport',
      _ => 'Numéro de la pièce',
    };
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(signUpDraftProvider);
    final issueDate = draft.idIssueDate;

    return Column(
      spacing: Sizes.p20,
      children: [
        AppSelectField(
          label: 'Pays de délivrance',
          value: draft.idCountry,
          onTap: _pickCountry,
        ),
        AppSelectField(
          label: 'Type de pièce',
          value: draft.idType,
          placeholder: "Carte d'électeur, permis…",
          onTap: _pickType,
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppTextField(
                label: 'Nom',
                controller: _lastName,
                hintText: 'Musaghi',
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                onChanged: (value) =>
                    _notifier.update((d) => d.copyWith(lastName: value)),
              ),
            ),
            gapW12,
            Expanded(
              child: AppTextField(
                label: 'Prénom',
                controller: _firstName,
                hintText: 'Providence',
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                onChanged: (value) =>
                    _notifier.update((d) => d.copyWith(firstName: value)),
              ),
            ),
          ],
        ),
        AppTextField(
          label: _numberLabel(draft.idType),
          controller: _idNumber,
          prefixIcon: AppIcons.idCard,
          hintText: 'Ex : FF056HGJ',
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) =>
              _notifier.update((d) => d.copyWith(idNumber: value)),
        ),
        AppSelectField(
          label: 'Date de délivrance',
          value: issueDate == null ? null : formatIssueDate(issueDate),
          placeholder: 'Choisir une date',
          trailingIcon: AppIcons.calendar,
          onTap: _pickIssueDate,
        ),
      ],
    );
  }
}

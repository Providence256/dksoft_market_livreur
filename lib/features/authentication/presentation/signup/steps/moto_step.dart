import 'package:dksoft_market_livreur/core/widgets/app_fields.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/signup/signup_draft.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/signup/signup_options.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Étape 3 : la moto. Les champs se débloquent dans l'ordre (marque,
/// modèle, couleur, année), la plaque reste facultative.
class MotoStep extends ConsumerStatefulWidget {
  const MotoStep({super.key});

  @override
  ConsumerState<MotoStep> createState() => _MotoStepState();
}

class _MotoStepState extends ConsumerState<MotoStep> {
  late final TextEditingController _model;
  late final TextEditingController _year;
  late final TextEditingController _plaque;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(signUpDraftProvider);
    _model = TextEditingController(text: draft.motoModel);
    _year = TextEditingController(text: draft.motoYear);
    _plaque = TextEditingController(text: draft.plaque);
  }

  @override
  void dispose() {
    _model.dispose();
    _year.dispose();
    _plaque.dispose();
    super.dispose();
  }

  SignUpDraftNotifier get _notifier => ref.read(signUpDraftProvider.notifier);

  Future<void> _pickMake() async {
    final selected = await showOptionsSheet(
      context,
      title: 'Marque de la moto',
      options: kMotoMakes,
      selected: ref.read(signUpDraftProvider).motoMake,
    );
    if (selected != null) {
      _notifier.update((draft) => draft.copyWith(motoMake: selected));
    }
  }

  Future<void> _pickColor() async {
    final selected = await showOptionsSheet(
      context,
      title: 'Couleur de la moto',
      options: kMotoColors,
      selected: ref.read(signUpDraftProvider).motoColor,
    );
    if (selected != null) {
      _notifier.update((draft) => draft.copyWith(motoColor: selected));
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(signUpDraftProvider);

    // Un champ n'est utilisable que si tous les précédents sont remplis.
    final makeDone = draft.motoMake != null;
    final modelDone = draft.motoModel.trim().isNotEmpty;
    final colorEnabled = makeDone && modelDone;
    final yearEnabled = colorEnabled && draft.motoColor != null;

    return Column(
      spacing: Sizes.p20,
      children: [
        const AppSelectField(
          label: 'Type de véhicule',
          value: 'Moto',
          trailingIcon: AppIcons.lock,
          onTap: null,
        ),
        AppSelectField(
          label: 'Marque',
          value: draft.motoMake,
          placeholder: 'Honda, Yamaha, TVS…',
          onTap: _pickMake,
        ),
        AppTextField(
          label: 'Modèle',
          controller: _model,
          enabled: makeDone,
          hintText: 'Ex : CG 125, YBR 125',
          textCapitalization: TextCapitalization.words,
          validator: (value) =>
              (value ?? '').trim().length < 2 ? 'Entrez le modèle' : null,
          onChanged: (value) =>
              _notifier.update((d) => d.copyWith(motoModel: value)),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AppSelectField(
                label: 'Couleur',
                value: draft.motoColor,
                enabled: colorEnabled,
                onTap: _pickColor,
              ),
            ),
            gapW12,
            Expanded(
              child: AppTextField(
                label: 'Année',
                controller: _year,
                enabled: yearEnabled,
                hintText: '2020',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                validator: (value) {
                  if ((value ?? '').length < 4) return null;
                  return draft.isMotoYearValid
                      ? null
                      : 'Entre ${SignUpDraft.minMotoYear} et '
                            '${DateTime.now().year}';
                },
                onChanged: (value) =>
                    _notifier.update((d) => d.copyWith(motoYear: value)),
              ),
            ),
          ],
        ),
        AppTextField(
          label: "Plaque d'immatriculation (facultatif)",
          controller: _plaque,
          prefixIcon: AppIcons.plate,
          hintText: 'Ex : 1234AB01',
          textCapitalization: TextCapitalization.characters,
          onChanged: (value) =>
              _notifier.update((d) => d.copyWith(plaque: value)),
        ),
      ],
    );
  }
}

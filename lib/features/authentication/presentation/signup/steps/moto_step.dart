import 'package:dksoft_market_livreur/features/authentication/presentation/signup/signup_draft.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/signup/signup_options.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/signup/widgets/progress_row.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/signup/widgets/step_select_row.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/signup/widgets/step_text_field.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/widgets/auth_text_field.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

    // Une ligne n'est utilisable que si toutes les précédentes sont remplies.
    final makeDone = draft.motoMake != null;
    final modelDone = draft.motoModel.trim().isNotEmpty;
    final colorDone = draft.motoColor != null;
    final yearDone = draft.isMotoYearValid;

    final colorEnabled = makeDone && modelDone;
    final yearEnabled = makeDone && modelDone && colorDone;
    final plateEnabled = yearEnabled && yearDone;

    // Prochaine ligne à remplir (point orange).
    final activeMake = !makeDone;
    final activeModel = makeDone && !modelDone;
    final activeColor = makeDone && modelDone && !colorDone;
    final activeYear = makeDone && modelDone && colorDone && !yearDone;

    return Column(
      spacing: 14,
      children: [
        // Type de véhicule : imposé.
        ProgressRow(
          done: true,
          active: false,
          child: StepSelectRow(
            label: 'Type de véhicule',
            value: 'Moto',
            underline: false,
            onTap: null,
            trailing: const Icon(
              Icons.lock_outline,
              size: 20,
              color: AppColors.textHintLight,
            ),
          ),
        ),
        ProgressRow(
          done: makeDone,
          active: activeMake,
          child: StepSelectRow(
            label: 'Marque',
            value: draft.motoMake,
            underline: false,
            enabled: true,
            onTap: _pickMake,
          ),
        ),
        ProgressRow(
          done: modelDone,
          active: activeModel,
          child: AuthTextField(
            label: 'Modèle',
            controller: _model,
            hintText: 'Ex : CG 125, YBR 125',
            textCapitalization: TextCapitalization.words,
            validator: (value) =>
                (value ?? '').trim().length < 2 ? 'Entrez le Modèle' : null,
            onchanged: (value) =>
                _notifier.update((d) => d.copyWith(motoModel: value)),
          ),
        ),

        ProgressRow(
          done: colorDone,
          active: activeColor,
          child: StepSelectRow(
            label: 'Couleur',
            value: draft.motoColor,
            underline: false,
            enabled: colorEnabled,
            onTap: _pickColor,
          ),
        ),

        ProgressRow(
          done: yearDone,
          active: activeYear,
          child: StepTextField(
            label: 'Année de fabrication',
            controller: _year,
            enabled: yearEnabled,
            underline: false,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(4),
            ],
            validator: (value) {
              final text = value ?? '';
              if (text.length < 4) return null;
              return draft.isMotoYearValid
                  ? null
                  : 'Année entre ${SignUpDraft.minMotoYear} et '
                        '${DateTime.now().year}';
            },
            onChanged: (value) =>
                _notifier.update((d) => d.copyWith(motoYear: value)),
          ),
        ),
        ProgressRow(
          done: plateEnabled,
          active: false,
          child: AuthTextField(
            label: "Plaque d'immatriculation (facultatif)",
            controller: _plaque,
            textCapitalization: TextCapitalization.characters,
            onchanged: (value) =>
                _notifier.update((d) => d.copyWith(plaque: value)),
          ),
        ),
      ],
    );
  }
}

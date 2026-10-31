import 'package:dksoft_market_livreur/core/data/livreur_repository.dart';
import 'package:dksoft_market_livreur/core/domain/livreur_model.dart';
import 'package:dksoft_market_livreur/core/widgets/app_button.dart';
import 'package:dksoft_market_livreur/core/widgets/app_fields.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/signup/signup_draft.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/signup/signup_options.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modifier sa moto (changement de moto, faute à l'inscription…). Renvoie
/// true si c'est enregistré.
Future<bool> showEditMotoSheet(BuildContext context, LivreurModel livreur) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _EditMotoSheet(livreur: livreur),
  ).then((saved) => saved ?? false);
}

class _EditMotoSheet extends ConsumerStatefulWidget {
  const _EditMotoSheet({required this.livreur});

  final LivreurModel livreur;

  @override
  ConsumerState<_EditMotoSheet> createState() => _EditMotoSheetState();
}

class _EditMotoSheetState extends ConsumerState<_EditMotoSheet> {
  final _formKey = GlobalKey<FormState>();
  late String? _make = widget.livreur.motoMake.isEmpty
      ? null
      : widget.livreur.motoMake;
  late String? _color = widget.livreur.motoColor.isEmpty
      ? null
      : widget.livreur.motoColor;
  late final _model = TextEditingController(text: widget.livreur.motoModel);
  late final _year = TextEditingController(
    text: widget.livreur.motoYear?.toString() ?? '',
  );
  late final _plaque = TextEditingController(text: widget.livreur.plaque ?? '');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _model.dispose();
    _year.dispose();
    _plaque.dispose();
    super.dispose();
  }

  Future<void> _pick({
    required String title,
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onSelected,
  }) async {
    final value = await showOptionsSheet(
      context,
      title: title,
      options: options,
      selected: selected,
    );
    if (value != null) setState(() => onSelected(value));
  }

  Future<void> _save() async {
    final valid = _formKey.currentState!.validate();
    if (!valid || _make == null || _color == null) {
      setState(() => _error = 'Complétez la marque et la couleur.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });

    final uid = widget.livreur.id;
    final plaque = _plaque.text.trim();
    try {
      await ref
          .read(livreurRepositoryProvider)
          .updateMoto(
            uid: uid,
            make: _make!,
            model: _model.text.trim(),
            color: _color!,
            year: int.parse(_year.text),
            plaque: plaque.isEmpty ? null : plaque.toUpperCase(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              "Impossible d'enregistrer. Vérifiez votre connexion et réessayez.",
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Sizes.screenPadding,
            0,
            Sizes.screenPadding,
            Sizes.p20,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: Sizes.p16,
              children: [
                Text('Ma moto', style: theme.textTheme.titleLarge),
                AppSelectField(
                  label: 'Marque',
                  value: _make,
                  onTap: () => _pick(
                    title: 'Marque de la moto',
                    options: kMotoMakes,
                    selected: _make,
                    onSelected: (value) => _make = value,
                  ),
                ),
                AppTextField(
                  label: 'Modèle',
                  controller: _model,
                  hintText: 'Ex : CG 125, YBR 125',
                  textCapitalization: TextCapitalization.words,
                  validator: (value) => (value ?? '').trim().length < 2
                      ? 'Entrez le modèle'
                      : null,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppSelectField(
                        label: 'Couleur',
                        value: _color,
                        onTap: () => _pick(
                          title: 'Couleur de la moto',
                          options: kMotoColors,
                          selected: _color,
                          onSelected: (value) => _color = value,
                        ),
                      ),
                    ),
                    gapW12,
                    Expanded(
                      child: AppTextField(
                        label: 'Année',
                        controller: _year,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        validator: (value) {
                          final year = int.tryParse(value ?? '');
                          return year == null ||
                                  year < SignUpDraft.minMotoYear ||
                                  year > DateTime.now().year
                              ? 'Année invalide'
                              : null;
                        },
                      ),
                    ),
                  ],
                ),
                AppTextField(
                  label: "Plaque d'immatriculation (facultatif)",
                  controller: _plaque,
                  prefixIcon: AppIcons.plate,
                  textCapitalization: TextCapitalization.characters,
                ),
                Text(
                  "Le changement est enregistré et signalé à l'administration.",
                  style: theme.textTheme.bodySmall,
                ),
                if (_error != null)
                  Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                AppButton(
                  label: 'Enregistrer',
                  icon: AppIcons.check,
                  loading: _loading,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

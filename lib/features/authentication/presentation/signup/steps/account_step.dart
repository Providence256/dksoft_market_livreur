import 'package:dksoft_market_livreur/core/widgets/app_fields.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/signup/signup_draft.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Étape 1 : téléphone et mot de passe.
class AccountStep extends ConsumerStatefulWidget {
  const AccountStep({super.key});

  @override
  ConsumerState<AccountStep> createState() => _AccountStepState();
}

class _AccountStepState extends ConsumerState<AccountStep> {
  late final TextEditingController _phone;
  late final TextEditingController _password;
  late final TextEditingController _confirm;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(signUpDraftProvider);
    _phone = TextEditingController(text: draft.phone);
    _password = TextEditingController(text: draft.password);
    _confirm = TextEditingController(text: draft.confirmPassword);
  }

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  SignUpDraftNotifier get _notifier => ref.read(signUpDraftProvider.notifier);

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: Sizes.p20,
      children: [
        AppTextField(
          label: 'Téléphone',
          controller: _phone,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          hintText: '995 415 641',
          prefix: const PhonePrefix(),
          validator: (value) {
            final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
            return digits.length < 9 ? 'Numéro invalide' : null;
          },
          onChanged: (value) =>
              _notifier.update((d) => d.copyWith(phone: value)),
        ),
        AppTextField(
          label: 'Mot de passe',
          controller: _password,
          obscureText: _obscure,
          textInputAction: TextInputAction.next,
          prefixIcon: AppIcons.lock,
          hintText: 'Au moins 6 caractères',
          suffix: IconButton(
            tooltip: _obscure ? 'Afficher' : 'Masquer',
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: AppIcon(_obscure ? AppIcons.eye : AppIcons.eyeOff, size: 20),
          ),
          validator: (value) =>
              (value ?? '').length < 6 ? 'Au moins 6 caractères' : null,
          onChanged: (value) =>
              _notifier.update((d) => d.copyWith(password: value)),
        ),
        AppTextField(
          label: 'Confirmer le mot de passe',
          controller: _confirm,
          obscureText: _obscure,
          textInputAction: TextInputAction.done,
          prefixIcon: AppIcons.lock,
          validator: (value) => value != _password.text
              ? 'Les mots de passe ne correspondent pas'
              : null,
          onChanged: (value) =>
              _notifier.update((d) => d.copyWith(confirmPassword: value)),
        ),
      ],
    );
  }
}

import 'package:dksoft_market_livreur/features/authentication/presentation/signup/signup_draft.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/widgets/auth_text_field.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

/// Étape 1 : téléphone, commune et mot de passe.
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
      children: [
        AuthTextField(
          label: 'TÉLÉPHONE',
          controller: _phone,
          keyboardType: TextInputType.phone,
          hintText: '995 415 641',
          prefix: const _CountryPrefix(),
          validator: (value) {
            final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
            return digits.length < 9 ? 'Numéro invalide' : null;
          },
          onchanged: (value) =>
              _notifier.update((d) => d.copyWith(phone: value)),
        ),

        const SizedBox(height: 14),
        AuthTextField(
          label: 'MOT DE PASSE',
          controller: _password,
          obscureText: _obscure,
          prefix: Icon(Icons.lock_outline_rounded, color: Colors.grey[500]),
          suffix: IconButton(
            onPressed: () => setState(() {
              _obscure = !_obscure;
            }),
            icon: HugeIcon(
              color: AppColors.primary,
              icon: _obscure
                  ? HugeIcons.strokeRoundedViewOffSlash
                  : HugeIcons.strokeRoundedView,
            ),
          ),

          validator: (value) =>
              (value ?? '').length < 6 ? 'Au moins 6 caractères' : null,
          onchanged: (value) =>
              _notifier.update((d) => d.copyWith(password: value)),
        ),
        const SizedBox(height: 14),
        AuthTextField(
          label: 'CONFIRMER LE MOT DE PASSE',
          controller: _confirm,
          obscureText: _obscure,
          prefix: Icon(Icons.lock_outline_rounded, color: Colors.grey[500]),
          validator: (value) => value != _password.text
              ? 'Les mots de passe ne correspondent pas'
              : null,
          onchanged: (value) =>
              _notifier.update((d) => d.copyWith(confirmPassword: value)),
        ),
      ],
    );
  }
}

class _CountryPrefix extends StatelessWidget {
  const _CountryPrefix();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('🇨🇩', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 6),
        Text(
          '+243',
          style: Theme.of(
            context,
          ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 10),
        Container(width: 1, height: 22, color: Colors.grey.shade300),
      ],
    );
  }
}

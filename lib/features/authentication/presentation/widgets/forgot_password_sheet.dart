import 'package:dksoft_market_livreur/core/widgets/app_button.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/core/widgets/app_fields.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/core/widgets/icon_tile.dart';
import 'package:dksoft_market_livreur/features/authentication/data/auth_repository.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/helpers/phone_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mot de passe oublié : le motard laisse son numéro, l'administration le
/// rappelle avec un mot de passe provisoire.
Future<void> showForgotPasswordSheet(BuildContext context, {String? phone}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ForgotPasswordSheet(initialPhone: phone ?? ''),
  );
}

class _ForgotPasswordSheet extends ConsumerStatefulWidget {
  const _ForgotPasswordSheet({required this.initialPhone});

  final String initialPhone;

  @override
  ConsumerState<_ForgotPasswordSheet> createState() =>
      _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends ConsumerState<_ForgotPasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _phone = TextEditingController(text: widget.initialPhone);
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .requestPasswordReset(normalizeCongoPhone(_phone.text)!);
      if (mounted) setState(() => _sent = true);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Sizes.screenPadding,
            0,
            Sizes.screenPadding,
            Sizes.p20,
          ),
          child: _sent ? _done(theme) : _form(theme),
        ),
      ),
    );
  }

  Widget _form(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Mot de passe oublié', style: theme.textTheme.titleLarge),
          gapH8,
          Text(
            "Indiquez votre numéro : l'administration Dksoft Market vous "
            'appellera pour vérifier votre identité et vous donner un mot de '
            'passe provisoire.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: context.palette.textSecondary,
            ),
          ),
          gapH20,
          AppTextField(
            label: 'Téléphone',
            controller: _phone,
            keyboardType: TextInputType.phone,
            prefix: const PhonePrefix(),
            hintText: '995 415 641',
            validator: (value) => normalizeCongoPhone(value ?? '') == null
                ? 'Numéro invalide'
                : null,
          ),
          if (_error != null) ...[
            gapH12,
            Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.error,
              ),
            ),
          ],
          gapH20,
          AppButton(
            label: 'Envoyer la demande',
            icon: AppIcons.forward,
            loading: _loading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Widget _done(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const IconTile(
          icon: AppIcons.checkCircle,
          color: AppColors.success,
          size: 64,
          radius: Radii.xl,
        ),
        gapH16,
        Text(
          'Demande envoyée',
          style: theme.textTheme.titleLarge,
          textAlign: TextAlign.center,
        ),
        gapH8,
        Text(
          "Si ce numéro correspond à un compte motard, l'administration vous "
          'appellera. Une fois connecté, changez le mot de passe provisoire '
          'depuis votre profil.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: context.palette.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        gapH24,
        AppButton(
          label: 'Compris',
          variant: AppButtonVariant.tonal,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

import 'package:dksoft_market_livreur/core/widgets/app_button.dart';
import 'package:dksoft_market_livreur/core/widgets/app_fields.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/features/authentication/data/auth_repository.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Changer son mot de passe (par exemple le mot de passe provisoire donné
/// par l'administration). Renvoie true si c'est fait.
Future<bool> showChangePasswordSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _ChangePasswordSheet(),
  ).then((changed) => changed ?? false);
}

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() =>
      _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .changePassword(
            currentPassword: _current.text,
            newPassword: _new.text,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eye = IconButton(
      tooltip: _obscure ? 'Afficher' : 'Masquer',
      onPressed: () => setState(() => _obscure = !_obscure),
      icon: AppIcon(_obscure ? AppIcons.eye : AppIcons.eyeOff, size: 20),
    );

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
                Text(
                  'Changer mon mot de passe',
                  style: theme.textTheme.titleLarge,
                ),
                AppTextField(
                  label: 'Mot de passe actuel',
                  controller: _current,
                  obscureText: _obscure,
                  prefixIcon: AppIcons.lock,
                  suffix: eye,
                  validator: (value) => (value ?? '').isEmpty ? 'Requis' : null,
                ),
                AppTextField(
                  label: 'Nouveau mot de passe',
                  controller: _new,
                  obscureText: _obscure,
                  prefixIcon: AppIcons.lock,
                  hintText: 'Au moins 6 caractères',
                  validator: (value) =>
                      (value ?? '').length < 6 ? 'Au moins 6 caractères' : null,
                ),
                AppTextField(
                  label: 'Confirmer',
                  controller: _confirm,
                  obscureText: _obscure,
                  prefixIcon: AppIcons.lock,
                  validator: (value) => value != _new.text
                      ? 'Les mots de passe ne correspondent pas'
                      : null,
                ),
                if (_error != null)
                  Text(
                    _error!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                AppButton(
                  label: 'Changer le mot de passe',
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

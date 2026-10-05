import 'package:dksoft_market_livreur/features/authentication/presentation/auth_controller.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/widgets/auth_text_field.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/widgets/phone_prefix.dart';
import 'package:dksoft_market_livreur/routing/app_router.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

const _idTypes = ['Carte d\'électeur', 'Permis de conduire', 'Passeport'];

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _motoController = TextEditingController();
  final _plaqueController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _commune;
  String? _idType;
  bool _obscurePassword = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _motoController.dispose();
    _plaqueController.dispose();
    _idNumberController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _nullIfEmpty(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState!.validate();

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vous devez accepter les conditions d'utilisation."),
        ),
      );
      return;
    }
    if (!isValid) return;

    FocusScope.of(context).unfocus();

    final success = await ref
        .read(authControllerProvider.notifier)
        .signUp(
          fullName: _nameController.text.trim(),
          phone: '+243${_phoneController.text.replaceAll(' ', '')}',
          password: _passwordController.text,
          commune: _commune!,
          motoType: _motoController.text.trim(),
          idType: _idType!,
          idNumber: _idNumberController.text.trim(),
          plaque: _nullIfEmpty(_plaqueController.text),
          email: _nullIfEmpty(_emailController.text),
        );

    if (!mounted || !success) return;
    context.goNamed(AppRoute.home.name);
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final theme = Theme.of(context);

    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${next.error}')));
      }
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
        title: Text(
          'Devenir livreur',
          style: theme.textTheme.headlineSmall!.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rejoignez les livreurs Dksoft',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Votre profil sera vérifié par l'administration avant "
                  'de recevoir vos premières courses.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),

                const _SectionLabel('Vos informations'),
                const SizedBox(height: 10),
                AuthTextField(
                  label: 'NOM COMPLET',
                  controller: _nameController,
                  prefix: Icon(Icons.person_outline, color: Colors.grey[500]),
                  hintText: 'Providence Musaghi',
                  validator: (value) => (value ?? '').trim().length < 2
                      ? 'Entrez votre nom complet'
                      : null,
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  label: 'TÉLÉPHONE',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  hintText: '995 415 641',
                  prefix: const PhonePrefix(),
                  validator: (value) {
                    final digits = (value ?? '').replaceAll(
                      RegExp(r'[^0-9]'),
                      '',
                    );
                    return digits.length < 9 ? 'Numéro invalide' : null;
                  },
                ),
                const SizedBox(height: 10),
                const _SectionLabel('Sécurité'),
                const SizedBox(height: 10),
                AuthTextField(
                  label: 'MOT DE PASSE',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  prefix: Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.grey[500],
                  ),
                  suffix: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: HugeIcon(
                      color: AppColors.primary,
                      icon: _obscurePassword
                          ? HugeIcons.strokeRoundedViewOffSlash
                          : HugeIcons.strokeRoundedView,
                    ),
                  ),
                  validator: (value) =>
                      (value ?? '').length < 6 ? 'Au moins 6 caractères' : null,
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  label: 'CONFIRMER LE MOT DE PASSE',
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  prefix: Icon(
                    Icons.lock_outline_rounded,
                    color: Colors.grey[500],
                  ),
                  validator: (value) => value != _passwordController.text
                      ? 'Les mots de passe ne correspondent pas'
                      : null,
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Suivant',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}

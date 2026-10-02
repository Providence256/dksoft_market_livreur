import 'package:dksoft_market_livreur/features/authentication/presentation/auth_controller.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/widgets/auth_dropdown_field.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/widgets/auth_text_field.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/widgets/phone_prefix.dart';
import 'package:dksoft_market_livreur/routing/app_router.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/kinshasa_communes.dart';
import 'package:flutter/gestures.dart';
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
                const SizedBox(height: 20),

                const _SectionLabel('Vos informations'),
                const SizedBox(height: 10),
                AuthTextField(
                  label: 'NOM COMPLET',
                  controller: _nameController,
                  prefix: Icon(Icons.person_outline, color: Colors.grey[500]),
                  hintText: 'Jean Mukendi',
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
                const SizedBox(height: 14),
                AuthTextField(
                  label: 'E-MAIL (OPTIONNEL)',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  hintText: 'vous@exemple.com',
                  prefix: Icon(Icons.mail_outline, color: Colors.grey[500]),
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    return RegExp(r'^.+@.+\..+$').hasMatch(value)
                        ? null
                        : 'E-mail invalide';
                  },
                ),
                const SizedBox(height: 14),
                AuthDropdownField(
                  label: 'COMMUNE',
                  hintText: 'Choisir votre commune',
                  value: _commune,
                  items: kKinshasaCommunes,
                  prefix: Icon(
                    Icons.location_on_outlined,
                    color: Colors.grey[500],
                  ),
                  onChanged: (value) => setState(() => _commune = value),
                  validator: (value) =>
                      value == null ? 'Choisissez votre commune' : null,
                ),
                const SizedBox(height: 22),

                const _SectionLabel('Votre moto'),
                const SizedBox(height: 10),
                AuthTextField(
                  label: 'TYPE DE MOTO',
                  controller: _motoController,
                  hintText: 'Ex : Honda 125, Haojue 150',
                  prefix: Icon(Icons.two_wheeler, color: Colors.grey[500]),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Indiquez votre type de moto'
                      : null,
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  label: 'PLAQUE (OPTIONNEL)',
                  controller: _plaqueController,
                  hintText: '1234AB01',
                  prefix: Icon(
                    Icons.confirmation_number_outlined,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 22),

                const _SectionLabel("Pièce d'identité"),
                const SizedBox(height: 10),
                AuthDropdownField(
                  label: 'TYPE DE PIÈCE',
                  hintText: 'Choisir le type de pièce',
                  value: _idType,
                  items: _idTypes,
                  prefix: Icon(Icons.badge_outlined, color: Colors.grey[500]),
                  onChanged: (value) => setState(() => _idType = value),
                  validator: (value) =>
                      value == null ? 'Choisissez le type de pièce' : null,
                ),
                const SizedBox(height: 14),
                AuthTextField(
                  label: 'NUMÉRO DE LA PIÈCE',
                  controller: _idNumberController,
                  hintText: 'Numéro figurant sur la pièce',
                  prefix: Icon(Icons.numbers, color: Colors.grey[500]),
                  validator: (value) => (value ?? '').trim().length < 4
                      ? 'Numéro de pièce invalide'
                      : null,
                ),
                const SizedBox(height: 22),

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

                InkWell(
                  onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _acceptedTerms,
                        onChanged: (value) =>
                            setState(() => _acceptedTerms = value ?? false),
                        activeColor: AppColors.primary,
                      ),
                      Expanded(
                        child: Text(
                          "J'accepte les conditions d'utilisation de "
                          'Dksoft Market',
                          style: theme.textTheme.bodySmall!.copyWith(
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

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
                            'Créer mon compte',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                Center(
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                      children: [
                        const TextSpan(text: 'Déjà un compte ? '),
                        TextSpan(
                          text: 'Se connecter',
                          style: const TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => Navigator.of(context).pop(),
                        ),
                      ],
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

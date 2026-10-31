import 'package:dksoft_market_livreur/core/animations/motion.dart';
import 'package:dksoft_market_livreur/core/widgets/toast.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/core/widgets/app_button.dart';
import 'package:dksoft_market_livreur/core/widgets/app_fields.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/core/widgets/hero_card.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/auth_controller.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/widgets/brand_mark.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/widgets/forgot_password_sheet.dart';
import 'package:dksoft_market_livreur/routing/app_router.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/helpers/phone_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    // Pas de navigation manuelle : dès que la connexion réussit, le flux
    // d'authentification Firebase déclenche le `redirect` du routeur, qui
    // quitte /login tout seul.
    await ref
        .read(authControllerProvider.notifier)
        .signIn(
          phone:
              normalizeCongoPhone(_phoneController.text) ??
              '+243${_phoneController.text.replaceAll(' ', '')}',
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(authControllerProvider).isLoading;
    final topInset = MediaQuery.paddingOf(context).top;

    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      if (next.hasError) {
        Toast.error(context, next.error!);
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: context.palette.surface,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---- Bandeau marine ----
              HeroBackground(
                shadow: false,
                borderRadius: BorderRadius.zero,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    Sizes.p24,
                    topInset + Sizes.p24,
                    Sizes.p24,
                    Sizes.p48 + Sizes.p16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: staggerIn([
                      const BrandMark(onDark: true),
                      gapH32,
                      const Text(
                        'Livrez à Kinshasa,\npayé à chaque course.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ),
                      gapH12,
                      Wrap(
                        spacing: Sizes.p8,
                        runSpacing: Sizes.p8,
                        children: const [
                          _Perk(
                            icon: AppIcons.flash,
                            label: 'Courses en direct',
                          ),
                          _Perk(icon: AppIcons.coins, label: 'Gains suivis'),
                          _Perk(icon: AppIcons.route, label: 'GPS intégré'),
                        ],
                      ),
                    ], step: 60),
                  ),
                ),
              ),

              // ---- Formulaire, qui chevauche le bandeau ----
              Transform.translate(
                offset: const Offset(0, -Sizes.p32),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    Sizes.p24,
                    Sizes.p32,
                    Sizes.p24,
                    Sizes.p24,
                  ),
                  decoration: BoxDecoration(
                    color: context.palette.surface,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(Radii.xl),
                    ),
                  ),
                  child: AutofillGroup(
                    child: Form(
                      key: _formKey,
                      child: FadeSlideIn(
                        delay: const Duration(milliseconds: 150),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Connexion',
                              style: theme.textTheme.headlineMedium,
                            ),
                            gapH4,
                            Text(
                              'Entrez votre numéro et votre mot de passe.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: context.palette.textSecondary,
                              ),
                            ),
                            gapH24,
                            AppTextField(
                              label: 'Téléphone',
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              hintText: '995 415 641',
                              autofillHints: const [
                                AutofillHints.telephoneNumber,
                              ],
                              prefix: const PhonePrefix(),
                              validator: (value) {
                                final digits = (value ?? '').replaceAll(
                                  RegExp(r'[^0-9]'),
                                  '',
                                );
                                return digits.length < 9
                                    ? 'Numéro de téléphone invalide'
                                    : null;
                              },
                            ),
                            gapH16,
                            AppTextField(
                              label: 'Mot de passe',
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              prefixIcon: AppIcons.lock,
                              suffix: IconButton(
                                tooltip: _obscurePassword
                                    ? 'Afficher'
                                    : 'Masquer',
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: AppIcon(
                                  _obscurePassword
                                      ? AppIcons.eye
                                      : AppIcons.eyeOff,
                                  size: 20,
                                ),
                              ),
                              validator: (value) => (value ?? '').length < 6
                                  ? 'Au moins 6 caractères'
                                  : null,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () => showForgotPasswordSheet(
                                        context,
                                        phone: _phoneController.text,
                                      ),
                                child: const Text('Mot de passe oublié ?'),
                              ),
                            ),
                            gapH12,
                            AppButton(
                              label: 'Se connecter',
                              icon: AppIcons.forward,
                              loading: isLoading,
                              onPressed: _submit,
                            ),
                            gapH24,
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Sizes.p12,
                                  ),
                                  child: Text(
                                    'Nouveau ?',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                            gapH16,
                            AppButton(
                              label: 'Devenir livreur Dksoft',
                              icon: AppIcons.moto,
                              variant: AppButtonVariant.outlined,
                              onPressed: isLoading
                                  ? null
                                  : () =>
                                        context.pushNamed(AppRoute.signup.name),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Atout de l'app, en pastille sur le bandeau.
class _Perk extends StatelessWidget {
  const _Perk({required this.icon, required this.label});

  final AppIconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return HeroChip(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, color: AppColors.secondaryLight),
          gapW4,
          Text(label),
        ],
      ),
    );
  }
}

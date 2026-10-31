import 'package:dksoft_market_livreur/core/animations/motion.dart';
import 'package:dksoft_market_livreur/core/widgets/toast.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/core/widgets/app_button.dart';
import 'package:dksoft_market_livreur/features/authentication/data/auth_repository.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/auth_controller.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/signup/signup_draft.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/signup/steps/account_step.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/signup/steps/identity_step.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/signup/steps/moto_step.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/signup/steps/review_step.dart';
import 'package:dksoft_market_livreur/routing/app_router.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/utils/helpers/phone_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Inscription du motard en 4 étapes : compte, pièce d'identité, moto,
/// récapitulatif. Rien n'est envoyé avant le dernier bouton.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  static const _lastStep = 3;

  static const _titles = [
    'Créez votre compte',
    "Votre pièce d'identité",
    'Votre moto',
    'Vérifiez vos informations',
  ];

  static const _subtitles = [
    'Votre numéro de téléphone vous servira à vous connecter.',
    'Saisissez les informations de votre pièce. Vous enverrez sa photo '
        "après l'inscription.",
    'Indiquez les informations de votre moto, personnelle ou louée.',
    "Un dernier coup d'œil avant de créer votre compte.",
  ];

  int _step = 0;

  bool _canContinue(SignUpDraft draft) {
    return switch (_step) {
      0 => draft.isAccountValid,
      1 => draft.isIdentityValid,
      2 => draft.isMotoValid,
      _ => draft.acceptedTerms,
    };
  }

  void _goBack() {
    FocusScope.of(context).unfocus();
    if (_step > 0) {
      setState(() => _step--);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoute.login.name);
    }
  }

  Future<void> _next(SignUpDraft draft) async {
    FocusScope.of(context).unfocus();

    if (_step < _lastStep) {
      setState(() => _step++);
      return;
    }

    // Dernière étape : création du compte.
    final phone = normalizeCongoPhone(draft.phone);
    if (phone == null || !draft.isMotoYearValid) {
      setState(() => _step = 0);
      return;
    }

    final plaque = draft.plaque.trim();

    final success = await ref
        .read(authControllerProvider.notifier)
        .signUp(
          firstName: draft.firstName.trim(),
          lastName: draft.lastName.trim(),
          phone: phone,
          password: draft.password,
          idCountry: draft.idCountry,
          idType: draft.idType!,
          idNumber: draft.idNumber.trim(),
          idIssueDate: draft.idIssueDate!,
          motoMake: draft.motoMake!,
          motoModel: draft.motoModel.trim(),
          motoColor: draft.motoColor!,
          motoYear: draft.motoYearNumber!,
          plaque: plaque.isEmpty ? null : plaque,
        );

    if (!mounted || !success) return;
    context.goNamed(AppRoute.home.name);
  }

  Widget _buildStep() {
    return switch (_step) {
      0 => const AccountStep(),
      1 => const IdentityStep(),
      2 => const MotoStep(),
      _ => ReviewStep(onEdit: (step) => setState(() => _step = step)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final draft = ref.watch(signUpDraftProvider);
    final isLoading = ref.watch(authControllerProvider).isLoading;

    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      if (!next.hasError) return;

      Toast.error(context, next.error!);

      // Numéro déjà inscrit : on ramène l'utilisateur à l'étape du téléphone.
      if (next.error == AuthRepository.phoneInUseMessage) {
        setState(() => _step = 0);
      }
    });

    return PopScope(
      // Le bouton « retour » du téléphone revient d'une étape, il ne quitte
      // l'inscription qu'à la première.
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !isLoading) setState(() => _step--);
      },
      child: Scaffold(
        backgroundColor: context.palette.surface,
        body: SafeArea(
          child: Column(
            children: [
              // ---- Retour + progression ----
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Sizes.p12,
                  Sizes.p8,
                  Sizes.p24,
                  0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Retour',
                      style: IconButton.styleFrom(
                        backgroundColor: context.palette.surfaceMuted,
                      ),
                      icon: const AppIcon(AppIcons.back),
                      onPressed: isLoading ? null : _goBack,
                    ),
                    gapW12,
                    Expanded(
                      child: _StepProgress(
                        current: _step,
                        total: _lastStep + 1,
                      ),
                    ),
                  ],
                ),
              ),

              // ---- Contenu défilant : titre + étape ----
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    Sizes.p24,
                    Sizes.p24,
                    Sizes.p24,
                    Sizes.p24,
                  ),
                  child: AnimatedSwitcher(
                    duration: Motion.medium,
                    switchInCurve: Motion.emphasized,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.04, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: Column(
                      key: ValueKey(_step),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ÉTAPE ${_step + 1} SUR ${_lastStep + 1}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.secondaryDark,
                          ),
                        ),
                        gapH8,
                        Text(
                          _titles[_step],
                          style: theme.textTheme.headlineMedium,
                        ),
                        gapH8,
                        Text(
                          _subtitles[_step],
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: context.palette.textSecondary,
                          ),
                        ),
                        gapH32,
                        _buildStep(),
                      ],
                    ),
                  ),
                ),
              ),

              // ---- Bouton fixé en bas ----
              DecoratedBox(
                decoration: BoxDecoration(
                  color: context.palette.surface,
                  border: Border(
                    top: BorderSide(color: context.palette.border),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Sizes.p24,
                    Sizes.p12,
                    Sizes.p24,
                    Sizes.p16,
                  ),
                  child: AppButton(
                    label: _step == _lastStep
                        ? 'Créer mon compte'
                        : 'Continuer',
                    icon: _step == _lastStep
                        ? AppIcons.check
                        : AppIcons.forward,
                    loading: isLoading,
                    onPressed: _canContinue(draft) ? () => _next(draft) : null,
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

/// Barre de progression en segments : un par étape, remplis jusqu'à
/// l'étape en cours.
class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 6,
      children: [
        for (var i = 0; i < total; i++)
          Expanded(
            child: AnimatedContainer(
              duration: Motion.medium,
              curve: Motion.emphasized,
              height: 6,
              decoration: BoxDecoration(
                color: i < current
                    ? context.palette.primary
                    : i == current
                    ? AppColors.secondary
                    : context.palette.surfaceMuted,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
      ],
    );
  }
}

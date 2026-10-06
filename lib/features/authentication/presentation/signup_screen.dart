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
import 'package:hugeicons/hugeicons.dart';

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
    'Créez votre compte livreur',
    "Informations de la pièce d'identité",
    'Renseignez votre moto',
    'Vérifiez vos informations',
  ];

  static const _subtitles = [
    'Votre numéro de téléphone vous servira à vous connecter.',
    'Saisissez les informations de votre pièce. Vous enverrez sa photo '
        "après l'inscription.",
    'Indiquez les informations de votre moto, personnelle ou louée.',
    null,
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
    final subtitle = _subtitles[_step];

    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      if (!next.hasError) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${next.error}')));

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
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // ---- Flèche retour + progression ----
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, Sizes.p24, 0),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Retour',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary.withValues(
                          alpha: .05,
                        ),
                      ),
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowLeft02,
                        size: 28,
                        color: AppColors.primary,
                      ),

                      onPressed: isLoading ? null : _goBack,
                    ),
                    const SizedBox(width: 8),
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
                    Sizes.p8,
                    Sizes.p24,
                    Sizes.p24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Étape ${_step + 1} sur ${_lastStep + 1}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                      ),
                      gapH8,
                      Text(
                        _titles[_step],
                        style: theme.textTheme.headlineMedium,
                      ),
                      if (subtitle != null) ...[
                        gapH8,
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                      gapH20,
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: KeyedSubtree(
                          key: ValueKey(_step),
                          child: _buildStep(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ---- Bouton fixé en bas ----
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(
                  Sizes.p16,
                  Sizes.p12,
                  Sizes.p16,
                  Sizes.p16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (!isLoading && _canContinue(draft))
                        ? () => _next(draft)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFF3F3F3),
                      disabledForegroundColor: AppColors.textHintLight,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _step == _lastStep
                                ? 'Créer mon compte'
                                : 'Continuer',
                            style: Theme.of(context).textTheme.bodySmall!
                                .copyWith(color: Colors.white),
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

/// Barre de progression en segments : un par étape, remplis jusqu'à
/// l'étape en cours.
class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 5,
              decoration: BoxDecoration(
                color: i <= current
                    ? AppColors.primary
                    : AppColors.dividerLight,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          if (i < total - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

import 'package:dksoft_market_livreur/core/widgets/skeleton.dart';
import 'package:dksoft_market_livreur/core/animations/motion.dart';
import 'package:dksoft_market_livreur/core/widgets/toast.dart';
import 'package:dksoft_market_livreur/utils/themes/app_palette.dart';
import 'package:dksoft_market_livreur/core/widgets/app_icon.dart';
import 'package:dksoft_market_livreur/core/data/livreur_repository.dart';
import 'package:dksoft_market_livreur/core/domain/livreur_model.dart';
import 'package:dksoft_market_livreur/core/widgets/app_button.dart';
import 'package:dksoft_market_livreur/core/widgets/app_card.dart';
import 'package:dksoft_market_livreur/core/widgets/icon_tile.dart';
import 'package:dksoft_market_livreur/features/validation/presentation/identity_upload_controller.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
import 'package:dksoft_market_livreur/features/authentication/presentation/sign_out_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Affiché tant que l'administration n'a pas validé le profil du motard
/// (§6.4). Permet d'envoyer la photo de la pièce d'identité, indispensable
/// à la validation (§3.4, §17 : vérification des motards contre la fraude).
class PendingValidationScreen extends ConsumerWidget {
  const PendingValidationScreen({super.key, required this.livreur});

  final LivreurModel livreur;

  Future<void> _choosePhotoSource(BuildContext context, WidgetRef ref) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            Sizes.p12,
            0,
            Sizes.p12,
            Sizes.p12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: IconTile(
                  icon: AppIcons.camera,
                  color: context.palette.primary,
                  size: 40,
                ),
                title: const Text('Prendre une photo'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: IconTile(
                  icon: AppIcons.gallery,
                  color: context.palette.primary,
                  size: 40,
                ),
                title: const Text('Choisir dans la galerie'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;
    await ref
        .read(identityUploadControllerProvider.notifier)
        .pickAndUpload(source);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isUploading = ref.watch(identityUploadControllerProvider).isLoading;
    final hasPhoto = livreur.idPhotoPath != null;

    ref.listen<AsyncValue<void>>(identityUploadControllerProvider, (
      previous,
      next,
    ) {
      if (next.hasError) {
        Toast.error(context, next.error!);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            Sizes.screenPadding,
            Sizes.p32,
            Sizes.screenPadding,
            Sizes.p24,
          ),
          children: staggerIn([
            const Center(
              child: IconTile(
                icon: AppIcons.hourglass,
                color: AppColors.warning,
                size: 80,
                radius: Radii.xl,
              ),
            ),
            gapH20,
            Text(
              'Compte en attente de validation',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            gapH8,
            Text(
              "Bonjour ${livreur.fullName.split(' ').first}, l'administration "
              'vérifie votre profil. Vous pourrez recevoir des courses dès '
              'que votre compte sera validé.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: context.palette.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            gapH32,

            // ---- Progression ----
            AppCard(
              padding: const EdgeInsets.all(Sizes.p20),
              child: Column(
                children: [
                  const _StepRow(
                    state: _StepState.done,
                    title: 'Compte créé',
                    subtitle: 'Vos informations sont enregistrées.',
                  ),
                  _StepRow(
                    state: hasPhoto ? _StepState.done : _StepState.current,
                    title: "Photo de la pièce d'identité",
                    subtitle: hasPhoto
                        ? '${livreur.idType} envoyée.'
                        : '${livreur.idType} à photographier.',
                  ),
                  _StepRow(
                    state: hasPhoto ? _StepState.current : _StepState.todo,
                    title: "Validation par l'administration",
                    subtitle: hasPhoto
                        ? 'Votre dossier est en cours d’examen.'
                        : "Disponible dès l'envoi de votre photo.",
                    isLast: true,
                  ),
                ],
              ),
            ),
            gapH16,

            if (hasPhoto) ...[
              _IdentityPreview(path: livreur.idPhotoPath!),
              gapH16,
            ],

            AppButton(
              label: hasPhoto
                  ? 'Remplacer la photo'
                  : 'Ajouter la photo de ma pièce',
              icon: AppIcons.camera,
              variant: hasPhoto
                  ? AppButtonVariant.tonal
                  : AppButtonVariant.primary,
              loading: isUploading,
              onPressed: () => _choosePhotoSource(context, ref),
            ),
            gapH12,
            Center(
              child: TextButton(
                onPressed: () =>
                    ref.read(signOutControllerProvider.notifier).signOut(),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Se déconnecter'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

enum _StepState { done, current, todo }

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.state,
    required this.title,
    required this.subtitle,
    this.isLast = false,
  });

  final _StepState state;
  final String title;
  final String subtitle;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final indicator = switch (state) {
      _StepState.done => Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
        ),
        child: const AppIcon(AppIcons.check, size: 16, color: Colors.white),
      ),
      _StepState.current => Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.palette.primarySoft,
          shape: BoxShape.circle,
          border: Border.all(color: context.palette.primary, width: 2),
        ),
      ),
      _StepState.todo => Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: context.palette.border, width: 2),
        ),
      ),
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              indicator,
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: state == _StepState.done
                        ? AppColors.success.withValues(alpha: 0.4)
                        : context.palette.border,
                  ),
                ),
            ],
          ),
          gapW16,
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : Sizes.p20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: state == _StepState.todo
                          ? context.palette.textMuted
                          : context.palette.textPrimary,
                    ),
                  ),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityPreview extends ConsumerWidget {
  const _IdentityPreview({required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final photo = ref.watch(identityPhotoProvider(path));

    Widget message(String text) => Center(
      child: Padding(
        padding: const EdgeInsets.all(Sizes.p16),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.lg),
      child: Container(
        height: 180,
        width: double.infinity,
        color: context.palette.surfaceMuted,
        child: photo.when(
          loading: () => const Shimmer(child: SkeletonBox(radius: 0)),
          error: (_, _) =>
              message('Aperçu indisponible (la photo est bien envoyée).'),
          data: (bytes) => bytes == null
              ? message('Aperçu indisponible.')
              : Image.memory(bytes, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

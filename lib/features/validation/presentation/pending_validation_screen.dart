import 'package:dksoft_market_livreur/core/data/livreur_repository.dart';
import 'package:dksoft_market_livreur/core/domain/livreur_model.dart';
import 'package:dksoft_market_livreur/features/authentication/data/auth_repository.dart';
import 'package:dksoft_market_livreur/features/validation/presentation/identity_upload_controller.dart';
import 'package:dksoft_market_livreur/utils/constants/app_colors.dart';
import 'package:dksoft_market_livreur/utils/constants/app_sizes.dart';
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
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${next.error}')));
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Sizes.p24),
          child: Column(
            children: [
              gapH24,
              Container(
                padding: const EdgeInsets.all(Sizes.p20),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_top_rounded,
                  color: AppColors.warning,
                  size: 40,
                ),
              ),
              gapH16,
              Text(
                'Compte en attente de validation',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              gapH8,
              Text(
                "Bonjour ${livreur.fullName.split(' ').first}, l'administration "
                'vérifie votre profil. Vous pourrez recevoir des courses dès '
                'que votre compte sera validé.',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
                textAlign: TextAlign.center,
              ),
              gapH24,

              // ---- Progression ----
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(Sizes.p16),
                decoration: BoxDecoration(
                  color: AppColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const _StepRow(
                      done: true,
                      title: 'Compte créé',
                      subtitle: 'Vos informations sont enregistrées.',
                    ),
                    gapH12,
                    _StepRow(
                      done: hasPhoto,
                      title: "Photo de la pièce d'identité",
                      subtitle: hasPhoto
                          ? '${livreur.idType} envoyée.'
                          : '${livreur.idType} à photographier.',
                    ),
                    gapH12,
                    _StepRow(
                      done: false,
                      title: "Validation par l'administration",
                      subtitle: hasPhoto
                          ? 'Votre dossier est en cours d’examen.'
                          : "Disponible dès l'envoi de votre photo.",
                    ),
                  ],
                ),
              ),
              gapH20,

              if (hasPhoto) ...[
                _IdentityPreview(path: livreur.idPhotoPath!),
                gapH12,
              ],

              SizedBox(
                width: double.infinity,
                child: hasPhoto
                    ? ElevatedButton(
                        onPressed: isUploading
                            ? null
                            : () => _choosePhotoSource(context, ref),
                        child: const Text('Remplacer la photo'),
                      )
                    : ElevatedButton(
                        onPressed: isUploading
                            ? null
                            : () => _choosePhotoSource(context, ref),
                        child: isUploading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Ajouter la photo de ma pièce',
                                style: theme.textTheme.bodySmall!.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                      ),
              ),
              if (hasPhoto && isUploading) ...[
                gapH12,
                const LinearProgressIndicator(),
              ],
              gapH12,
              TextButton(
                onPressed: () => ref.read(authRepositoryProvider).signOut(),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.errorDark.withValues(alpha: .5),
                ),
                child: Text(
                  'Se déconnecter',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall!.copyWith(color: AppColors.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.done,
    required this.title,
    required this.subtitle,
  });

  final bool done;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          done ? Icons.check_circle : Icons.radio_button_unchecked,
          color: done ? AppColors.success : AppColors.textHintLight,
        ),
        gapW12,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.bodyMedium),
              Text(
                subtitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IdentityPreview extends ConsumerWidget {
  const _IdentityPreview({required this.path});

  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photo = ref.watch(identityPhotoProvider(path));

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 180,
        width: double.infinity,
        child: photo.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const Center(
            child: Text("Aperçu indisponible (la photo est bien envoyée)."),
          ),
          data: (bytes) => bytes == null
              ? const Center(child: Text('Aperçu indisponible.'))
              : Image.memory(bytes, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

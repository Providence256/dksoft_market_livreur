import 'package:dksoft_market_livreur/core/data/livreur_repository.dart';
import 'package:dksoft_market_livreur/features/authentication/data/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class IdentityUploadController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Ouvre l'appareil photo ou la galerie, puis envoie la photo.
  /// L'image est réduite (1600 px, qualité 80) pour économiser les
  /// données mobiles (§12.4, connexion moyenne à Kinshasa).
  Future<void> pickAndUpload(ImageSource source) async {
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;
    if (uid == null) return;

    state = const AsyncLoading();

    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 80,
      );

      // L'utilisateur a fermé la caméra/galerie sans choisir de photo.
      if (picked == null) {
        if (ref.mounted) state = const AsyncData(null);
        return;
      }

      final bytes = await picked.readAsBytes();
      await ref
          .read(livreurRepositoryProvider)
          .uploadIdentityPhoto(
            uid: uid,
            bytes: bytes,
            contentType: picked.mimeType ?? 'image/jpeg',
          );

      if (!ref.mounted) return;
      state = const AsyncData(null);
    } catch (_, stackTrace) {
      if (!ref.mounted) return;
      state = AsyncError(
        "Impossible d'envoyer la photo. Vérifiez votre connexion et "
        'réessayez.',
        stackTrace,
      );
    }
  }
}

final identityUploadControllerProvider =
    AsyncNotifierProvider.autoDispose<IdentityUploadController, void>(
      IdentityUploadController.new,
    );

import 'package:dksoft_market_livreur/features/deliveries/domain/delivery_model.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ouvre le composeur téléphonique. Renvoie false si l'appel a échoué.
Future<bool> callPhone(String phone) async {
  try {
    return await launchUrl(Uri(scheme: 'tel', path: phone));
  } catch (_) {
    return false;
  }
}

/// Ouvre l'itinéraire vers un lieu dans l'app de cartes du téléphone.
///
/// Avec des coordonnées GPS, l'itinéraire est précis. Sans, on cherche
/// par adresse + commune : à Kinshasa les adresses sont souvent
/// imprécises (§17), c'est donc un point de départ, pas une garantie.
Future<bool> openInMaps(DeliveryPlace place) async {
  final lat = place.latitude;
  final lng = place.longitude;

  final uri = (lat != null && lng != null)
      ? Uri.https('www.google.com', '/maps/dir/', {
          'api': '1',
          'destination': '$lat,$lng',
        })
      : Uri.https('www.google.com', '/maps/search/', {
          'api': '1',
          'query': '${place.address}, ${place.commune}, Kinshasa',
        });

  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

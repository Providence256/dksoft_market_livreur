/// Formate une distance en mètres pour l'affichage (« 850 m », « 3,2 km »).
String formatDistance(double meters) {
  if (meters < 10) return 'Moins de 10 m';
  if (meters < 1000) return '${(meters / 10).round() * 10} m';

  final km = meters / 1000;
  final text = km.toStringAsFixed(km < 10 ? 1 : 0).replaceAll('.', ',');
  return '$text km';
}

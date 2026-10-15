/// « 12 min », « 1 h 05 ».
String formatDuration(double seconds) {
  final minutes = (seconds / 60).ceil().clamp(1, 99999);
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = (minutes % 60).toString().padLeft(2, '0');
  return '$h h $m';
}

/// Heure d'arrivée estimée : maintenant + [seconds], au format « 10:15 ».
String formatArrival(double seconds) {
  final at = DateTime.now().add(Duration(seconds: seconds.round()));
  return '${at.hour.toString().padLeft(2, '0')}:'
      '${at.minute.toString().padLeft(2, '0')}';
}

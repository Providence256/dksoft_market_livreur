/// Normalise un numéro congolais saisi à la main en « +243XXXXXXXXX ».
///
/// Accepte « 991 234 567 », « 0991234567 » ou « +243 991 234 567 » : le
/// zéro de tête et l'indicatif sont retirés, puis on exige exactement
/// 9 chiffres. Renvoie null si le numéro est invalide.
///
/// Sert à la connexion ET à l'inscription : un même numéro doit toujours
/// donner le même identifiant de compte.
String? normalizeCongoPhone(String input) {
  var digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.startsWith('243')) digits = digits.substring(3);
  digits = digits.replaceFirst(RegExp(r'^0+'), '');
  if (digits.length != 9) return null;
  return '+243$digits';
}

/// « +243991234567 » -> « +243 99 123 4567 » pour l'affichage.
String formatPhoneDisplay(String normalized) {
  final digits = normalized.replaceFirst('+243', '');
  if (digits.length != 9) return normalized;
  return '+243 ${digits.substring(0, 2)} ${digits.substring(2, 5)} '
      '${digits.substring(5)}';
}

import 'package:dksoft_market_livreur/utils/helpers/phone_format.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tout ce que le motard a saisi dans l'assistant d'inscription.
///
/// Les étapes y écrivent au fil de la saisie : revenir en arrière ne fait
/// rien perdre. Rien n'est envoyé à Firebase avant le bouton final.
class SignUpDraft {
  const SignUpDraft({
    // Étape 1 : compte
    this.phone = '',
    this.commune,
    this.password = '',
    this.confirmPassword = '',
    // Étape 2 : pièce d'identité
    this.idCountry = 'République démocratique du Congo',
    this.idType,
    this.lastName = '',
    this.firstName = '',
    this.idNumber = '',
    this.idIssueDate,
    // Étape 3 : moto
    this.motoMake,
    this.motoModel = '',
    this.motoColor,
    this.motoYear = '',
    this.plaque = '',
    // Étape 4 : récapitulatif
    this.acceptedTerms = false,
  });

  final String phone;
  final String? commune;
  final String password;
  final String confirmPassword;

  final String idCountry;
  final String? idType;
  final String lastName;
  final String firstName;
  final String idNumber;
  final DateTime? idIssueDate;

  final String? motoMake;
  final String motoModel;
  final String? motoColor;
  final String motoYear;
  final String plaque;

  final bool acceptedTerms;

  static const minMotoYear = 1990;

  SignUpDraft copyWith({
    String? phone,
    String? commune,
    String? password,
    String? confirmPassword,
    String? idCountry,
    String? idType,
    String? lastName,
    String? firstName,
    String? idNumber,
    DateTime? idIssueDate,
    String? motoMake,
    String? motoModel,
    String? motoColor,
    String? motoYear,
    String? plaque,
    bool? acceptedTerms,
  }) {
    return SignUpDraft(
      phone: phone ?? this.phone,
      commune: commune ?? this.commune,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      idCountry: idCountry ?? this.idCountry,
      idType: idType ?? this.idType,
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      idNumber: idNumber ?? this.idNumber,
      idIssueDate: idIssueDate ?? this.idIssueDate,
      motoMake: motoMake ?? this.motoMake,
      motoModel: motoModel ?? this.motoModel,
      motoColor: motoColor ?? this.motoColor,
      motoYear: motoYear ?? this.motoYear,
      plaque: plaque ?? this.plaque,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
    );
  }

  // ---- Validité de chaque étape (active ou non le bouton « Continuer ») ----

  bool get isAccountValid =>
      normalizeCongoPhone(phone) != null &&
      password.length >= 6 &&
      confirmPassword == password;

  bool get isIdentityValid =>
      idType != null &&
      lastName.trim().length >= 2 &&
      firstName.trim().length >= 2 &&
      idNumber.trim().length >= 4 &&
      idIssueDate != null;

  int? get motoYearNumber => int.tryParse(motoYear.trim());

  bool get isMotoYearValid {
    final year = motoYearNumber;
    return year != null && year >= minMotoYear && year <= DateTime.now().year;
  }

  bool get isMotoValid =>
      motoMake != null &&
      motoModel.trim().isNotEmpty &&
      motoColor != null &&
      isMotoYearValid;

  String get fullName => '${firstName.trim()} ${lastName.trim()}'.trim();
}

class SignUpDraftNotifier extends Notifier<SignUpDraft> {
  @override
  SignUpDraft build() => const SignUpDraft();

  void update(SignUpDraft Function(SignUpDraft draft) transform) {
    state = transform(state);
  }
}

/// autoDispose : quitter l'inscription efface le brouillon (mot de passe
/// compris).
final signUpDraftProvider =
    NotifierProvider.autoDispose<SignUpDraftNotifier, SignUpDraft>(
      SignUpDraftNotifier.new,
    );

/// « 03/10/2024 »
String formatIssueDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

import 'package:cloud_firestore/cloud_firestore.dart';

enum PayoutStatus {
  enAttente('En attente'),
  validee('Payé'),
  refusee('Refusé');

  const PayoutStatus(this.label);

  final String label;

  static PayoutStatus fromName(String? name) => PayoutStatus.values.firstWhere(
    (status) => status.name == name,
    orElse: () => PayoutStatus.enAttente,
  );
}

/// Moyens de paiement acceptés par le backend (livreur_payouts.ts).
const kPayoutMethods = ['M-Pesa', 'Airtel Money', 'Orange Money', 'Espèces'];

/// Montant minimum d'un retrait, en USD (même valeur que le backend).
const kMinPayout = 5.0;

/// Demande de retrait `livreurs/{uid}/payoutRequests/{id}`, créée et
/// traitée par le backend.
class PayoutRequest {
  const PayoutRequest({
    required this.id,
    required this.amount,
    required this.method,
    required this.status,
    this.phone,
    this.createdAt,
  });

  final String id;
  final double amount;
  final String method;
  final String? phone;
  final PayoutStatus status;
  final DateTime? createdAt;

  factory PayoutRequest.fromDoc(String id, Map<String, dynamic> data) {
    return PayoutRequest(
      id: id,
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      method: data['method'] as String? ?? '',
      phone: data['phone'] as String?,
      status: PayoutStatus.fromName(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

// lib/domain/entities/transaction.dart

import 'package:equatable/equatable.dart';

/// 💸 Entité représentant un mouvement financier au sein d'un groupe Likelemba.
///
/// Immuable et indépendante de la persistance. Chaque transaction est horodatée
/// et catégorisée.
class Transaction extends Equatable {
  final int id; // Changé
  final DateTime timestamp;
  final double amount;
  final TransactionCurrency currency;
  final TransactionType type;
  final TransactionStatus status;
  final String? note;
  final String? proofImageUrl;

  // Références aux autres entités (par ID)
  final String userId; // Auteur de la transaction
  final String groupId;
  final String? recipientId; // Bénéficiaire (si type payout)

  final bool isSynced;

  const Transaction({
    required this.id,
    required this.timestamp,
    required this.amount,
    required this.currency,
    required this.type,
    required this.status,
    this.note,
    this.proofImageUrl,
    required this.userId,
    required this.groupId,
    this.recipientId,
    required this.isSynced,
  });

  /// Vérifie si le montant de la transaction est cohérent avec son type.
  /// Par exemple, une cotisation doit correspondre à la cotisation quotidienne du groupe.
  bool isAmountValid(double expectedDailyContribution) {
    bool valid;
    switch (type) {
      case TransactionType.contribution:
        valid = amount == expectedDailyContribution;
        break;
      case TransactionType.payout:
      case TransactionType.penalty:
      case TransactionType.refund:
      case TransactionType.reserveFund:
        valid = amount > 0;
        break;
    }
    print('Transaction.isAmountValid - $type, Montant: $amount → $valid');
    return valid;
  }

  /// Indique si la transaction est comptabilisée dans les soldes.
  bool get isAccounted {
    final accounted = status == TransactionStatus.validated;
    print('Transaction.isAccounted - $id → $accounted');
    return accounted;
  }

  Transaction copyWith({
    int? id,
    DateTime? timestamp,
    double? amount,
    TransactionCurrency? currency,
    TransactionType? type,
    TransactionStatus? status,
    String? note,
    String? proofImageUrl,
    String? userId,
    String? groupId,
    String? recipientId,
    bool? isSynced,
  }) {
    return Transaction(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      type: type ?? this.type,
      status: status ?? this.status,
      note: note ?? this.note,
      proofImageUrl: proofImageUrl ?? this.proofImageUrl,
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      recipientId: recipientId ?? this.recipientId,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  @override
  List<Object?> get props => [
        id,
        timestamp,
        amount,
        currency,
        type,
        status,
        userId,
        groupId,
        recipientId,
        isSynced,
      ];
}

/// Devises supportées.
enum TransactionCurrency { cdf, usd }

/// Types de transactions possibles.
enum TransactionType {
  contribution, // Cotisation quotidienne
  payout,       // Versement de la cagnotte
  penalty,      // Pénalité prélevée lors d'un départ
  refund,       // Remboursement lors d'un départ
  reserveFund,  // Alimentation du fonds de réserve
}

/// Statuts de validation d'une transaction.
enum TransactionStatus {
  pending,   // En attente de validation
  validated, // Validée et comptabilisée
  rejected,  // Rejetée
}
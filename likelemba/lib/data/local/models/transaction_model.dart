// lib/data/local/models/transaction_model.dart

import 'package:isar/isar.dart';

import 'likelemba_model.dart';
import 'user_model.dart';
part 'transaction_model.g.dart';

/// 💸 Modèle de transaction financière (registre immuable).
///
/// Chaque mouvement d'argent (cotisation, versement de cagnotte, pénalité)
/// est enregistré ici pour garantir une transparence totale.
@Collection()
class TransactionModel {
  /// Identifiant unique de la transaction.
  Id id = Isar.autoIncrement;

  /// Date et heure exactes de la transaction.
  @Index()
  late DateTime timestamp;

  /// Montant de la transaction (toujours positif).
  late double amount;

  /// Devise utilisée (0 = CDF, 1 = USD).
  /// Stocké en `int` pour l'efficacité, mappé vers `AppCurrency` via une extension.
  @enumerated
  late TransactionCurrency currency;

  /// Type de transaction.
  @enumerated
  late TransactionType type;

  /// Statut de validation (ex: en attente, validé, rejeté).
  @enumerated
  TransactionStatus status = TransactionStatus.pending;

  /// Note ou commentaire optionnel.
  String? note;

  /// Preuve de paiement (chemin du fichier local ou URL).
  String? proofImagePath;

  /// Indique si cette transaction a été synchronisée avec le serveur distant.
  bool isSynced = false;

  // -------------------------------------------------------------------------
  // Relations
  // -------------------------------------------------------------------------

  /// Utilisateur à l'origine de la transaction (ex: le payeur).
  final userLink = IsarLink<UserModel>();

  /// Groupe Likelemba concerné par cette transaction.
  final groupLink = IsarLink<LikelembaModel>();

  /// Bénéficiaire (pour les versements de cagnotte).
  final recipientLink = IsarLink<UserModel>();
}

/// Devises supportées pour les transactions.
enum TransactionCurrency {
  cdf, // Franc Congolais
  usd, // Dollar Américain
}

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
  pending,   // En attente de validation (par l'admin)
  validated, // Validée et comptabilisée
  rejected,  // Rejetée
}
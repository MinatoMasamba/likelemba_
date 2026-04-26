
// lib/domain/repositories/i_transaction_repository.dart

import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/transaction.dart';

/// 💸 Interface du repository de gestion des transactions financières (Contrat domaine).
///
/// Garantit la traçabilité et l'intégrité de tous les mouvements d'argent au sein
/// des groupes Likelemba.
abstract class ITransactionRepository {
  /// Enregistre une nouvelle transaction dans le système.
  Future<Either<Failure, Transaction>> submitTransaction(Transaction transaction);

  /// Récupère l'historique complet des transactions d'un groupe.
  /// [limit] et [offset] permettent la pagination.
  Future<Either<Failure, List<Transaction>>> getTransactionsByGroup(
    int groupId, {
    int limit = 50,
    int offset = 0,
  });

  /// Récupère l'historique des transactions d'un utilisateur spécifique.
  Future<Either<Failure, List<Transaction>>> getTransactionsByUser(
    int userId, {
    int limit = 50,
    int offset = 0,
  });

  /// Valide une transaction en attente (action réservée à l'administrateur).
  /// Cela confirme la réception effective des fonds et comptabilise la transaction.
  Future<Either<Failure, void>> validateTransaction(int transactionId, int adminUserId);

  /// Rejette une transaction en attente (action réservée à l'administrateur).
  /// [reason] : Motif du rejet (ex: preuve de paiement invalide).
  Future<Either<Failure, void>> rejectTransaction(
    int transactionId,
    int adminUserId,
    String reason,
  );

  /// Récupère les transactions en attente de validation pour les groupes d'un admin.
  Future<Either<Failure, List<Transaction>>> getPendingValidations(int adminUserId);

  /// Calcule le montant total des cotisations validées pour un utilisateur dans un groupe.
  Future<Either<Failure, double>> getUserTotalContribution(int groupId, int userId);

  /// Calcule le montant actuel du fonds de réserve d'un groupe.
  Future<Either<Failure, double>> getCurrentReserveFund(int groupId);

  /// Calcule le remboursement théorique pour un départ anticipé.
  Future<Either<Failure, double>> calculateExitRefund(int groupId, int userId);
}

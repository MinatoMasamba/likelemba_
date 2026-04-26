// lib/data/repositories/transaction_repository_impl.dart

import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';

import '../../core/error/failures.dart';
import '../../core/error/app_exception.dart';
import '../../core/utils/penalty_calculator.dart';
import '../local/daos/transaction_dao.dart';
import '../local/daos/user_dao.dart';
import '../local/daos/likelemba_dao.dart';
import '../local/daos/outbox_dao.dart';
import '../local/models/transaction_model.dart';
import '../local/models/outbox_model.dart';
import '../../domain/entities/transaction.dart' as entity;
import '../../domain/repositories/i_transaction_repository.dart';

/// Implémentation du repository de gestion des transactions financières.
class TransactionRepositoryImpl implements ITransactionRepository {
  final TransactionDao _transactionDao;
  final UserDao _userDao;
  final LikelembaDao _likelembaDao;
  final OutboxDao _outboxDao;
  final Logger _logger = Logger();

  TransactionRepositoryImpl({
    required TransactionDao transactionDao,
    required UserDao userDao,
    required LikelembaDao likelembaDao,
    required OutboxDao outboxDao,
  })  : _transactionDao = transactionDao,
        _userDao = userDao,
        _likelembaDao = likelembaDao,
        _outboxDao = outboxDao;

  // -------------------------------------------------------------------------
  // Méthodes publiques (interface ITransactionRepository)
  // -------------------------------------------------------------------------

  @override
  Future<Either<Failure, entity.Transaction>> submitTransaction(entity.Transaction transaction) async {
    const method = 'submitTransaction';
    _logger.i('$method - Soumission transaction type ${transaction.type}');

    // Convertir l'entité en modèle Isar
    final model = await _toModel(transaction);
    if (model == null) {
      return Left(ValidationFailure('Données de transaction invalides (utilisateur ou groupe manquant).'));
    }

    final result = await _createTransaction(model);
    return result.fold(
      (failure) => Left(failure),
      (txModel) async => Right(await txModel.toEntity()),
    );
  }

  @override
  Future<Either<Failure, List<entity.Transaction>>> getTransactionsByGroup(
    int groupId, {
    int limit = 50,
    int offset = 0,
  }) async {
    const method = 'getTransactionsByGroup';
    _logger.d('$method - Groupe $groupId');
    try {
      final models = await _transactionDao.getTransactionsByGroup(groupId, limit: limit, offset: offset);
      final entities = await Future.wait(models.map((m) => m.toEntity()));
      return Right(entities);
    } on AppException catch (e) {
      _logger.e('$method - Exception: $e');
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      _logger.e('$method - Erreur inconnue: $e');
      return Left(CacheFailure(customMessage: 'Erreur de lecture des transactions'));
    }
  }

  @override
  Future<Either<Failure, List<entity.Transaction>>> getTransactionsByUser(
    int userId, {
    int limit = 50,
    int offset = 0,
  }) async {
    const method = 'getTransactionsByUser';
    _logger.d('$method - Utilisateur $userId');
    try {
      final models = await _transactionDao.getTransactionsByUser(userId, limit: limit);
      final entities = await Future.wait(models.map((m) => m.toEntity()));
      return Right(entities);
    } on AppException catch (e) {
      _logger.e('$method - Exception: $e');
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      _logger.e('$method - Erreur inconnue: $e');
      return Left(CacheFailure(customMessage: 'Erreur de lecture des transactions'));
    }
  }

  @override
  Future<Either<Failure, void>> validateTransaction(int transactionId, int adminUserId) async {
    return _updateTransactionStatus(transactionId, TransactionStatus.validated, adminUserId);
  }

  @override
  Future<Either<Failure, void>> rejectTransaction(
    int transactionId,
    int adminUserId,
    String reason,
  ) async {
    final result = await _updateTransactionStatus(transactionId, TransactionStatus.rejected, adminUserId);
    if (result.isRight()) {
      // Ajouter la raison dans une note ou un log
      _logger.w('Transaction $transactionId rejetée par admin $adminUserId. Raison: $reason');
    }
    return result;
  }

  @override
  Future<Either<Failure, List<entity.Transaction>>> getPendingValidations(int adminUserId) async {
    const method = 'getPendingValidations';
    _logger.d('$method - Admin $adminUserId');
    try {
      final models = await _transactionDao.getPendingValidations(adminUserId);
      final entities = await Future.wait(models.map((m) => m.toEntity()));
      return Right(entities);
    } on AppException catch (e) {
      _logger.e('$method - Exception: $e');
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      _logger.e('$method - Erreur inconnue: $e');
      return Left(CacheFailure(customMessage: 'Erreur de récupération des validations en attente'));
    }
  }

  @override
  Future<Either<Failure, double>> getUserTotalContribution(int groupId, int userId) async {
    const method = 'getUserTotalContribution';
    _logger.d('$method - Groupe $groupId, User $userId');
    try {
      final sum = await _transactionDao.getSumContributions(groupId, userId: userId);
      return Right(sum);
    } on AppException catch (e) {
      _logger.e('$method - Exception: $e');
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      _logger.e('$method - Erreur inconnue: $e');
      return Left(CacheFailure(customMessage: 'Erreur de calcul des contributions'));
    }
  }

  @override
  Future<Either<Failure, double>> getCurrentReserveFund(int groupId) async {
    const method = 'getCurrentReserveFund';
    _logger.d('$method - Groupe $groupId');
    try {
      final group = await _likelembaDao.getById(groupId);
      if (group == null) return Left(ValidationFailure('Groupe introuvable'));
      return Right(group.currentReserveFund);
    } on AppException catch (e) {
      _logger.e('$method - Exception: $e');
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      _logger.e('$method - Erreur inconnue: $e');
      return Left(CacheFailure(customMessage: 'Erreur de récupération du fonds de réserve'));
    }
  }

  @override
  Future<Either<Failure, double>> calculateExitRefund(int groupId, int userId) async {
    const method = 'calculateExitRefund';
    _logger.d('$method - Calcul remboursement pour user $userId groupe $groupId');
    try {
      final group = await _likelembaDao.getById(groupId);
      if (group == null) return Left(ValidationFailure('Groupe introuvable.'));

      final totalContributed = await _transactionDao.getSumContributions(groupId, userId: userId);
      final elapsedDays = group.elapsedDays;
      final refund = PenaltyCalculator.calculateRefund(
        totalContributed: totalContributed,
        elapsedDays: elapsedDays,
        totalCycleDays: group.cycleDurationDays,
        basePenalty: group.basePenaltyRate,
      );
      return Right(refund);
    } on AppException catch (e) {
      _logger.e('$method - Exception: $e');
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      _logger.e('$method - Erreur inconnue: $e');
      return Left(ComputationFailure(customMessage: 'Erreur lors du calcul du remboursement'));
    }
  }

  // -------------------------------------------------------------------------
  // Méthodes internes (modèles Isar)
  // -------------------------------------------------------------------------

  /// Crée une transaction locale (utilisée en interne).
  Future<Either<Failure, TransactionModel>> _createTransaction(TransactionModel transaction) async {
    const method = '_createTransaction';
    try {
      if (transaction.amount <= 0) {
        return Left(ValidationFailure('Le montant doit être positif.'));
      }

      final group = await _likelembaDao.getById(transaction.groupLink.value!.id);
      if (group == null) {
        return Left(ValidationFailure('Groupe introuvable.'));
      }

      if (transaction.type == TransactionType.contribution) {
        if (transaction.amount != group.dailyContribution) {
          return Left(ValidationFailure(
            'Le montant doit être égal à la cotisation quotidienne (${group.dailyContribution}).',
          ));
        }
      }

      final txId = await _transactionDao.create(transaction);
      transaction.id = txId;

      if (transaction.type == TransactionType.contribution) {
        await _userDao.addContribution(transaction.userLink.value!.id, transaction.amount);
      }

      if (transaction.type == TransactionType.reserveFund) {
        final newFund = group.currentReserveFund + transaction.amount;
        await _likelembaDao.updateReserveFund(group.id, newFund);
      }

      final outbox = OutboxModel()
        ..actionType = 'CREATE_TRANSACTION'
        ..payload = '{"transactionId": $txId, "type": "${transaction.type.name}"}'
        ..priority = 2;
      await _outboxDao.create(outbox);

      _logger.i('$method - Transaction $txId créée localement.');
      return Right(transaction);
    } on AppException catch (e) {
      _logger.e('$method - Exception: $e');
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      _logger.e('$method - Erreur inconnue: $e');
      return Left(CacheFailure(customMessage: 'Erreur lors de la création de la transaction'));
    }
  }

  Future<Either<Failure, void>> _updateTransactionStatus(
    int transactionId,
    TransactionStatus newStatus,
    int adminUserId,
  ) async {
    const method = '_updateTransactionStatus';
    _logger.i('$method - Transaction $transactionId -> $newStatus par admin $adminUserId');
    try {
      final tx = await _transactionDao.getById(transactionId);
      if (tx == null) return Left(ValidationFailure('Transaction introuvable.'));

      final group = await _likelembaDao.getById(tx.groupLink.value!.id);
      if (group == null) return Left(ValidationFailure('Groupe introuvable.'));
      if (group.adminLink.value?.id != adminUserId) {
        return Left(ValidationFailure('Seul l\'administrateur du groupe peut modifier cette transaction.'));
      }

      await _transactionDao.updateStatus(transactionId, newStatus);

      final outbox = OutboxModel()
        ..actionType = 'UPDATE_TX_STATUS'
        ..payload = '{"transactionId": $transactionId, "newStatus": "${newStatus.name}"}'
        ..priority = 2;
      await _outboxDao.create(outbox);

      return const Right(null);
    } on AppException catch (e) {
      _logger.e('$method - Exception: $e');
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      _logger.e('$method - Erreur inconnue: $e');
      return Left(CacheFailure(customMessage: 'Erreur lors de la mise à jour du statut'));
    }
  }

  // -------------------------------------------------------------------------
  // Conversion Entité ↔ Modèle
  // -------------------------------------------------------------------------

  Future<TransactionModel?> _toModel(entity.Transaction transaction) async {
    final user = await _userDao.getById(int.parse(transaction.userId));
    final group = await _likelembaDao.getById(int.parse(transaction.groupId));
    if (user == null || group == null) return null;

    final model = TransactionModel()
      ..amount = transaction.amount
      ..currency = transaction.currency == entity.TransactionCurrency.cdf
          ? TransactionCurrency.cdf
          : TransactionCurrency.usd
      ..type = _mapTypeToModel(transaction.type)
      ..status = _mapStatusToModel(transaction.status)
      ..note = transaction.note
      ..proofImagePath = transaction.proofImageUrl
      ..isSynced = transaction.isSynced
      ..timestamp = transaction.timestamp;

    model.userLink.value = user;
    model.groupLink.value = group;
    if (transaction.recipientId != null) {
      final recipient = await _userDao.getById(int.parse(transaction.recipientId!));
      model.recipientLink.value = recipient;
    }

    return model;
  }

  static TransactionType _mapTypeToModel(entity.TransactionType type) {
    switch (type) {
      case entity.TransactionType.contribution:
        return TransactionType.contribution;
      case entity.TransactionType.payout:
        return TransactionType.payout;
      case entity.TransactionType.penalty:
        return TransactionType.penalty;
      case entity.TransactionType.refund:
        return TransactionType.refund;
      case entity.TransactionType.reserveFund:
        return TransactionType.reserveFund;
    }
  }

  static TransactionStatus _mapStatusToModel(entity.TransactionStatus status) {
    switch (status) {
      case entity.TransactionStatus.pending:
        return TransactionStatus.pending;
      case entity.TransactionStatus.validated:
        return TransactionStatus.validated;
      case entity.TransactionStatus.rejected:
        return TransactionStatus.rejected;
    }
  }
}

// -----------------------------------------------------------------------------
// Extension de conversion TransactionModel → Transaction (Entité)
// -----------------------------------------------------------------------------

extension TransactionModelToEntity on TransactionModel {
  Future<entity.Transaction> toEntity() async {
    await userLink.load();
    await groupLink.load();
    await recipientLink.load();

    entity.TransactionType type;
    switch (this.type) {
      case TransactionType.contribution:
        type = entity.TransactionType.contribution;
        break;
      case TransactionType.payout:
        type = entity.TransactionType.payout;
        break;
      case TransactionType.penalty:
        type = entity.TransactionType.penalty;
        break;
      case TransactionType.refund:
        type = entity.TransactionType.refund;
        break;
      case TransactionType.reserveFund:
        type = entity.TransactionType.reserveFund;
        break;
    }

    entity.TransactionStatus status;
    switch (this.status) {
      case TransactionStatus.pending:
        status = entity.TransactionStatus.pending;
        break;
      case TransactionStatus.validated:
        status = entity.TransactionStatus.validated;
        break;
      case TransactionStatus.rejected:
        status = entity.TransactionStatus.rejected;
        break;
    }

    return entity.Transaction(
      id: this.id,
      timestamp: timestamp,
      amount: amount,
      currency: currency == TransactionCurrency.cdf
          ? entity.TransactionCurrency.cdf
          : entity.TransactionCurrency.usd,
      type: type,
      status: status,
      note: note,
      proofImageUrl: proofImagePath,
      userId: userLink.value!.id.toString(),
      groupId: groupLink.value!.id.toString(),
      recipientId: recipientLink.value?.id.toString(),
      isSynced: isSynced,
    );
  }
}
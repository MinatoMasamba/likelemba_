// lib/data/repositories/sync_repository_impl.dart

import 'dart:async';
import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';

import '../../core/error/failures.dart';
import '../../core/error/app_exception.dart';
import '../local/daos/outbox_dao.dart';
import '../local/daos/transaction_dao.dart';
import '../local/daos/likelemba_dao.dart';
import '../local/daos/user_dao.dart';
import '../local/models/likelemba_model.dart';
import '../local/models/transaction_model.dart';
import '../local/models/user_model.dart';
import '../remote/sync_remote_data_source.dart';
import '../../domain/repositories/i_sync_repository.dart' hide PushResult, SyncDelta;

/// Implémentation du repository de synchronisation.
class SyncRepositoryImpl implements ISyncRepository {
  final SyncRemoteDataSource _remoteDataSource;
  final OutboxDao _outboxDao;
  final TransactionDao _transactionDao;
  final LikelembaDao _likelembaDao;
  final UserDao _userDao;
  final Logger _logger = Logger();

  SyncRepositoryImpl({
    required SyncRemoteDataSource remoteDataSource,
    required OutboxDao outboxDao,
    required TransactionDao transactionDao,
    required LikelembaDao likelembaDao,
    required UserDao userDao,
  })  : _remoteDataSource = remoteDataSource,
        _outboxDao = outboxDao,
        _transactionDao = transactionDao,
        _likelembaDao = likelembaDao,
        _userDao = userDao;

  /// Pousse les messages en attente de l'Outbox vers le serveur.
  @override
  Future<Either<Failure, PushResult>> pushPendingActions() async {
    const method = 'pushPendingActions';
    _logger.i('$method - Début du push batch');
    try {
      final pending = await _outboxDao.getPendingMessages(limit: 50);
      if (pending.isEmpty) {
        return Right(PushResult(syncedIds: [], failedIds: [], conflicts: []));
      }

      final payloads = pending.map((m) {
        return {
          'id': m.id,
          'actionType': m.actionType,
          'payload': m.payload,
        };
      }).toList();

      // Marquer comme "processing"
      for (var msg in pending) {
        await _outboxDao.markAsProcessing(msg.id);
      }

      final result = await _remoteDataSource.pushOutboxBatch(payloads);

      // Mettre à jour les statuts locaux selon le résultat
      for (var id in result.syncedIds) {
        await _outboxDao.markAsSynced(id);
      }
      for (var id in result.failedIds) {
        await _outboxDao.markAsFailed(id, 'Échec côté serveur');
      }
      // Les conflits sont conservés (avec l'état serveur) pour arbitrage différé
      // par resolveConflicts(), plutôt que d'être traités comme un simple échec.
      for (var conflict in result.conflicts) {
        await _outboxDao.markAsConflict(conflict.outboxId, jsonEncode(conflict.serverState));
      }

      _logger.i(
        '$method - Synced: ${result.syncedIds.length}, Failed: ${result.failedIds.length}, '
        'Conflicts: ${result.conflicts.length}',
      );
      return Right(result);
    } on AppException catch (e) {
      _logger.e('$method - Exception: $e');
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      _logger.e('$method - Erreur inconnue: $e');
      return Left(SyncFailure(customMessage: 'Erreur lors de la synchronisation'));
    }
  }

  /// Récupère les mises à jour du serveur et fusionne localement.
  @override
  Future<Either<Failure, SyncDelta>> pullRemoteUpdates(DateTime lastSync, List<int> groupIds) async {
    const method = 'pullRemoteUpdates';
    _logger.i('$method - Récupération delta depuis $lastSync');
    try {
      final delta = await _remoteDataSource.pullUpdates(lastSync, groupIds);

      // Ordre important : groupes puis membres avant les transactions, car ces
      // dernières doivent résoudre leurs liens vers un groupe/utilisateur local.
      for (var groupData in delta.groupUpdates) {
        await _applyGroupUpdate(groupData);
      }
      for (var memberData in delta.memberUpdates) {
        await _applyMemberUpdate(memberData);
      }
      for (var txData in delta.transactions) {
        await _applyTransactionUpdate(txData);
      }

      _logger.i(
        '$method - Delta appliqué: ${delta.groupUpdates.length} groupes, '
        '${delta.memberUpdates.length} membres, ${delta.transactions.length} transactions',
      );
      return Right(delta);
    } on AppException catch (e) {
      _logger.e('$method - Exception: $e');
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      _logger.e('$method - Erreur inconnue: $e');
      return Left(SyncFailure(customMessage: 'Erreur lors de la récupération des mises à jour'));
    }
  }

  /// Insère ou met à jour un groupe reçu du serveur.
  Future<void> _applyGroupUpdate(GroupDeltaDto data) async {
    if (data.id.isEmpty) return;
    final existing = await _likelembaDao.getByRemoteId(data.id);

    final model = existing ?? LikelembaModel();
    model
      ..remoteId = data.id
      ..groupName = data.name
      ..description = data.description
      ..dailyContribution = data.contributionAmount
      ..securityFeeRate = data.securityFeeRate
      ..basePenaltyRate = data.penaltyRateInitial
      ..cycleDurationDays = data.cycleDurationDays
      ..regenerationTargetDays = data.regenerationTargetDays
      ..currentReserveFund = data.reserveAmount
      ..currentBeneficiaryIndex = data.currentBeneficiaryIndex
      ..isLocked = data.isLocked
      ..createdAt = existing?.createdAt ?? data.createdAt
      ..cycleStartDate = data.startedAt ?? existing?.cycleStartDate ?? data.createdAt;

    await _likelembaDao.upsertFromRemote(model);
    _logger.d('_applyGroupUpdate - Groupe ${data.id} ${existing == null ? "créé" : "mis à jour"}.');
  }

  /// Met à jour un membre existant à partir de son numéro de téléphone.
  ///
  /// Si l'utilisateur n'existe pas encore localement, la mise à jour est ignorée :
  /// un [UserModel] requiert un `pinHash` qui ne peut provenir que du flux
  /// d'inscription/authentification, jamais d'un delta de synchronisation.
  Future<void> _applyMemberUpdate(MemberDeltaDto data) async {
    if (data.phoneNumber.isEmpty) return;
    final existing = await _userDao.getByPhoneNumber(data.phoneNumber);
    if (existing == null) {
      _logger.w('_applyMemberUpdate - Utilisateur ${data.phoneNumber} inconnu localement, ignoré.');
      return;
    }

    if (data.name != null) existing.name = data.name!;
    if (data.trustScore != null) existing.trustScore = data.trustScore!.clamp(0, 100);
    if (data.totalContribution != null) existing.totalContribution = data.totalContribution!;
    if (data.isBiometricEnabled != null) existing.isBiometricEnabled = data.isBiometricEnabled!;
    if (data.notificationsEnabled != null) existing.notificationsEnabled = data.notificationsEnabled!;

    await _userDao.upsertFromRemote(existing);
    _logger.d('_applyMemberUpdate - Utilisateur ${data.phoneNumber} mis à jour.');
  }

  /// Insère ou met à jour une transaction reçue du serveur.
  ///
  /// Ignorée si le groupe ou l'utilisateur référencés ne sont pas (encore)
  /// connus localement : ils arriveront via leurs propres deltas et la
  /// transaction sera retentée au prochain pull.
  Future<void> _applyTransactionUpdate(TransactionDeltaDto data) async {
    if (data.id.isEmpty) return;

    final group = await _likelembaDao.getByRemoteId(data.groupId);
    final user = await _userDao.getByPhoneNumber(data.userPhoneNumber);
    if (group == null || user == null) {
      _logger.w('_applyTransactionUpdate - Groupe ou utilisateur introuvable pour transaction ${data.id}, ignorée.');
      return;
    }

    final existing = await _transactionDao.getByRemoteId(data.id);
    final model = existing ?? TransactionModel();
    model
      ..remoteId = data.id
      ..amount = data.amount
      ..currency = _mapCurrency(data.currency)
      ..type = _mapType(data.type)
      ..status = _mapStatus(data.status)
      ..note = data.note
      ..proofImagePath = data.proofImagePath
      ..isSynced = true
      ..timestamp = data.timestamp;
    model.groupLink.value = group;
    model.userLink.value = user;

    if (data.recipientPhoneNumber != null) {
      model.recipientLink.value = await _userDao.getByPhoneNumber(data.recipientPhoneNumber!);
    }

    await _transactionDao.upsertFromRemote(model);
    _logger.d('_applyTransactionUpdate - Transaction ${data.id} ${existing == null ? "créée" : "mise à jour"}.');
  }

  TransactionCurrency _mapCurrency(String value) {
    return value.toLowerCase() == 'usd' ? TransactionCurrency.usd : TransactionCurrency.cdf;
  }

  TransactionType _mapType(String value) {
    return TransactionType.values.firstWhere(
      (t) => t.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TransactionType.contribution,
    );
  }

  TransactionStatus _mapStatus(String value) {
    return TransactionStatus.values.firstWhere(
      (s) => s.name.toLowerCase() == value.toLowerCase(),
      orElse: () => TransactionStatus.pending,
    );
  }

  /// Résout les conflits entre données locales et serveur.
  ///
  /// Règle métier : le serveur a priorité, sauf si l'action locale a été
  /// initiée après la dernière mise à jour connue côté serveur (`updated_at`
  /// dans le payload de conflit) — dans ce cas l'action locale est retentée.
  @override
  Future<Either<Failure, void>> resolveConflicts() async {
    const method = 'resolveConflicts';
    try {
      final conflicted = await _outboxDao.getConflicted();
      _logger.i('$method - ${conflicted.length} conflit(s) à résoudre');

      for (final msg in conflicted) {
        DateTime? serverUpdatedAt;
        if (msg.conflictData != null) {
          try {
            final serverState = jsonDecode(msg.conflictData!) as Map<String, dynamic>;
            final raw = serverState['updated_at'];
            if (raw != null) serverUpdatedAt = DateTime.tryParse(raw.toString());
          } catch (e) {
            _logger.w('$method - conflictData invalide pour message ${msg.id}: $e');
          }
        }

        final localIsNewer = serverUpdatedAt == null || msg.createdAt.isAfter(serverUpdatedAt);
        if (localIsNewer) {
          _logger.i('$method - Message ${msg.id} : action locale plus récente, nouvelle tentative.');
          await _outboxDao.resetForRetry(msg.id);
        } else {
          _logger.i('$method - Message ${msg.id} : le serveur a priorité, action locale abandonnée.');
          await _outboxDao.markAsSynced(msg.id);
        }
      }

      return const Right(null);
    } on AppException catch (e) {
      _logger.e('$method - Exception: $e');
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      _logger.e('$method - Erreur inconnue: $e');
      return Left(SyncFailure(customMessage: 'Erreur lors de la résolution des conflits'));
    }
  }
}
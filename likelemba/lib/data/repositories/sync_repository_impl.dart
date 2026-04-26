// lib/data/repositories/sync_repository_impl.dart

import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';

import '../../core/error/failures.dart';
import '../../core/error/app_exception.dart';
import '../local/daos/outbox_dao.dart';
import '../local/daos/transaction_dao.dart';
import '../local/daos/likelemba_dao.dart';
import '../local/daos/user_dao.dart';
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

      _logger.i('$method - Synced: ${result.syncedIds.length}, Failed: ${result.failedIds.length}');
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
      
      // Appliquer les modifications localement
      // (simplifié : on pourrait avoir des DAOs pour upsert)
      for (var txData in delta.transactions) {
        // Créer ou mettre à jour TransactionModel
        // ...
      }
      for (var userData in delta.memberUpdates) {
        // Mise à jour UserModel
        // ...
      }
      for (var groupData in delta.groupUpdates) {
        // Mise à jour LikelembaModel
        // ...
      }

      _logger.i('$method - Delta appliqué avec succès');
      return Right(delta);
    } on AppException catch (e) {
      _logger.e('$method - Exception: $e');
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      _logger.e('$method - Erreur inconnue: $e');
      return Left(SyncFailure(customMessage: 'Erreur lors de la récupération des mises à jour'));
    }
  }

  /// Résout les conflits entre données locales et serveur.
  @override
  Future<Either<Failure, void>> resolveConflicts() async {
    const method = 'resolveConflicts';
    _logger.i('$method - Résolution des conflits');
    try {
      // Règle métier : le serveur a priorité sauf si la transaction locale est plus récente
      // (à implémenter selon besoins)
      // ...
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
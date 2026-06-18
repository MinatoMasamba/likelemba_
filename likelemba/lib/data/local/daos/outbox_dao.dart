// lib/data/local/daos/outbox_dao.dart

import 'package:isar/isar.dart';
import 'package:logger/logger.dart';

import '../isar_service.dart';
import '../models/outbox_model.dart';

/// 📤 Data Access Object pour la collection [OutboxModel].
class OutboxDao {
  final IsarService _isarService;
  final Logger _logger = Logger();

  OutboxDao(this._isarService);

  /// Récupère les messages en attente, triés par priorité décroissante puis date croissante.
  Future<List<OutboxModel>> getPendingMessages({int limit = 10}) async {
    return await _isarService.readTxn((isar) async {
      return await isar.outboxModels
          .filter()
          .statusEqualTo(OutboxStatus.pending)
          .sortByPriorityDesc()
          .thenByCreatedAt()
          .limit(limit)
          .findAll();
    });
  }

  /// Crée un nouveau message dans l'outbox.
  Future<int> create(OutboxModel message) async {
    return await _isarService.writeTxn((isar) async {
      message.createdAt = DateTime.now();
      message.status = OutboxStatus.pending;
      return await isar.outboxModels.put(message);
    });
  }

  /// Marque un message comme étant en cours de traitement.
  Future<void> markAsProcessing(int id) async {
    await _isarService.writeTxn((isar) async {
      final msg = await isar.outboxModels.get(id);
      if (msg != null && msg.status == OutboxStatus.pending) {
        msg.status = OutboxStatus.processing;
        await isar.outboxModels.put(msg);
      }
    });
  }

  /// Marque un message comme synchronisé avec succès.
  Future<void> markAsSynced(int id) async {
    await _isarService.writeTxn((isar) async {
      final msg = await isar.outboxModels.get(id);
      if (msg != null) {
        msg.status = OutboxStatus.synced;
        await isar.outboxModels.put(msg);
      }
    });
  }

  /// Marque un message comme échoué, incrémente le compteur de tentatives.
  Future<void> markAsFailed(int id, String error) async {
    await _isarService.writeTxn((isar) async {
      final msg = await isar.outboxModels.get(id);
      if (msg != null) {
        msg.retryCount += 1;
        msg.lastAttemptAt = DateTime.now();
        msg.lastError = error;
        if (msg.retryCount >= 5) {
          msg.status = OutboxStatus.failed;
          _logger.w('OutboxDao.markAsFailed - Message $id définitivement échoué après 5 tentatives.');
        } else {
          msg.status = OutboxStatus.pending; // Réessayer plus tard
        }
        await isar.outboxModels.put(msg);
      }
    });
  }

  /// Marque un message comme étant en conflit avec le serveur.
  ///
  /// [serverData] : payload JSON renvoyé par le serveur représentant l'état
  /// actuel de la ressource, conservé pour permettre à [resolveConflicts]
  /// d'arbitrer entre la version locale et la version serveur.
  Future<void> markAsConflict(int id, String serverData) async {
    await _isarService.writeTxn((isar) async {
      final msg = await isar.outboxModels.get(id);
      if (msg != null) {
        msg.status = OutboxStatus.conflict;
        msg.conflictData = serverData;
        msg.conflictDetectedAt = DateTime.now();
        await isar.outboxModels.put(msg);
      }
    });
  }

  /// Récupère tous les messages actuellement en conflit.
  Future<List<OutboxModel>> getConflicted() async {
    return await _isarService.readTxn((isar) async {
      return await isar.outboxModels
          .filter()
          .statusEqualTo(OutboxStatus.conflict)
          .findAll();
    });
  }

  /// Réinitialise un message échoué pour qu'il soit retenté.
  Future<void> resetForRetry(int id) async {
    await _isarService.writeTxn((isar) async {
      final msg = await isar.outboxModels.get(id);
      if (msg != null) {
        msg.status = OutboxStatus.pending;
        msg.retryCount = 0;
        msg.lastError = null;
        await isar.outboxModels.put(msg);
      }
    });
  }

  /// Supprime tous les messages synchronisés (nettoyage).
  Future<int> deleteSynced() async {
    return await _isarService.writeTxn((isar) async {
      return await isar.outboxModels
          .filter()
          .statusEqualTo(OutboxStatus.synced)
          .deleteAll();
    });
  }
}
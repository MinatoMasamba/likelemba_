// lib/data/local/daos/transaction_dao.dart

import 'package:isar/isar.dart';
import 'package:likelemba/core/error/app_exception.dart';
import 'package:likelemba/data/local/models/user_model.dart';
import 'package:logger/logger.dart';

import '../isar_service.dart';
import '../models/transaction_model.dart';
import '../models/likelemba_model.dart'; // 🔑 IMPORT OBLIGATOIRE pour accéder à adminLink

/// 💸 Data Access Object pour la collection [TransactionModel].
///
/// Fournit des méthodes typées pour interagir avec les transactions financières
/// (cotisations, versements, pénalités, fonds de réserve) dans la base Isar.
/// Respecte le principe d'immutabilité : aucune suppression physique n'est autorisée.
class TransactionDao {
  final IsarService _isarService;
  final Logger _logger = Logger();

  TransactionDao(this._isarService);

  // -------------------------------------------------------------------------
  // 🔍 Méthodes de lecture
  // -------------------------------------------------------------------------

  /// Récupère une transaction par son identifiant, avec toutes ses relations chargées.
  ///
  /// [id] : Identifiant unique de la transaction.
  /// Retourne `null` si aucune transaction ne correspond.
  Future<TransactionModel?> getById(int id) async {
    return await _isarService.readTxn((isar) async {
      final tx = await isar.transactionModels.get(id);
      if (tx != null) {
        // Chargement des relations pour éviter les erreurs d'accès ultérieures
        await tx.userLink.load();       // Le payeur
        await tx.groupLink.load();      // Le groupe concerné
        await tx.recipientLink.load();  // Le bénéficiaire (si applicable)
      }
      return tx;
    });
  }

  /// Récupère une transaction par son identifiant côté serveur.
  ///
  /// Utilisé pour fusionner les mises à jour distantes (`pullRemoteUpdates`)
  /// sans créer de doublons.
  Future<TransactionModel?> getByRemoteId(String remoteId) async {
    return await _isarService.readTxn((isar) async {
      return await isar.transactionModels
          .filter()
          .remoteIdEqualTo(remoteId)
          .findFirst();
    });
  }

  /// Récupère les transactions d'un groupe spécifique, paginées par date décroissante.
  ///
  /// [groupId] : Identifiant du groupe.
  /// [limit]   : Nombre maximal de transactions à retourner (défaut 50).
  /// [offset]  : Décalage pour la pagination (défaut 0).
  Future<List<TransactionModel>> getTransactionsByGroup(
    int groupId, {
    int limit = 50,
    int offset = 0,
  }) async {
    return await _isarService.readTxn((isar) async {
      return await isar.transactionModels
          .filter()
          .groupLink((q) => q.idEqualTo(groupId))
          .sortByTimestampDesc()   // Du plus récent au plus ancien
          .offset(offset)
          .limit(limit)
          .findAll();
    });
  }

  /// Récupère l'historique des transactions d'un utilisateur donné.
  ///
  /// [userId] : Identifiant de l'utilisateur.
  /// [limit]  : Nombre maximal de transactions à retourner (défaut 50).
  Future<List<TransactionModel>> getTransactionsByUser(
    int userId, {
    int limit = 50,
  }) async {
    return await _isarService.readTxn((isar) async {
      return await isar.transactionModels
          .filter()
          .userLink((q) => q.idEqualTo(userId))
          .sortByTimestampDesc()
          .limit(limit)
          .findAll();
    });
  }

  /// Récupère les transactions en attente de validation pour tous les groupes
  /// administrés par un utilisateur donné.
  ///
  /// [adminUserId] : Identifiant de l'administrateur.
  Future<List<TransactionModel>> getPendingValidations(int adminUserId) async {
    return await _isarService.readTxn((isar) async {
      // 1. Récupérer tous les groupes gérés par cet administrateur
      final managedGroups = await isar.likelembaModels
          .filter()
          .adminLink((q) => q.idEqualTo(adminUserId))
          .findAll();

      final groupIds = managedGroups.map((g) => g.id).toList();
      if (groupIds.isEmpty) return [];

      // 2. Construire un filtre OR sur les groupLink
      // On commence avec le premier ID, puis on chaîne avec .or() pour les suivants
      var query = isar.transactionModels
          .filter()
          .statusEqualTo(TransactionStatus.pending)
          .groupLink((q) => q.idEqualTo(groupIds.first));

      for (var i = 1; i < groupIds.length; i++) {
        final id = groupIds[i];
        query = query.or().groupLink((q) => q.idEqualTo(id));
      }

      return await query.findAll();
    });
  }

  // -------------------------------------------------------------------------
  // ✏️ Méthodes d'écriture
  // -------------------------------------------------------------------------

  /// Crée une nouvelle transaction dans le registre.
  ///
  /// Le montant doit être strictement positif.
  /// Le timestamp est automatiquement défini à la date courante.
  ///
  /// [transaction] : L'objet transaction à persister.
  /// Retourne l'identifiant généré.
  Future<int> create(TransactionModel transaction) async {
    // Validation métier : montant positif obligatoire
    if (transaction.amount <= 0) {
      throw ArgumentError('Le montant doit être strictement positif.');
    }
    return await _isarService.writeTxn((isar) async {
      transaction.timestamp = DateTime.now();
      return await isar.transactionModels.put(transaction);
    });
  }

  /// Insère ou met à jour une transaction reçue du serveur (`pullRemoteUpdates`).
  ///
  /// Contrairement à [create], ne réécrit pas le `timestamp` : celui-ci provient
  /// du serveur et doit être préservé tel quel.
  Future<int> upsertFromRemote(TransactionModel transaction) async {
    return await _isarService.writeTxn((isar) async {
      return await isar.transactionModels.put(transaction);
    });
  }

  /// Met à jour le statut d'une transaction existante.
  ///
  /// Règle métier : une transaction validée ne peut jamais repasser en attente.
  ///
  /// [transactionId] : Identifiant de la transaction.
  /// [newStatus]     : Nouveau statut à appliquer.
  /// Lance une [ValidationException] si la transition est interdite.
  Future<void> updateStatus(int transactionId, TransactionStatus newStatus) async {
    await _isarService.writeTxn((isar) async {
      final tx = await isar.transactionModels.get(transactionId);
      if (tx == null) {
        _logger.w('TransactionDao.updateStatus - Transaction $transactionId introuvable.');
        return;
      }
      // Protection contre la régression de statut
      if (tx.status == TransactionStatus.validated && newStatus == TransactionStatus.pending) {
        throw ValidationException('Impossible de repasser une transaction validée en attente.');
      }
      tx.status = newStatus;
      await isar.transactionModels.put(tx);
      _logger.i('TransactionDao.updateStatus - Transaction $transactionId -> $newStatus');
    });
  }

  // -------------------------------------------------------------------------
  // 📊 Méthodes d'agrégation (calculs financiers)
  // -------------------------------------------------------------------------

  /// Calcule la somme des montants pour un groupe, un type de transaction,
  /// et optionnellement un statut de validation.
  ///
  /// [groupId] : Identifiant du groupe.
  /// [type]    : Type de transaction (contribution, payout, penalty, etc.).
  /// [status]  : Statut de validation (optionnel).
  /// Retourne la somme en double, ou 0.0 si aucune transaction ne correspond.
  Future<double> getSumByType(
    int groupId,
    TransactionType type, {
    TransactionStatus? status,
  }) async {
    return await _isarService.readTxn((isar) async {
      // Construction de la requête filtrée
      var query = isar.transactionModels
          .filter()
          .groupLink((q) => q.idEqualTo(groupId))
          .typeEqualTo(type);

      // Ajout du filtre sur le statut si spécifié
      if (status != null) {
        query = query.statusEqualTo(status);
      }

      // Agrégation : somme de la propriété 'amount'
      final sum = await query.amountProperty().sum();
      return sum ?? 0.0;
    });
  }

  /// Calcule le total des contributions versées au fonds de réserve d'un groupe.
  ///
  /// Seules les transactions de type [TransactionType.reserveFund]
  /// avec le statut [TransactionStatus.validated] sont prises en compte.
  ///
  /// [groupId] : Identifiant du groupe.
  Future<double> getSumReserveFund(int groupId) async {
    return await getSumByType(
      groupId,
      TransactionType.reserveFund,
      status: TransactionStatus.validated,
    );
  }

  /// Calcule le total des cotisations validées pour un groupe
  /// (et optionnellement pour un membre spécifique).
  ///
  /// [groupId] : Identifiant du groupe.
  /// [userId]  : Identifiant du membre (optionnel). Si non fourni, somme pour tout le groupe.
  Future<double> getSumContributions(int groupId, {int? userId}) async {
    return await _isarService.readTxn((isar) async {
      var query = isar.transactionModels
          .filter()
          .groupLink((q) => q.idEqualTo(groupId))
          .typeEqualTo(TransactionType.contribution)
          .statusEqualTo(TransactionStatus.validated);

      // Filtre supplémentaire par utilisateur si demandé
      if (userId != null) {
        query = query.userLink((q) => q.idEqualTo(userId));
      }

      final sum = await query.amountProperty().sum();
      return sum ?? 0.0;
    });
  }
}
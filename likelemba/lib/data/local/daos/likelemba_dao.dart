// lib/data/local/daos/likelemba_dao.dart

import 'package:isar/isar.dart';
import 'package:logger/logger.dart';

import '../../../core/error/app_exception.dart';
import '../isar_service.dart';
import '../models/likelemba_model.dart';
import '../models/user_model.dart';

/// 👥 Data Access Object pour la collection [LikelembaModel].
class LikelembaDao {
  final IsarService _isarService;
  final Logger _logger = Logger();

  LikelembaDao(this._isarService);

  /// Récupère un groupe avec ses relations chargées.
  Future<LikelembaModel?> getById(int id) async {
    return await _isarService.readTxn((isar) async {
      final group = await isar.likelembaModels.get(id);
      if (group != null) {
        await group.memberLinks.load();
        await group.adminLink.load();
      }
      return group;
    });
  }

  /// Récupère un groupe par son identifiant côté serveur.
  Future<LikelembaModel?> getByRemoteId(String remoteId) async {
    return await _isarService.readTxn((isar) async {
      return await isar.likelembaModels
          .filter()
          .remoteIdEqualTo(remoteId)
          .findFirst();
    });
  }

  /// Insère ou met à jour un groupe reçu du serveur (`pullRemoteUpdates`).
  ///
  /// Contrairement à [create], ne réinitialise pas `createdAt`/`cycleStartDate` :
  /// ces dates proviennent du serveur et doivent être préservées telles quelles.
  Future<int> upsertFromRemote(LikelembaModel group) async {
    return await _isarService.writeTxn((isar) async {
      return await isar.likelembaModels.put(group);
    });
  }

  /// Récupère tous les groupes triés par date de création.
  Future<List<LikelembaModel>> getAll() async {
    return await _isarService.readTxn((isar) async {
      return await isar.likelembaModels.where().sortByCreatedAtDesc().findAll();
    });
  }

  /// Récupère les groupes gérés par un administrateur donné.
  Future<List<LikelembaModel>> getGroupsManagedBy(int adminUserId) async {
    return await _isarService.readTxn((isar) async {
      return await isar.likelembaModels
          .filter()
          .adminLink((q) => q.idEqualTo(adminUserId))
          .findAll();
    });
  }

  /// Récupère les groupes actifs auxquels un membre participe.
  Future<List<LikelembaModel>> getActiveGroupsForMember(int userId) async {
    return await _isarService.readTxn((isar) async {
      final groups = await isar.likelembaModels
          .filter()
          .memberLinks((q) => q.idEqualTo(userId))
          .findAll();
      // Filtrer ceux dont le cycle n'est pas terminé
      return groups.where((g) => !g.isCycleCompleted).toList();
    });
  }

  /// Crée un nouveau groupe.
  Future<int> create(LikelembaModel group) async {
    return await _isarService.writeTxn((isar) async {
      group.createdAt = DateTime.now();
      group.cycleStartDate = DateTime.now();
      return await isar.likelembaModels.put(group);
    });
  }

  /// Met à jour un groupe existant.
  Future<void> update(LikelembaModel group) async {
    await _isarService.writeTxn((isar) async {
      await isar.likelembaModels.put(group);
    });
  }

  /// Verrouille un groupe (paramètres figés).
  Future<void> lockGroup(int groupId) async {
    await _isarService.writeTxn((isar) async {
      final group = await isar.likelembaModels.get(groupId);
      if (group == null) throw Exception('Groupe introuvable');
      if (group.isLocked) {
        throw ValidationException('Le groupe est déjà verrouillé.');
      }
      group.isLocked = true;
      group.lockedAt = DateTime.now();
      await isar.likelembaModels.put(group);
      _logger.i('LikelembaDao.lockGroup - Groupe $groupId verrouillé.');
    });
  }

  /// Passe au bénéficiaire suivant dans la file d'attente.
  Future<void> advanceBeneficiary(int groupId) async {
    await _isarService.writeTxn((isar) async {
      final group = await isar.likelembaModels.get(groupId);
      if (group == null) return;
      await group.memberLinks.load();
      final memberCount = group.memberLinks.length;
      if (memberCount == 0) return;
      
      group.currentBeneficiaryIndex = (group.currentBeneficiaryIndex + 1) % memberCount;
      await isar.likelembaModels.put(group);
    });
  }

  /// Ajoute un membre au groupe.
  Future<void> addMember(int groupId, int userId) async {
    await _isarService.writeTxn((isar) async {
      final group = await isar.likelembaModels.get(groupId);
      final user = await isar.userModels.get(userId);
      if (group == null || user == null) {
        throw Exception('Groupe ou utilisateur introuvable');
      }
      if (group.isLocked) {
        throw ValidationException('Impossible d\'ajouter un membre : groupe verrouillé.');
      }
      await group.memberLinks.load();
      if (group.memberLinks.any((m) => m.id == userId)) {
        throw ValidationException('L\'utilisateur est déjà membre.');
      }
      group.memberLinks.add(user);
      await group.memberLinks.save();
      _logger.i('LikelembaDao.addMember - Utilisateur $userId ajouté au groupe $groupId.');
    });
  }

  /// Retire un membre du groupe.
  Future<void> removeMember(int groupId, int userId) async {
    await _isarService.writeTxn((isar) async {
      final group = await isar.likelembaModels.get(groupId);
      if (group == null) return;
      await group.memberLinks.load();
      if (group.adminLink.value?.id == userId) {
        throw ValidationException('Impossible de retirer l\'administrateur du groupe.');
      }
      group.memberLinks.removeWhere((m) => m.id == userId);
      await group.memberLinks.save();
    });
  }

  /// Met à jour le montant du fonds de réserve.
  Future<void> updateReserveFund(int groupId, double newAmount) async {
    await _isarService.writeTxn((isar) async {
      final group = await isar.likelembaModels.get(groupId);
      if (group != null) {
        group.currentReserveFund = newAmount;
        await isar.likelembaModels.put(group);
      }
    });
  }

  Stream<List<LikelembaModel>> watchActiveGroupsForMember(int userId) {
  return _isarService.instance.likelembaModels
      .filter()
      .memberLinks((q) => q.idEqualTo(userId))
      .watch(fireImmediately: true)
      .map((groups) => groups.where((g) => !g.isCycleCompleted).toList());
}
}
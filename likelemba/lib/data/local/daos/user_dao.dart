// lib/data/local/daos/user_dao.dart

import 'package:isar/isar.dart';
import 'package:likelemba/data/local/models/likelemba_model.dart';
import 'package:logger/logger.dart';

import '../isar_service.dart';
import '../models/user_model.dart';

/// 🔍 Data Access Object pour la collection [UserModel].
///
/// Fournit des méthodes typées pour interagir avec les utilisateurs
/// dans la base de données Isar. Toute la logique d'accès aux données
/// est encapsulée ici.
class UserDao {
  final IsarService _isarService;
  final Logger _logger = Logger();

  UserDao(this._isarService);

  /// Récupère un utilisateur par son identifiant.
  Future<UserModel?> getById(int id) async {
    return await _isarService.readTxn((isar) async {
      return await isar.userModels.get(id);
    });
  }

  /// Récupère un utilisateur par son numéro de téléphone (indexé).
  Future<UserModel?> getByPhoneNumber(String phoneNumber) async {
    return await _isarService.readTxn((isar) async {
      return await isar.userModels
          .filter()
          .phoneNumberEqualTo(phoneNumber)
          .findFirst();
    });
  }

  /// Récupère tous les utilisateurs actifs.
  Future<List<UserModel>> getAllActive() async {
    return await _isarService.readTxn((isar) async {
      return await isar.userModels
          .filter()
          .statusEqualTo(UserStatus.active)
          .findAll();
    });
  }

  /// Stream réactif de tous les utilisateurs actifs.
  Stream<List<UserModel>> watchAllActive() {
    return _isarService.instance.userModels
        .filter()
        .statusEqualTo(UserStatus.active)
        .watch(fireImmediately: true);
  }

  /// Crée un nouvel utilisateur.
  Future<int> create(UserModel user) async {
    return await _isarService.writeTxn((isar) async {
      user.createdAt = DateTime.now();
      return await isar.userModels.put(user);
    });
  }

  /// Met à jour un utilisateur existant.
  Future<void> update(UserModel user) async {
    await _isarService.writeTxn((isar) async {
      final existing = await isar.userModels.get(user.id);
      if (existing == null) {
        throw Exception('Utilisateur avec id ${user.id} introuvable');
      }
      await isar.userModels.put(user);
    });
  }

  /// Met à jour le score de confiance d'un utilisateur.
  Future<void> updateTrustScore(int userId, int newScore) async {
    await _isarService.writeTxn((isar) async {
      final user = await isar.userModels.get(userId);
      if (user != null) {
        user.trustScore = newScore.clamp(0, 100);
        await isar.userModels.put(user);
      }
    });
  }

  /// Incrémente le total des contributions d'un utilisateur.
  Future<void> addContribution(int userId, double amount) async {
    await _isarService.writeTxn((isar) async {
      final user = await isar.userModels.get(userId);
      if (user != null) {
        user.totalContribution += amount;
        await isar.userModels.put(user);
      }
    });
  }

  /// Supprime un utilisateur (s'il n'est référencé nulle part).
  Future<bool> delete(int id) async {
    return await _isarService.writeTxn((isar) async {
      // Vérifier qu'il n'est pas admin d'un groupe
      final isAdmin = await isar.likelembaModels
          .filter()
          .adminLink((q) => q.idEqualTo(id))
          .isEmpty();
      // Vérifier qu'il n'est membre d'aucun groupe
      final isMember = await isar.likelembaModels
          .filter()
          .memberLinks((q) => q.idEqualTo(id))
          .isEmpty();
      
      if (!isAdmin || !isMember) {
        _logger.w('UserDao.delete - Impossible de supprimer l\'utilisateur $id car il est lié à des groupes.');
        return false;
      }
      
      await isar.userModels.delete(id);
      _logger.i('UserDao.delete - Utilisateur $id supprimé.');
      return true;
    });
  }
}
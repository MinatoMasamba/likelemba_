
// lib/domain/repositories/i_tontine_repository.dart

import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/likelemba_group.dart';

/// 👥 Interface du repository de gestion des groupes de tontine (Contrat domaine).
///
/// Définit les opérations de création, modification et consultation des groupes
/// Likelemba, incluant les calculs liés aux équations différentielles (EDO).
/// Tous les identifiants sont de type `int` pour correspondre à Isar.
abstract class ITontineRepository {
  /// Crée un nouveau groupe Likelemba.
  /// [group] : L'entité groupe à créer.
  /// [adminUserId] : Identifiant de l'utilisateur administrateur.
  Future<Either<Failure, LikelembaGroup>> createGroup(LikelembaGroup group, int adminUserId);

  /// Récupère un groupe par son identifiant.
  Future<Either<Failure, LikelembaGroup?>> getGroupById(int groupId);

  /// Retourne un flux (Stream) des groupes actifs auxquels un utilisateur participe.
  /// Le Stream se met à jour automatiquement lorsque les données locales changent.
  Stream<Either<Failure, List<LikelembaGroup>>> watchUserGroups(int userId);

  /// Ajoute un membre à un groupe existant.
  /// [groupId] : Identifiant du groupe.
  /// [userId] : Identifiant de l'utilisateur à ajouter.
  /// [inviteCode] : Code d'invitation optionnel (si le groupe est privé).
  Future<Either<Failure, void>> joinGroup(int groupId, int userId, {String? inviteCode});

  /// Verrouille définitivement les paramètres financiers d'un groupe.
  /// Action irréversible réservée à l'administrateur du groupe.
  Future<Either<Failure, void>> lockGroupSettings(int groupId, int adminUserId);

  /// Calcule la pénalité de sortie (montant retenu) pour un utilisateur souhaitant
  /// quitter le groupe de manière anticipée.
  Future<Either<Failure, double>> calculateExitPenalty(int groupId, int userId);

  /// Passe au bénéficiaire suivant dans le cycle.
  Future<Either<Failure, void>> advanceBeneficiary(int groupId, int adminUserId);

  /// Récupère tous les groupes administrés par un utilisateur donné (serveur + cache local).
  Future<Either<Failure, List<LikelembaGroup>>> getGroupsManagedBy(int adminUserId);

  /// Lecture hors-ligne des groupes administrés depuis la base Isar locale.
  Future<Either<Failure, List<LikelembaGroup>>> getLocalGroupsManagedBy(int adminUserId);
}

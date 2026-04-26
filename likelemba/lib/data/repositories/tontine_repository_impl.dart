// lib/data/repositories/tontine_repository_impl.dart

import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';

import '../../core/error/failures.dart';
import '../../core/error/app_exception.dart';
import '../../core/utils/penalty_calculator.dart';
import '../local/daos/likelemba_dao.dart';
import '../local/daos/outbox_dao.dart';
import '../local/daos/user_dao.dart';
import '../local/daos/transaction_dao.dart';
import '../local/models/likelemba_model.dart';
import '../local/models/outbox_model.dart';
import '../local/models/user_model.dart';
import '../remote/tontine_remote_data_source.dart'; // nouveau
import '../../domain/entities/likelemba_group.dart' as entity;
import '../../domain/repositories/i_tontine_repository.dart';

/// Implémentation du repository de gestion des tontines (groupes).
class TontineRepositoryImpl implements ITontineRepository {
  final LikelembaDao _likelembaDao;
  final UserDao _userDao;
  final OutboxDao _outboxDao;
  final TransactionDao _transactionDao;
  final TontineRemoteDataSource _tontineRemoteDataSource; // nouveau champ
  final Logger _logger = Logger();

  TontineRepositoryImpl({
    required LikelembaDao likelembaDao,
    required UserDao userDao,
    required OutboxDao outboxDao,
    required TransactionDao transactionDao,
    required TontineRemoteDataSource tontineRemoteDataSource, // nouveau
  })  : _likelembaDao = likelembaDao,
        _userDao = userDao,
        _outboxDao = outboxDao,
        _transactionDao = transactionDao,
        _tontineRemoteDataSource = tontineRemoteDataSource;

  // -------------------------------------------------------------------------
  // Méthodes publiques (interface ITontineRepository)
  // -------------------------------------------------------------------------

  @override
  Future<Either<Failure, entity.LikelembaGroup>> createGroup(
    entity.LikelembaGroup group,
    int adminUserId,
  ) async {
    const method = 'createGroup';
    _logger.i('$method - Création du groupe "${group.groupName}"');

    try {
      // 1. Vérification de l'administrateur
      final admin = await _userDao.getById(adminUserId);
      if (admin == null || admin.role != UserRole.admin) {
        return Left(ValidationFailure('Seul un administrateur peut créer un groupe.'));
      }

      // 2. Appel au serveur pour créer la tontine
      final groupResponse = await _tontineRemoteDataSource.createGroup(
        name: group.groupName,
        description: group.description ?? '',
        contributionAmount: group.dailyContribution,
        securityFeeRate: group.securityFeeRate,
        penaltyRateInitial: group.basePenaltyRate,
        cycleDurationDays: group.cycleDurationDays,
      );

      // 3. Persistance locale avec les données reçues du serveur
      final model = LikelembaModel()
        ..remoteId = groupResponse.id                 // UUID du serveur
        ..groupName = groupResponse.name
        ..description = groupResponse.description
        ..dailyContribution = groupResponse.contributionAmount
        ..securityFeeRate = groupResponse.securityFeeRate
        ..basePenaltyRate = groupResponse.penaltyRateInitial
        ..cycleDurationDays = groupResponse.cycleDurationDays
        ..regenerationTargetDays = groupResponse.regenerationTargetDays
        ..currentReserveFund = groupResponse.reserveAmount
        ..currentBeneficiaryIndex = groupResponse.currentBeneficiaryIndex
        ..isLocked = groupResponse.isLocked
        ..lockedAt = groupResponse.startedAt
        ..createdAt = groupResponse.createdAt
        ..cycleStartDate = groupResponse.startedAt ?? DateTime.now();

      // Lier l'administrateur comme membre
      model.adminLink.value = admin;
      model.memberLinks.add(admin);

      final localId = await _likelembaDao.create(model);
      model.id = localId;

      // Outbox pour synchro future si nécessaire
      final outboxMessage = OutboxModel()
        ..actionType = 'CREATE_GROUP'
        ..payload = '{"groupId": $localId, "remoteId": "${groupResponse.id}"}'
        ..priority = 5;
      await _outboxDao.create(outboxMessage);

      final createdGroup = await model.toEntity();
      _logger.i('$method - Groupe créé, localId=$localId, UUID=${groupResponse.id}');
      return Right(createdGroup);
    } on AppException catch (e) {
      _logger.e('$method - Exception: $e');
      return Left(mapExceptionToFailure(e));
    } catch (e, stack) {
      _logger.e('$method - Erreur inconnue: $e', error: e, stackTrace: stack);
      return Left(CacheFailure(customMessage: 'Erreur lors de la création du groupe'));
    }
  }

  @override
  Future<Either<Failure, entity.LikelembaGroup?>> getGroupById(int groupId) async {
    const method = 'getGroupById';
    _logger.d('$method - Récupération groupe $groupId');
    try {
      final model = await _likelembaDao.getById(groupId);
      if (model == null) return const Right(null);
      return Right(await model.toEntity());
    } on AppException catch (e) {
      _logger.e('$method - Exception: $e');
      return Left(mapExceptionToFailure(e));
    } catch (e, stack) {
      _logger.e('$method - Erreur inconnue: $e', error: e, stackTrace: stack);
      return Left(CacheFailure(customMessage: 'Erreur de lecture du groupe'));
    }
  }

  @override
  Stream<Either<Failure, List<entity.LikelembaGroup>>> watchUserGroups(int userId) {
    const method = 'watchUserGroups';
    _logger.d('$method - Mise en place du stream pour user $userId');
    return _likelembaDao.watchActiveGroupsForMember(userId).asyncMap((models) async {
      try {
        final entities = await Future.wait(models.map((m) => m.toEntity()));
        return Right<Failure, List<entity.LikelembaGroup>>(entities);
      } catch (e, stack) {
        _logger.e('$method - Erreur mapping: $e', error: e, stackTrace: stack);
        return Left<Failure, List<entity.LikelembaGroup>>(
          CacheFailure(customMessage: 'Erreur de lecture des groupes'),
        );
      }
    });
  }

  @override
  Future<Either<Failure, void>> joinGroup(int groupId, int userId, {String? inviteCode}) async {
    const method = 'joinGroup';
    _logger.i('$method - Ajout membre $userId au groupe $groupId');
    try {
      final group = await _likelembaDao.getById(groupId);
      if (group == null) return Left(ValidationFailure('Groupe introuvable.'));
      if (group.isLocked) {
        return Left(ValidationFailure('Le groupe est verrouillé.'));
      }
      final user = await _userDao.getById(userId);
      if (user == null) return Left(ValidationFailure('Utilisateur introuvable.'));

      await _likelembaDao.addMember(groupId, userId);

      final outbox = OutboxModel()
        ..actionType = 'ADD_MEMBER'
        ..payload = '{"groupId": $groupId, "userId": $userId}'
        ..priority = 4;
      await _outboxDao.create(outbox);

      return const Right(null);
    } on AppException catch (e) {
      _logger.e('$method - Exception: $e');
      return Left(mapExceptionToFailure(e));
    } catch (e, stack) {
      _logger.e('$method - Erreur inconnue: $e', error: e, stackTrace: stack);
      return Left(CacheFailure(customMessage: 'Impossible de rejoindre le groupe'));
    }
  }

  @override
  Future<Either<Failure, void>> lockGroupSettings(int groupId, int adminUserId) async {
    const method = 'lockGroupSettings';
    _logger.i('$method - Verrouillage groupe $groupId par admin $adminUserId');
    try {
      final group = await _likelembaDao.getById(groupId);
      if (group == null) return Left(ValidationFailure('Groupe introuvable.'));
      if (group.adminLink.value?.id != adminUserId) {
        return Left(ValidationFailure('Seul l\'administrateur peut verrouiller le groupe.'));
      }
      await _likelembaDao.lockGroup(groupId);

      final outbox = OutboxModel()
        ..actionType = 'LOCK_GROUP'
        ..payload = '{"groupId": $groupId}'
        ..priority = 3;
      await _outboxDao.create(outbox);

      return const Right(null);
    } on AppException catch (e) {
      _logger.e('$method - Exception: $e');
      return Left(mapExceptionToFailure(e));
    } catch (e, stack) {
      _logger.e('$method - Erreur inconnue: $e', error: e, stackTrace: stack);
      return Left(CacheFailure(customMessage: 'Erreur lors du verrouillage'));
    }
  }

  @override
  Future<Either<Failure, double>> calculateExitPenalty(int groupId, int userId) async {
    const method = 'calculateExitPenalty';
    _logger.d('$method - Calcul pénalité pour user $userId groupe $groupId');
    try {
      final group = await _likelembaDao.getById(groupId);
      if (group == null) return Left(ValidationFailure('Groupe introuvable.'));

      final totalContributed = await _transactionDao.getSumContributions(groupId, userId: userId);
      final refund = PenaltyCalculator.calculateRefund(
        totalContributed: totalContributed,
        elapsedDays: group.elapsedDays,
        totalCycleDays: group.cycleDurationDays,
        basePenalty: group.basePenaltyRate,
      );
      final penalty = totalContributed - refund;
      return Right(penalty);
    } on AppException catch (e) {
      _logger.e('$method - Exception: $e');
      return Left(mapExceptionToFailure(e));
    } catch (e, stack) {
      _logger.e('$method - Erreur inconnue: $e', error: e, stackTrace: stack);
      return Left(ComputationFailure(customMessage: 'Erreur de calcul de la pénalité'));
    }
  }

  @override
  Future<Either<Failure, void>> advanceBeneficiary(int groupId, int adminUserId) async {
    const method = 'advanceBeneficiary';
    _logger.i('$method - Avancement bénéficiaire groupe $groupId');
    try {
      final group = await _likelembaDao.getById(groupId);
      if (group == null) return Left(ValidationFailure('Groupe introuvable.'));
      if (group.adminLink.value?.id != adminUserId) {
        return Left(ValidationFailure('Seul l\'administrateur peut effectuer cette action.'));
      }
      await _likelembaDao.advanceBeneficiary(groupId);

      final outbox = OutboxModel()
        ..actionType = 'ADVANCE_BENEFICIARY'
        ..payload = '{"groupId": $groupId}'
        ..priority = 3;
      await _outboxDao.create(outbox);

      return const Right(null);
    } on AppException catch (e) {
      _logger.e('$method - Exception: $e');
      return Left(mapExceptionToFailure(e));
    } catch (e, stack) {
      _logger.e('$method - Erreur inconnue: $e', error: e, stackTrace: stack);
      return Left(CacheFailure(customMessage: 'Erreur lors de l\'avancement'));
    }
  }

 // lib/data/repositories/tontine_repository_impl.dart

@override
Future<Either<Failure, List<entity.LikelembaGroup>>> getGroupsManagedBy(int adminUserId) async {
  const method = 'getGroupsManagedBy';
  _logger.d('$method - Début pour admin $adminUserId');
  
  try {
    _logger.d('$method - Appel au remote...');
    final groupResponses = await _tontineRemoteDataSource.getManagedGroups();
    _logger.d('$method - ${groupResponses.length} réponses reçues');

    final List<entity.LikelembaGroup> groups = [];
    for (final response in groupResponses) {
      final model = LikelembaModel()
        ..remoteId = response.id
        ..groupName = response.name
        ..description = response.description
        ..dailyContribution = response.contributionAmount
        ..securityFeeRate = response.securityFeeRate
        ..basePenaltyRate = response.penaltyRateInitial
        ..cycleDurationDays = response.cycleDurationDays
        ..regenerationTargetDays = response.regenerationTargetDays
        ..currentReserveFund = response.reserveAmount
        ..currentBeneficiaryIndex = response.currentBeneficiaryIndex
        ..isLocked = response.isLocked
        ..lockedAt = response.startedAt
        ..createdAt = response.createdAt
        ..cycleStartDate = response.startedAt ?? DateTime.now();

      final localId = await _likelembaDao.create(model);
      model.id = localId;
      groups.add(await model.toEntity());
    }

    _logger.d('$method - ${groups.length} groupes persistés');
    return Right(groups);
  } on AppException catch (e) {
    _logger.e('$method - Exception: $e');
    return Left(mapExceptionToFailure(e));
  } catch (e, stack) {
    _logger.e('$method - Erreur: $e', error: e, stackTrace: stack);
    return Left(CacheFailure(customMessage: 'Erreur de récupération des groupes'));
  }
}

  // -------------------------------------------------------------------------
  // Conversion Entité ↔ Modèle
  // -------------------------------------------------------------------------

  LikelembaModel _fromEntity(entity.LikelembaGroup group) {
    return LikelembaModel()
      ..groupName = group.groupName
      ..description = group.description
      ..cycleDurationDays = group.cycleDurationDays
      ..dailyContribution = group.dailyContribution
      ..securityFeeRate = group.securityFeeRate
      ..basePenaltyRate = group.basePenaltyRate
      ..regenerationTargetDays = group.regenerationTargetDays
      ..currentReserveFund = group.currentReserveFund
      ..currentBeneficiaryIndex = group.currentBeneficiaryIndex
      ..isLocked = group.isLocked
      ..lockedAt = group.lockedAt
      ..createdAt = group.createdAt
      ..cycleStartDate = group.cycleStartDate;
  }
}

// -----------------------------------------------------------------------------
// Extension de conversion LikelembaModel → LikelembaGroup (Entité)
// -----------------------------------------------------------------------------

extension LikelembaModelToEntity on LikelembaModel {
  Future<entity.LikelembaGroup> toEntity() async {
    await adminLink.load();
    await memberLinks.load();

    return entity.LikelembaGroup(
      id: this.id,
      groupName: groupName,
      description: description,
      createdAt: createdAt,
      cycleStartDate: cycleStartDate,
      cycleDurationDays: cycleDurationDays,
      dailyContribution: dailyContribution,
      securityFeeRate: securityFeeRate,
      basePenaltyRate: basePenaltyRate,
      regenerationTargetDays: regenerationTargetDays,
      currentReserveFund: currentReserveFund,
      currentBeneficiaryIndex: currentBeneficiaryIndex,
      isLocked: isLocked,
      lockedAt: lockedAt,
      adminId: adminLink.value?.id ?? 0,
      memberIds: memberLinks.map((u) => u.id).toList(),
      remoteId: remoteId, // ajouté
    );
  }
}
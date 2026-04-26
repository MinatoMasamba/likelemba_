// lib/domain/usecases/tontine/create_group_use_case.dart

import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';
import '../../../core/error/failures.dart';
import '../../entities/likelemba_group.dart';
import '../../repositories/i_tontine_repository.dart';

class CreateGroupUseCase {
  final ITontineRepository _tontineRepository;
  final Logger _logger = Logger();

  CreateGroupUseCase(this._tontineRepository);

  Future<Either<Failure, LikelembaGroup>> call({
    required String name,
    String? description,
    required double contributionAmount,
    required double securityFeeRate,
    required double penaltyRateInitial,
    required int cycleDurationDays,
    required int adminUserId,
  }) async {
    const method = 'CreateGroupUseCase.call';
    _logger.i('$method - Création du groupe "$name" par admin $adminUserId');

    final group = LikelembaGroup(
      id: 0, // temporaire, sera mis à jour par le serveur/local
      groupName: name,
      description: description,
      createdAt: DateTime.now(),
      cycleStartDate: DateTime.now(),
      cycleDurationDays: cycleDurationDays,
      dailyContribution: contributionAmount,
      securityFeeRate: securityFeeRate,
      basePenaltyRate: penaltyRateInitial,
      regenerationTargetDays: 3,
      currentReserveFund: 0.0,
      currentBeneficiaryIndex: 0,
      isLocked: false,
      adminId: adminUserId,
      memberIds: [adminUserId],
      remoteId: null,
    );

    return await _tontineRepository.createGroup(group, adminUserId);
  }
}
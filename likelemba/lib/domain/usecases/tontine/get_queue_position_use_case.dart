// lib/domain/usecases/tontine/get_queue_position_use_case.dart

import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';
import '../../../../core/error/failures.dart';
import '../../repositories/i_tontine_repository.dart';

class GetQueuePositionUseCase {
  final ITontineRepository _tontineRepository;
  final Logger _logger = Logger();

  GetQueuePositionUseCase(this._tontineRepository);

  Future<Either<Failure, QueuePosition>> call(String groupId, String userId) async {
    const method = 'GetQueuePositionUseCase.call';
    _logger.d('$method - Position pour $userId dans $groupId');

    final result = await _tontineRepository.getGroupById(int.parse(groupId));
    return result.fold(
      (failure) => Left(failure),
      (group) {
        if (group == null) return Left(ValidationFailure('Groupe introuvable.'));
        final memberIndex = group.memberIds.indexOf(int.parse(userId));
        if (memberIndex == -1) return Left(ValidationFailure('Membre non trouvé.'));

        final currentIndex = group.currentBeneficiaryIndex;
        final memberCount = group.memberCount;

        int positionsBefore;
        if (memberIndex >= currentIndex) {
          positionsBefore = memberIndex - currentIndex;
        } else {
          positionsBefore = memberCount - currentIndex + memberIndex;
        }

        final estimatedDays = positionsBefore * 1;
        final position = QueuePosition(
          position: positionsBefore + 1,
          estimatedDays: estimatedDays,
          totalMembers: memberCount,
        );

        _logger.d('$method - Position: ${position.position}/$memberCount, ~$estimatedDays jours');
        return Right(position);
      },
    );
  }
}

/// Modèle de résultat pour la position dans la file d'attente.
class QueuePosition {
  final int position;
  final int estimatedDays;
  final int totalMembers;

  QueuePosition({
    required this.position,
    required this.estimatedDays,
    required this.totalMembers,
  });
}
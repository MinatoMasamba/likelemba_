// lib/domain/usecases/tontine/calculate_cycle_projection_use_case.dart

import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/edo_solver.dart';
import '../../repositories/i_tontine_repository.dart';
import '../../entities/likelemba_group.dart';

/// 📈 Use Case : Projection de l'évolution du fonds de réserve via EDO.
///
/// Utilise l'utilitaire [EDOSolver] pour simuler la croissance du fonds
/// sur les prochains cycles.
class CalculateCycleProjectionUseCase {
  final ITontineRepository _tontineRepository;
  final Logger _logger = Logger();

  CalculateCycleProjectionUseCase(this._tontineRepository);

  /// Calcule une projection du fonds de réserve sur [projectionDays] jours.
  ///
  /// [groupId] : Identifiant du groupe.
  /// [projectionDays] : Nombre de jours à projeter (défaut 365).
  /// Retourne une liste de [FundState] représentant l'évolution.
  Future<Either<Failure, List<FundState>>> call(String groupId, {int projectionDays = 365}) async {
    const method = 'CalculateCycleProjectionUseCase.call';
    _logger.i('$method - Projection sur $projectionDays jours pour groupe $groupId');

    final groupResult = await _tontineRepository.getGroupById(int.parse(groupId));
    return groupResult.fold(
      (failure) => Left(failure),
      (group) {
        if (group == null) {
          return Left(ValidationFailure('Groupe introuvable.'));
        }
        // Appel de l'EDO Solver (méthode statique)
        try {
          final projection = EDOSolver.simulate(
            initialFund: group.currentReserveFund,
            memberCount: group.memberCount,
            dailySecurityFee: group.dailyContribution * group.securityFeeRate,
            days: projectionDays,
          );
          _logger.i('$method - Projection calculée (${projection.length} points)');
          return Right(projection);
        } catch (e) {
          _logger.e('$method - Erreur EDO: $e');
          return Left(ComputationFailure(customMessage: 'Erreur de calcul mathématique.'));
        }
      },
    );
  }
}
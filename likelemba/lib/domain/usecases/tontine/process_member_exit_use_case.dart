// lib/domain/usecases/tontine/process_member_exit_use_case.dart

import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/penalty_calculator.dart';
import '../../repositories/i_tontine_repository.dart';
import '../../repositories/i_transaction_repository.dart';
import '../../entities/transaction.dart';

class ProcessMemberExitUseCase {
  final ITontineRepository _tontineRepository;
  final ITransactionRepository _transactionRepository;
  final Logger _logger = Logger();

  ProcessMemberExitUseCase(this._tontineRepository, this._transactionRepository);

  Future<Either<Failure, double>> call(String groupId, String userId) async {
    const method = 'ProcessMemberExitUseCase.call';
    _logger.i('$method - Sortie du membre $userId du groupe $groupId');

    // 1. Récupérer le groupe
    final groupResult = await _tontineRepository.getGroupById(int.parse(groupId));
    return groupResult.fold(
      (failure) => Left(failure),
      (group) async {
        if (group == null) {
          return Left(ValidationFailure('Groupe introuvable.'));
        }

        // 2. Vérifier que le membre fait partie du groupe
        if (!group.memberIds.contains(userId)) {
          return Left(ValidationFailure('L\'utilisateur n\'est pas membre de ce groupe.'));
        }

        // 3. Récupérer le total cotisé par le membre
        final contribResult = await _transactionRepository.getUserTotalContribution(int.parse(groupId), int.parse(userId));
        return contribResult.fold(
          (failure) => Left(failure),
          (totalContributed) async {
            // 4. Calculer la pénalité et le remboursement
            final elapsedDays = group.elapsedDays;
            final refund = PenaltyCalculator.calculateRefund(
              totalContributed: totalContributed,
              elapsedDays: elapsedDays,
              totalCycleDays: group.cycleDurationDays,
              basePenalty: group.basePenaltyRate,
            );
            final penaltyAmount = totalContributed - refund;
            _logger.i('$method - Pénalité: $penaltyAmount, Remboursement: $refund');

            // 5. Vérifier la solvabilité du fonds de réserve
            final reserveResult = await _transactionRepository.getCurrentReserveFund(int.parse(groupId));
            return reserveResult.fold(
              (failure) => Left(failure),
              (currentFund) async {
                if (currentFund - refund < 0) {
                  return Left(ValidationFailure(
                    'Le fonds de réserve est insuffisant pour ce remboursement. '
                    'Contactez l\'administrateur.',
                  ));
                }

                // 6. Créer la transaction de remboursement
                final refundTransaction = Transaction(
                  id: DateTime.now().millisecondsSinceEpoch,
                  timestamp: DateTime.now(),
                  amount: refund,
                  currency: TransactionCurrency.cdf,
                  type: TransactionType.refund,
                  status: TransactionStatus.pending,
                  userId: userId,
                  groupId: groupId,
                  isSynced: false,
                );

                final txResult = await _transactionRepository.submitTransaction(refundTransaction);
                return txResult.fold(
                  (failure) => Left(failure),
                  (_) => Right(refund),
                );
              },
            );
          },
        );
      },
    );
  }
}
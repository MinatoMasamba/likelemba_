// lib/domain/usecases/transaction/submit_contribution_use_case.dart

import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';
import '../../../../core/error/failures.dart';
import '../../repositories/i_transaction_repository.dart';
import '../../repositories/i_tontine_repository.dart';
import '../../entities/transaction.dart';

class SubmitContributionUseCase {
  final ITransactionRepository _transactionRepository;
  final ITontineRepository _tontineRepository;
  final Logger _logger = Logger();

  SubmitContributionUseCase(this._transactionRepository, this._tontineRepository);

  Future<Either<Failure, Transaction>> call({
    required String groupId,
    required String userId,
    required double amount,
    String? proofImageUrl,
  }) async {
    const method = 'SubmitContributionUseCase.call';
    _logger.i('$method - Cotisation de $amount par $userId pour groupe $groupId');

    final groupResult = await _tontineRepository.getGroupById(int.parse(groupId));
    return groupResult.fold(
      (failure) => Left(failure),
      (group) {
        if (group == null) return Left(ValidationFailure('Groupe introuvable.'));

        if (amount != group.dailyContribution) {
          return Left(ValidationFailure(
            'Le montant doit être exactement de ${group.dailyContribution}.',
          ));
        }

        final transaction = Transaction(
          id: DateTime.now().millisecondsSinceEpoch,
          timestamp: DateTime.now(),
          amount: amount,
          currency: TransactionCurrency.cdf,
          type: TransactionType.contribution,
          status: TransactionStatus.pending,
          proofImageUrl: proofImageUrl,
          userId: userId,
          groupId: groupId,
          isSynced: false,
        );

        return _transactionRepository.submitTransaction(transaction);
      },
    );
  }
}
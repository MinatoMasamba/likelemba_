// lib/domain/usecases/transaction/validate_payment_use_case.dart

import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';
import '../../../../core/error/failures.dart';
import '../../repositories/i_transaction_repository.dart';
import '../../repositories/i_tontine_repository.dart';

/// ✅ Use Case : Validation d'une transaction par l'administrateur.
class ValidatePaymentUseCase {
  final ITransactionRepository _transactionRepository;
  final ITontineRepository _tontineRepository;
  final Logger _logger = Logger();

  ValidatePaymentUseCase(this._transactionRepository, this._tontineRepository);

  /// Valide une transaction en attente.
  ///
  /// [transactionId] : Identifiant de la transaction.
  /// [adminUserId] : Identifiant de l'administrateur qui valide.
  Future<Either<Failure, void>> call(String transactionId, String adminUserId) async {
    const method = 'ValidatePaymentUseCase.call';
    _logger.i('$method - Validation transaction $transactionId par admin $adminUserId');

    // 1. Récupérer la transaction (via un getById à ajouter dans l'interface)
    // Pour simplifier, on suppose que le repository a une méthode pour ça.
    // Ici on passe directement à la validation.

    final result = await _transactionRepository.validateTransaction(int.parse(transactionId), int.parse(adminUserId));
    return result.fold(
      (failure) {
        _logger.e('$method - Échec validation: $failure');
        return Left(failure);
      },
      (_) async {
        _logger.i('$method - Transaction validée avec succès');
        // Augmenter le trustScore du membre (logique métier supplémentaire)
        // Pourrait être un autre Use Case ou une mise à jour directe.
        return const Right(null);
      },
    );
  }
}
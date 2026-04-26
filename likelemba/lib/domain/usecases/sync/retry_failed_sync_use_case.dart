// lib/domain/usecases/sync/retry_failed_sync_use_case.dart

import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';
import '../../../../core/error/failures.dart';
import '../../repositories/i_sync_repository.dart';

/// 🔁 Use Case : Réessai des synchronisations ayant échoué.
class RetryFailedSyncUseCase {
  final ISyncRepository _syncRepository;
  final Logger _logger = Logger();

  RetryFailedSyncUseCase(this._syncRepository);

  /// Analyse les échecs et relance ce qui peut l'être.
  Future<Either<Failure, void>> call() async {
    const method = 'RetryFailedSyncUseCase.call';
    _logger.i('$method - Tentative de reprise des échecs');

    // Le repository gère la logique de réessai (ex: remise en pending des erreurs réseau)
    final result = await _syncRepository.resolveConflicts();
    return result.fold(
      (failure) {
        _logger.e('$method - Échec: $failure');
        return Left(failure);
      },
      (_) {
        _logger.i('$method - Reprise terminée');
        return const Right(null);
      },
    );
  }
}
// lib/domain/usecases/sync/process_outbox_use_case.dart

import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';
import '../../../../core/error/failures.dart';
import '../../entities/sync_entities.dart' as domain;
import '../../repositories/i_sync_repository.dart';
import '../../repositories/i_sync_repository.dart';

/// 🔄 Use Case : Traitement de la file d'attente Outbox.
class ProcessOutboxUseCase {
  final ISyncRepository _syncRepository;
  final Logger _logger = Logger();

  ProcessOutboxUseCase(this._syncRepository);

  /// Déclenche l'envoi des actions en attente vers le serveur.
  Future<Either<Failure, domain.PushResult>> call() async {
    const method = 'ProcessOutboxUseCase.call';
    _logger.i('$method - Début du traitement de l\'Outbox');

    final result = await _syncRepository.pushPendingActions();
    return result.fold(
      (failure) {
        _logger.e('$method - Échec: $failure');
        return Left(failure);
      },
      (pushResult) {
        _logger.i('$method - Synced: ${pushResult.syncedIds.length}, Failed: ${pushResult.failedIds.length}');
        return Right(pushResult as domain.PushResult);
      },
    );
  }
}
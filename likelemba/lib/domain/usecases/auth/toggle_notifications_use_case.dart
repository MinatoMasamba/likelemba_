// lib/domain/usecases/auth/toggle_notifications_use_case.dart

import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';
import '../../../../core/error/failures.dart';
import '../../repositories/i_auth_repository.dart';

/// 🔔 Use Case : Activation/Désactivation des notifications push.
class ToggleNotificationsUseCase {
  final IAuthRepository _authRepository;
  final Logger _logger = Logger();

  ToggleNotificationsUseCase(this._authRepository);

  /// Active ou désactive les notifications pour l'utilisateur courant.
  ///
  /// [enabled] : `true` pour activer, `false` pour désactiver.
  Future<Either<Failure, void>> call(bool enabled) async {
    const method = 'ToggleNotificationsUseCase.call';
    _logger.i('$method - Activation notifications: $enabled');

    final result = await _authRepository.toggleNotifications(enabled);
    return result.fold(
      (failure) {
        _logger.e('$method - Échec: $failure');
        return Left(failure);
      },
      (_) {
        _logger.i('$method - Notifications ${enabled ? "activées" : "désactivées"} avec succès.');
        return const Right(null);
      },
    );
  }
}

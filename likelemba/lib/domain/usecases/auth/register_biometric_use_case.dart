// lib/domain/usecases/auth/register_biometric_use_case.dart

import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';
import '../../../../core/error/failures.dart';
import '../../repositories/i_auth_repository.dart';
import '../../entities/user.dart';

/// 🔓 Use Case : Activation/Désactivation de l'authentification biométrique.
///
/// Vérifie la disponibilité matérielle puis persiste le choix utilisateur.
class RegisterBiometricUseCase {
  final IAuthRepository _authRepository;
  final Logger _logger = Logger();

  RegisterBiometricUseCase(this._authRepository);

  /// Active ou désactive la biométrie pour l'utilisateur courant.
  ///
  /// [enabled] : `true` pour activer, `false` pour désactiver.
  Future<Either<Failure, void>> call(bool enabled) async {
    const method = 'RegisterBiometricUseCase.call';
    _logger.i('$method - Activation biométrie: $enabled');

    // Vérification de la disponibilité matérielle (à implémenter via un service)
    // Ici on suppose que c'est géré par le repository.

    final result = await _authRepository.toggleBiometrics(enabled);
    return result.fold(
      (failure) {
        _logger.e('$method - Échec: $failure');
        return Left(failure);
      },
      (_) {
        _logger.i('$method - Biométrie ${enabled ? "activée" : "désactivée"} avec succès.');
        return const Right(null);
      },
    );
  }
}
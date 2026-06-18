// lib/domain/usecases/auth/change_pin_use_case.dart

import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';
import '../../../../core/error/failures.dart';
import '../../repositories/i_auth_repository.dart';

/// 🔑 Use Case : Changement du code PIN de l'utilisateur courant.
class ChangePinUseCase {
  final IAuthRepository _authRepository;
  final Logger _logger = Logger();

  ChangePinUseCase(this._authRepository);

  /// Valide les nouveaux PIN puis délègue le changement au repository.
  Future<Either<Failure, void>> call({
    required String oldPin,
    required String newPin,
    required String confirmPin,
  }) async {
    const method = 'ChangePinUseCase.call';

    if (newPin.length < 4 || newPin.length > 6) {
      return Left(ValidationFailure('Le nouveau PIN doit contenir entre 4 et 6 chiffres.'));
    }
    if (RegExp(r'[^0-9]').hasMatch(newPin)) {
      return Left(ValidationFailure('Le PIN ne doit contenir que des chiffres.'));
    }
    if (newPin != confirmPin) {
      return Left(ValidationFailure('Les deux PIN ne correspondent pas.'));
    }
    if (newPin == oldPin) {
      return Left(ValidationFailure('Le nouveau PIN doit être différent de l\'ancien.'));
    }

    _logger.i('$method - Changement de PIN en cours.');
    final result = await _authRepository.changePin(oldPin, newPin);
    return result.fold(
      (failure) {
        _logger.e('$method - Échec: $failure');
        return Left(failure);
      },
      (_) {
        _logger.i('$method - PIN changé avec succès.');
        return const Right(null);
      },
    );
  }
}

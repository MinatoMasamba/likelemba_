// lib/domain/usecases/auth/register_user_use_case.dart

import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';
import '../../../core/error/failures.dart';
import '../../entities/user.dart';
import '../../repositories/i_auth_repository.dart';

class RegisterUserUseCase {
  final IAuthRepository _authRepository;
  final Logger _logger = Logger();

  RegisterUserUseCase(this._authRepository);

  Future<Either<Failure, User>> call({
    required String name,
    required String phoneNumber,
    required String pin,
    required UserRole role,
  }) async {
    const method = 'RegisterUserUseCase.call';
    _logger.i('$method - Création compte pour $name ($phoneNumber) avec rôle ${role.name}');

    // Validation métier
    if (pin.length < 4) {
      return Left(ValidationFailure('Le PIN doit contenir au moins 4 chiffres.'));
    }
    if (phoneNumber.isEmpty) {
      return Left(ValidationFailure('Le numéro de téléphone est requis.'));
    }

    return await _authRepository.registerUser(
      name: name,
      phoneNumber: phoneNumber,
      pin: pin,
      role: role,
    );
  }
}
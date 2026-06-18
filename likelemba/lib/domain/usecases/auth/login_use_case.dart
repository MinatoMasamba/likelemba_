// lib/domain/usecases/auth/login_use_case.dart

import 'package:dartz/dartz.dart';
import 'package:likelemba/domain/entities/user.dart';
import 'package:logger/logger.dart';
import '../../../../core/error/failures.dart';
import '../../repositories/i_auth_repository.dart';
import '../../repositories/i_sync_repository.dart';

/// 🔐 Use Case : Authentification par téléphone et PIN.
///
/// Valide le format du numéro, déclenche la vérification OTP,
/// puis synchronise le profil utilisateur après connexion réussie.
class LoginUseCase {
  final IAuthRepository _authRepository;
  final ISyncRepository _syncRepository;
  final Logger _logger = Logger();

  LoginUseCase(this._authRepository, this._syncRepository);

  /// Exécute le processus de connexion.
  ///
  /// [phoneNumber] : Numéro au format international (+243...).
  /// [pin] : Code secret de l'utilisateur.
  /// Retourne l'entité [User] en cas de succès.
  Future<Either<Failure, User>> call(String phoneNumber, String pin) async {
    const method = 'LoginUseCase.call';
    _logger.i('$method - Tentative de connexion pour $phoneNumber');

    final normalized = _normalize(phoneNumber);

    if (!_isValidPhoneNumber(normalized)) {
      _logger.w('$method - Numéro invalide: $phoneNumber');
      return Left(ValidationFailure('Format de numéro de téléphone invalide.'));
    }

    _logger.i('$method - Numéro normalisé: $normalized');

    // Appel au repository d'authentification
    final result = await _authRepository.verifyOtp(normalized, pin);
    return result.fold(
      (failure) {
        _logger.e('$method - Échec connexion: $failure');
        return Left(failure);
      },
      (user) async {
        _logger.i('$method - Connexion réussie pour ${user.name}');
        // Synchronisation du profil pour mettre à jour le trustScore
        await _syncRepository.pullRemoteUpdates(DateTime.now(), []);
        return Right(user);
      },
    );
  }

  /// Convertit un numéro local congolais (0XXXXXXXXX) en format international (+243XXXXXXXXX).
  /// Les numéros déjà au format +... sont retournés inchangés.
  String _normalize(String phone) {
    final digits = phone.trim();
    if (digits.startsWith('+')) return digits;
    // Numéro local : 0XXXXXXXXX → +243XXXXXXXXX
    if (digits.startsWith('0') && digits.length == 10) {
      return '+243${digits.substring(1)}';
    }
    // Numéro sans indicatif ni zéro : 9XXXXXXXXX (9 chiffres)
    if (!digits.startsWith('0') && digits.length == 9) {
      return '+243$digits';
    }
    return digits;
  }

  bool _isValidPhoneNumber(String phone) {
    final regex = RegExp(r'^\+[1-9]\d{7,14}$');
    return regex.hasMatch(phone);
  }
}
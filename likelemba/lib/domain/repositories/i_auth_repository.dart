// lib/domain/repositories/i_auth_repository.dart

import 'package:dartz/dartz.dart';
import '../../core/error/failures.dart';
import '../entities/user.dart';

/// 🔐 Interface du repository d'authentification (Contrat domaine).
///
/// Définit les opérations liées à l'identité et à la sécurité de l'utilisateur.
/// L'implémentation concrète se trouve dans la couche `data`.
abstract class IAuthRepository {
  /// Demande l'envoi d'un code OTP par SMS pour le numéro spécifié.
  Future<Either<Failure, void>> requestOtp(String phoneNumber);

  /// Vérifie le code OTP reçu et authentifie l'utilisateur.
  /// Retourne l'entité [User] correspondante en cas de succès.
  Future<Either<Failure, User>> verifyOtp(String phoneNumber, String code);

  /// Récupère l'utilisateur actuellement connecté (session active).
  /// Retourne `null` si aucun utilisateur n'est authentifié.
  Future<Either<Failure, User?>> getCurrentUser();

  /// Déconnecte l'utilisateur et nettoie toutes les données sensibles locales.
  Future<Either<Failure, void>> logout();

   Future<Either<Failure, User>> registerUser({
    required String name,
    required String phoneNumber,
    required String pin,
    required UserRole role,
  });


  /// Active ou désactive l'authentification biométrique pour l'utilisateur courant.
  /// [enabled] : `true` pour activer, `false` pour désactiver.
  Future<Either<Failure, void>> toggleBiometrics(bool enabled);

  /// Active ou désactive les notifications push pour l'utilisateur courant.
  /// [enabled] : `true` pour activer, `false` pour désactiver.
  Future<Either<Failure, void>> toggleNotifications(bool enabled);

  /// Change le code PIN de l'utilisateur courant.
  /// [oldPin] : PIN actuel (vérifié côté serveur).
  /// [newPin] : nouveau PIN à enregistrer.
  Future<Either<Failure, void>> changePin(String oldPin, String newPin);
}
// lib/core/error/failures.dart

import 'package:logger/logger.dart';

import 'app_exception.dart';

/// 🛡️ Hiérarchie des échecs métier (Failures) pour l'interface utilisateur.
///
/// Dans la Clean Architecture, les exceptions techniques sont converties
/// en `Failure` dans la couche `data` (repositories). Ces objets contiennent
/// des messages compréhensibles et adaptés au contexte utilisateur.
/// L'UI peut ensuite les afficher ou déclencher des retours haptiques.
abstract class Failure {
  final String message;
  final Logger _logger = Logger();

  Failure(this.message) {
    _logger.w('Failure créée : ${runtimeType.toString()} - $message');
  }

  @override
  String toString() => 'Failure: $message';
}

// -----------------------------------------------------------------------------
// 🌐 Échecs réseau
// -----------------------------------------------------------------------------

class ServerFailure extends Failure {
  ServerFailure({String? customMessage})
      : super(customMessage ??
            'Impossible de contacter le serveur. Votre transaction a été enregistrée localement et sera synchronisée dès que la connexion sera rétablie.');
}

class ConnectionFailure extends Failure {
  ConnectionFailure()
      : super(
            'Pas de connexion internet. Vous êtes en mode hors-ligne. Vos actions seront synchronisées automatiquement.');
}

class TimeoutFailure extends Failure {
  TimeoutFailure() : super('Le serveur met trop de temps à répondre. Veuillez réessayer.');
}

class ExchangeRateFailure extends Failure {
  ExchangeRateFailure()
      : super(
            'Impossible de récupérer le taux de change actuel. La conversion sera effectuée avec le dernier taux connu.');
}

// -----------------------------------------------------------------------------
// 💾 Échecs de cache (Isar)
// -----------------------------------------------------------------------------

class CacheFailure extends Failure {
  CacheFailure({String? customMessage})
      : super(customMessage ??
            'Erreur lors de l\'accès aux données locales. Redémarrez l\'application si le problème persiste.');
}

class WriteCacheFailure extends CacheFailure {
  WriteCacheFailure()
      : super(customMessage:
            'Échec de sauvegarde locale. Vérifiez l\'espace disponible sur votre appareil.');
}

class ReadCacheFailure extends CacheFailure {
  ReadCacheFailure()
      : super(customMessage:
            'Impossible de charger vos données. Une synchronisation peut être nécessaire.');
}

// -----------------------------------------------------------------------------
// 🧮 Échecs mathématiques (EDO)
// -----------------------------------------------------------------------------

class ComputationFailure extends Failure {
  ComputationFailure({String? customMessage})
      : super(customMessage ??
            'Le calcul financier n\'a pas pu aboutir. Nos équipes ont été notifiées.');
}

class UnstableScenarioFailure extends ComputationFailure {
  UnstableScenarioFailure()
      : super(customMessage:
            'Le scénario demandé est trop instable. Contactez l\'administrateur du groupe.');
}

class InvalidParameterFailure extends ComputationFailure {
  InvalidParameterFailure(String paramName)
      : super(customMessage: 'La valeur fournie pour "$paramName" est invalide.');
}

// -----------------------------------------------------------------------------
// 🔐 Échecs d'authentification
// -----------------------------------------------------------------------------

class AuthenticationFailure extends Failure {
  AuthenticationFailure({String? customMessage})
      : super(customMessage ?? 'Échec de l\'authentification. Vérifiez vos identifiants.');
}

class BiometricFailure extends Failure {
  BiometricFailure()
      : super(
            'Authentification biométrique échouée. Veuillez utiliser votre code secret.');
}

// -----------------------------------------------------------------------------
// 🧾 Échecs de validation métier (spécifiques Likelemba)
// -----------------------------------------------------------------------------

class ValidationFailure extends Failure {
  ValidationFailure(String message) : super(message);
}

class InsufficientReserveFailure extends ValidationFailure {
  InsufficientReserveFailure()
      : super(
            'Le fonds de réserve est trop bas pour autoriser ce retrait. La stabilité du groupe est prioritaire.');
}

class NotYourTurnFailure extends ValidationFailure {
  NotYourTurnFailure()
      : super('Ce n\'est pas votre tour de recevoir la cagnotte. Veuillez patienter.');
}

class ExitNotAllowedFailure extends ValidationFailure {
  ExitNotAllowedFailure()
      : super(
            'Vous ne pouvez pas quitter le groupe à ce stade avancé du cycle. Veuillez contacter l\'administrateur.');
}

class GroupFullFailure extends ValidationFailure {
  GroupFullFailure() : super('Ce groupe est complet. Aucune place disponible.');
}

class MemberNotFoundFailure extends ValidationFailure {
  MemberNotFoundFailure() : super('Membre introuvable dans ce groupe.');
}

// -----------------------------------------------------------------------------
// 🔄 Utilitaire de conversion Exception -> Failure
// -----------------------------------------------------------------------------

/// Convertit une [AppException] en [Failure] appropriée pour l'UI.
///
/// À utiliser dans les repositories pour transformer les erreurs techniques
/// en échecs métier consommables par les UseCases.
Failure mapExceptionToFailure(AppException exception) {
  final logger = Logger();
  logger.d('Mapping Exception -> Failure : ${exception.runtimeType}');

  // Réseau
  if (exception is ServerException) {
    return ServerFailure(customMessage: exception.message);
  }
  if (exception is NetworkException) {
    return ConnectionFailure();
  }
  if (exception is TimeoutException) {
    return TimeoutFailure();
  }
  if (exception is ExchangeRateException) {
    return ExchangeRateFailure();
  }

  // Cache
  if (exception is WriteCacheException) {
    return WriteCacheFailure();
  }
  if (exception is ReadCacheException) {
    return ReadCacheFailure();
  }
  if (exception is CacheException) {
    return CacheFailure(customMessage: exception.message);
  }

  // Calcul
  if (exception is UnstableFinancialScenarioException) {
    return UnstableScenarioFailure();
  }
  if (exception is InvalidParameterException) {
    return InvalidParameterFailure(exception.message);
  }
  if (exception is ComputationException) {
    return ComputationFailure(customMessage: exception.message);
  }

  // Auth
  if (exception is BiometricException) {
    return BiometricFailure();
  }
  if (exception is AuthenticationException) {
    return AuthenticationFailure(customMessage: exception.message);
  }

  // Validation métier
  if (exception is InsufficientFundsException) {
    return InsufficientReserveFailure();
  }
  if (exception is NotYourTurnException) {
    return NotYourTurnFailure();
  }
  if (exception is ValidationException) {
    return ValidationFailure(exception.message);
  }

  // Fallback
  return ValidationFailure('Une erreur inattendue est survenue. Veuillez réessayer.');
}

// lib/core/error/failures.dart

// ... autres classes de Failure ...

class SyncFailure extends Failure {
  SyncFailure({String? customMessage})
      : super(customMessage ?? 'Échec de la synchronisation avec le serveur.');
}
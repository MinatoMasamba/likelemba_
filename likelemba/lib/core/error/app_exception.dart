// lib/core/error/app_exception.dart

import 'package:logger/logger.dart';

/// 🚨 Hiérarchie des exceptions techniques du projet Likelemba Sécurisé.
///
/// Ces exceptions sont levées dans les couches `data` (sources de données)
/// et `core/utils` (calculs mathématiques). Elles ne doivent jamais être
/// affichées directement à l'utilisateur. Utilisez les `Failure` correspondantes
/// dans la couche `domain`.
///
/// **Améliorations 2026 :**
/// - Logger statique unique pour éviter les allocations multiples.
/// - Capture automatique de la stack trace si non fournie (sauf pour les
///   exceptions de validation métier où la trace est superflue).
abstract class AppException implements Exception {
  final String message;
  final StackTrace? stackTrace;

  // Logger unique partagé par toutes les instances
  static final Logger _logger = Logger();

  /// Crée une exception technique.
  ///
  /// Si [stackTrace] est `null`, la stack trace courante est automatiquement
  /// capturée pour faciliter le débogage.
  AppException(this.message, [StackTrace? stackTrace])
      : stackTrace = stackTrace ?? _captureStackTrace() {
    _logError();
  }

  /// Constructeur protégé pour les exceptions métier qui ne nécessitent pas
  /// de stack trace (ex: `ValidationException`).
  ///
  /// Ce constructeur **ne capture pas** automatiquement la stack trace.
  AppException.withoutStackTrace(this.message) : stackTrace = null {
    _logError();
  }

  /// Capture la stack trace courante en nettoyant les frames internes.
  static StackTrace _captureStackTrace() {
    // StackTrace.current inclut la ligne d'appel du constructeur.
    return StackTrace.current;
  }

  void _logError() {
    _logger.e(
      '${runtimeType.toString()}: $message',
      error: this,
      stackTrace: stackTrace,
    );
  }
}

// -----------------------------------------------------------------------------
// 🌐 Exceptions liées au réseau
// -----------------------------------------------------------------------------

class ServerException extends AppException {
  final int? statusCode;
  ServerException(String message, {this.statusCode, StackTrace? stackTrace})
      : super('[HTTP ${statusCode ?? "N/A"}] $message', stackTrace);
}

class NetworkException extends AppException {
  NetworkException(String message, {StackTrace? stackTrace})
      : super('Erreur de connexion : $message', stackTrace);
}

class TimeoutException extends AppException {
  TimeoutException(String message, {StackTrace? stackTrace})
      : super('Délai d\'attente dépassé : $message', stackTrace);
}

class ExchangeRateException extends AppException {
  ExchangeRateException(String message, {StackTrace? stackTrace})
      : super('Échec récupération taux de change : $message', stackTrace);
}

// -----------------------------------------------------------------------------
// 💾 Exceptions liées au cache local (Isar)
// -----------------------------------------------------------------------------

class CacheException extends AppException {
  CacheException(String message, StackTrace? stackTrace, {StackTrace? stackTrace2})
      : super('Erreur base de données locale : $message', stackTrace);
}

class WriteCacheException extends CacheException {
  WriteCacheException(String message, StackTrace stack, {StackTrace? stackTrace})
      : super('Échec d\'écriture : $message', stackTrace);
}

class ReadCacheException extends CacheException {
  ReadCacheException(String message, StackTrace stack, {StackTrace? stackTrace})
      : super('Échec de lecture : $message', stackTrace);
}

// -----------------------------------------------------------------------------
// 🧮 Exceptions liées aux calculs mathématiques (EDO)
// -----------------------------------------------------------------------------

class ComputationException extends AppException {
  ComputationException(String message, StackTrace? stackTrace, {StackTrace? stackTrace2})
      : super('Erreur de calcul mathématique : $message', stackTrace);
}

class UnstableFinancialScenarioException extends ComputationException {
  UnstableFinancialScenarioException({StackTrace? stackTrace})
      : super(
          'Le scénario financier est trop instable pour être calculé.',
          stackTrace,
        );
}

class InvalidParameterException extends ComputationException {
  InvalidParameterException(String paramName, {StackTrace? stackTrace})
      : super('Paramètre invalide : $paramName', stackTrace);
}

// -----------------------------------------------------------------------------
// 🔐 Exceptions liées à l'authentification et à la sécurité
// -----------------------------------------------------------------------------

class AuthenticationException extends AppException {
  AuthenticationException(String message, {StackTrace? stackTrace})
      : super('Échec authentification : $message', stackTrace);
}

class BiometricException extends AppException {
  BiometricException(String message, {StackTrace? stackTrace})
      : super('Erreur biométrique : $message', stackTrace);
}

// -----------------------------------------------------------------------------
// 🧾 Exceptions de validation métier (pas de stack trace automatique)
// -----------------------------------------------------------------------------

class ValidationException extends AppException {
  ValidationException(String message) : super.withoutStackTrace(message);
}

class InsufficientFundsException extends ValidationException {
  InsufficientFundsException() : super('Fonds insuffisants pour effectuer cette opération.');
}

class NotYourTurnException extends ValidationException {
  NotYourTurnException() : super('Ce n\'est pas votre tour de recevoir la cagnotte.');
}
// lib/data/repositories/auth_repository_impl.dart

import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:logger/logger.dart';

import '../../core/error/failures.dart';
import '../../core/error/app_exception.dart';
import '../local/isar_service.dart';
import '../local/daos/user_dao.dart';
import '../local/models/user_model.dart';
import '../remote/auth_remote_data_source.dart';
import '../../domain/entities/user.dart' as entity;
import '../../domain/repositories/i_auth_repository.dart';

/// Implémentation concrète du repository d'authentification.
/// Respecte le pattern Offline-First : l'utilisateur est d'abord persisté localement
/// après une authentification réussie, puis synchronisé avec le serveur.
class AuthRepositoryImpl implements IAuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final UserDao _userDao;
  final IsarService _isarService;
  final Logger _logger = Logger();

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required UserDao userDao,
    required IsarService isarService,
  })  : _remoteDataSource = remoteDataSource,
        _userDao = userDao,
        _isarService = isarService;
        
  String? _currentAccessToken;
  
  /// ✅ Getter public pour le token actuel
  String? get currentAccessToken => _currentAccessToken;
  /// Demande un code OTP pour le numéro donné.
  @override
  Future<Either<Failure, void>> requestOtp(String phoneNumber) async {
    const method = 'requestOtp';
    _logger.i('$method - Demande OTP pour $phoneNumber');
    try {
      await _remoteDataSource.requestOtp(phoneNumber);
      return const Right(null);
    } on AppException catch (e) {
      _logger.e('$method - Exception: $e');
      return Left(mapExceptionToFailure(e));
    } catch (e) {
      _logger.e('$method - Erreur inconnue: $e');
      return Left(ServerFailure(customMessage: 'Erreur inattendue lors de la demande OTP'));
    }
  }

  /// Vérifie l'OTP et connecte l'utilisateur.
  /// En cas de succès, persiste l'utilisateur localement et retourne l'entité [User].
// lib/data/repositories/auth_repository_impl.dart

// lib/data/repositories/auth_repository_impl.dart

// lib/data/repositories/auth_repository_impl.dart

@override
Future<Either<Failure, entity.User>> verifyOtp(String phoneNumber, String code) async {
  const method = 'verifyOtp';
  _logger.i('$method - Vérification OTP pour $phoneNumber');
  try {
    final authResponse = await _remoteDataSource.verifyOtp(phoneNumber, code);

    // LOG COMPLET DE LA RÉPONSE
    print('========== AUTHRESPONSE REÇUE ==========');
    print('accountType: ${authResponse.accountType}');
    print('isAdmin: ${authResponse.isAdmin}');
    print('========================================');

    // ✅ Sauvegarder le token
    _currentAccessToken = authResponse.accessToken;
    print('Token JWT sauvegardé : ${_currentAccessToken?.substring(0, 30)}...');

    final existingUser = await _userDao.getByPhoneNumber(phoneNumber);
    if (existingUser != null) {
      existingUser.name = authResponse.fullName;
      existingUser.isBiometricEnabled = authResponse.biometricEnabled;
      // Utilise isAdmin pour déterminer le rôle
      existingUser.role = authResponse.isAdmin ? UserRole.admin : UserRole.member;
      print('########### le rôle de l\'utilisateur connecté: ${existingUser.role}');
      await _userDao.update(existingUser);
      return Right(existingUser.toEntity());
    }

    final newUser = UserModel()
      ..name = authResponse.fullName
      ..phoneNumber = phoneNumber
      ..pinHash = _hashPin(code)
      ..createdAt = DateTime.now()
      ..role = authResponse.isAdmin ? UserRole.admin : UserRole.member
      ..status = UserStatus.active
      ..trustScore = 100
      ..isBiometricEnabled = authResponse.biometricEnabled;
    final id = await _userDao.create(newUser);
    newUser.id = id;
    print('########### Nouvel utilisateur créé, rôle: ${newUser.role}');
    return Right(newUser.toEntity());
  } on AppException catch (e) {
    _logger.e('$method - Exception: $e');
    return Left(mapExceptionToFailure(e));
  } catch (e, stack) {
    _logger.e('$method - Erreur inconnue: $e', error: e, stackTrace: stack);
    return Left(AuthenticationFailure(customMessage: 'Échec de la vérification OTP'));
  }
}

  /// Récupère l'utilisateur actuellement connecté depuis le cache local.
  @override
  Future<Either<Failure, entity.User?>> getCurrentUser() async {
    const method = 'getCurrentUser';
    _logger.d('$method - Récupération utilisateur courant');
    try {
      // Idéalement, on stocke l'ID de l'utilisateur connecté dans SharedPreferences.
      // Pour l'exemple, on prend le premier utilisateur actif.
      final users = await _userDao.getAllActive();
      if (users.isEmpty) return const Right(null);
      return Right(users.first.toEntity());
    } on AppException catch (e) {
      _logger.e('$method - Exception: $e');
      return Left(mapExceptionToFailure(e));
    } catch (e, stack) {
      _logger.e('$method - Erreur inconnue: $e', error: e, stackTrace: stack);
      return Left(CacheFailure(customMessage: 'Impossible de récupérer l\'utilisateur'));
    }
  }

  /// Active ou désactive l'authentification biométrique pour l'utilisateur courant.
@override
Future<Either<Failure, void>> toggleBiometrics(bool enabled) async {
  const method = 'toggleBiometrics';
  _logger.i('$method - Activation biométrie: $enabled');
  try {
    // Récupère l'utilisateur connecté
    final currentUserResult = await getCurrentUser();
    
    // Utilisation de fold pour extraire la valeur ou propager l'erreur
    return currentUserResult.fold(
      (failure) {
        _logger.e('$method - Échec récupération utilisateur: ${failure.message}');
        return Left(failure);
      },
      (currentUserEntity) async {
        if (currentUserEntity == null) {
          _logger.w('$method - Aucun utilisateur connecté.');
          return Left(CacheFailure(customMessage: 'Aucun utilisateur connecté'));
        }

        // Récupère le modèle correspondant pour mise à jour
        final userModel = await _userDao.getById(currentUserEntity.id);
        if (userModel == null) {
          _logger.e('$method - Utilisateur ID ${currentUserEntity.id} introuvable en base.');
          return Left(CacheFailure(customMessage: 'Utilisateur introuvable en base'));
        }

        userModel.isBiometricEnabled = enabled;
        await _userDao.update(userModel);
        _logger.i('$method - Biométrie mise à jour avec succès.');
        return const Right(null);
      },
    );
  } on AppException catch (e) {
    _logger.e('$method - Exception applicative: $e');
    return Left(mapExceptionToFailure(e));
  } catch (e, stack) {
    _logger.e('$method - Erreur inconnue: $e', error: e, stackTrace: stack);
    return Left(CacheFailure(customMessage: 'Erreur lors de la modification de la biométrie'));
  }
}

  /// Active ou désactive les notifications push pour l'utilisateur courant.
@override
Future<Either<Failure, void>> toggleNotifications(bool enabled) async {
  const method = 'toggleNotifications';
  _logger.i('$method - Activation notifications: $enabled');
  try {
    final currentUserResult = await getCurrentUser();

    return currentUserResult.fold(
      (failure) {
        _logger.e('$method - Échec récupération utilisateur: ${failure.message}');
        return Left(failure);
      },
      (currentUserEntity) async {
        if (currentUserEntity == null) {
          _logger.w('$method - Aucun utilisateur connecté.');
          return Left(CacheFailure(customMessage: 'Aucun utilisateur connecté'));
        }

        final userModel = await _userDao.getById(currentUserEntity.id);
        if (userModel == null) {
          _logger.e('$method - Utilisateur ID ${currentUserEntity.id} introuvable en base.');
          return Left(CacheFailure(customMessage: 'Utilisateur introuvable en base'));
        }

        userModel.notificationsEnabled = enabled;
        await _userDao.update(userModel);
        _logger.i('$method - Notifications mises à jour avec succès.');
        return const Right(null);
      },
    );
  } on AppException catch (e) {
    _logger.e('$method - Exception applicative: $e');
    return Left(mapExceptionToFailure(e));
  } catch (e, stack) {
    _logger.e('$method - Erreur inconnue: $e', error: e, stackTrace: stack);
    return Left(CacheFailure(customMessage: 'Erreur lors de la modification des notifications'));
  }
}

  /// Change le PIN de l'utilisateur courant (vérification serveur + mise à jour locale).
@override
Future<Either<Failure, void>> changePin(String oldPin, String newPin) async {
  const method = 'changePin';
  _logger.i('$method - Changement de PIN demandé');
  try {
    await _remoteDataSource.changePin(oldPin, newPin);

    final currentUserResult = await getCurrentUser();
    return currentUserResult.fold(
      (failure) {
        _logger.e('$method - Échec récupération utilisateur: ${failure.message}');
        return Left(failure);
      },
      (currentUserEntity) async {
        if (currentUserEntity == null) {
          _logger.w('$method - Aucun utilisateur connecté.');
          return Left(CacheFailure(customMessage: 'Aucun utilisateur connecté'));
        }

        final userModel = await _userDao.getById(currentUserEntity.id);
        if (userModel == null) {
          _logger.e('$method - Utilisateur ID ${currentUserEntity.id} introuvable en base.');
          return Left(CacheFailure(customMessage: 'Utilisateur introuvable en base'));
        }

        userModel.pinHash = _hashPin(newPin);
        await _userDao.update(userModel);
        _logger.i('$method - PIN changé avec succès.');
        return const Right(null);
      },
    );
  } on AppException catch (e) {
    _logger.e('$method - Exception applicative: $e');
    return Left(mapExceptionToFailure(e));
  } catch (e, stack) {
    _logger.e('$method - Erreur inconnue: $e', error: e, stackTrace: stack);
    return Left(CacheFailure(customMessage: 'Erreur lors du changement de PIN'));
  }
}

  /// Déconnecte l'utilisateur : révoque le token distant et efface les données locales.
  @override
  Future<Either<Failure, void>> logout() async {
    const method = 'logout';
    _logger.i('$method - Déconnexion');
    try {
      await _remoteDataSource.logout();
      // Effacement de toutes les données locales (conformément à la directive de sécurité)
      await _isarService.clearAllData();
      return const Right(null);
    } on AppException catch (e) {
      _logger.e('$method - Exception: $e');
      return Left(mapExceptionToFailure(e));
    } catch (e, stack) {
      _logger.e('$method - Erreur inconnue: $e', error: e, stackTrace: stack);
      return Left(ServerFailure(customMessage: 'Erreur lors de la déconnexion'));
    }
  }

// lib/data/repositories/auth_repository_impl.dart

@override
Future<Either<Failure, entity.User>> registerUser({
  required String name,
  required String phoneNumber,
  required String pin,
  required entity.UserRole role,
}) async {
  const method = 'registerUser';
  _logger.i('$method - Création utilisateur $name ($phoneNumber)');

  try {
    // Validation locale (identique au sérialiseur)
    final validationError = _validateRegistrationInput(name, phoneNumber, pin);
    if (validationError != null) {
      return Left(ValidationFailure(validationError));
    }

    // 1. Appel au serveur via le remote data source
    final registeredUser = await _remoteDataSource.register(
      name: name,
      phoneNumber: phoneNumber,
      pin: pin,
      role: role.name
    );

    // 2. Persistance locale dans Isar
    final userModel = UserModel()
      ..name = name
      ..phoneNumber = phoneNumber
      ..pinHash = _hashPin(pin)
      ..createdAt = DateTime.now()
      ..role = UserRole.member
      ..status = UserStatus.active
      ..trustScore = 100
      ..isBiometricEnabled = false;

    final id = await _userDao.create(userModel);
    userModel.id = id;

    _logger.i('$method - Utilisateur créé localement avec id $id');
    return Right(userModel.toEntity());
  } on ValidationException catch (e) {
    _logger.w('$method - Erreur de validation: ${e.message}');
    return Left(ValidationFailure(e.message));
  } on AppException catch (e) {
    _logger.e('$method - Exception: $e');
    return Left(mapExceptionToFailure(e));
  } catch (e, stack) {
    _logger.e('$method - Erreur inconnue: $e', error: e, stackTrace: stack);
    return Left(ServerFailure(customMessage: 'Erreur lors de la création du compte'));
  }
}

/// Validation locale des données d'inscription
String? _validateRegistrationInput(String name, String phoneNumber, String pin) {
  // Validation du nom
  if (name.trim().isEmpty) {
    return 'Le nom complet est requis.';
  }
  if (name.length < 3) {
    return 'Le nom doit contenir au moins 3 caractères.';
  }

  // Validation du téléphone (format congolais/international)
  final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
  if (!phoneRegex.hasMatch(phoneNumber)) {
    return 'Numéro de téléphone invalide. Format attendu: +243XXXXXXXXX';
  }

  // Validation du PIN
  if (pin.isEmpty) {
    return 'Le code PIN est requis.';
  }
  if (pin.length < 4) {
    return 'Le code PIN doit contenir au moins 4 chiffres.';
  }
  if (pin.length > 6) {
    return 'Le code PIN ne doit pas dépasser 6 chiffres.';
  }
  if (!RegExp(r'^\d+$').hasMatch(pin)) {
    return 'Le code PIN ne doit contenir que des chiffres.';
  }

  return null;
}

String _hashPin(String pin) {
  // Utiliser crypto package pour un vrai hachage
  // Pour l'exemple, on retourne le PIN (À REMPLACER)
  return pin;
}

}

// -----------------------------------------------------------------------------
// Extension de conversion UserModel → User (Entité)
// -----------------------------------------------------------------------------

extension UserModelToEntity on UserModel {
  entity.User toEntity() => entity.User(
    id: this.id,
    name: name,
    phoneNumber: phoneNumber,
    role: role == UserRole.admin ? entity.UserRole.admin : entity.UserRole.member,
    status: status == UserStatus.active
        ? entity.UserStatus.active
        : (status == UserStatus.suspended ? entity.UserStatus.suspended : entity.UserStatus.closed),
    trustScore: trustScore,
    totalContribution: totalContribution,
    isBiometricEnabled: isBiometricEnabled,
    notificationsEnabled: notificationsEnabled,
  );
}
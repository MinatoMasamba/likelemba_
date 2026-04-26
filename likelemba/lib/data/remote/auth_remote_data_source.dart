// lib/data/remote/auth_remote_data_source.dart

import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/error/app_exception.dart';

/// 🔐 Remote Data Source responsable des opérations d'authentification.
///
/// Communique avec le backend pour :
/// - Envoyer/vérifier des OTP par SMS
/// - Gérer les tokens JWT (access + refresh)
/// - Enregistrer l'appareil pour la biométrie
/// - Déconnexion
///
/// **Sécurité** : Aucune donnée sensible (PIN, OTP, token) n'est loggée.
class AuthRemoteDataSource {
  static const String tag = 'AuthRemoteDataSource';
  final ApiClient _apiClient;

  AuthRemoteDataSource(this._apiClient);

  /// Demande l'envoi d'un code OTP par SMS.
  Future<void> requestOtp(String phoneNumber) async {
    const method = 'requestOtp';
    print('$tag.$method - Demande OTP pour $phoneNumber');

    try {
      final response = await _apiClient.dio.post(
        '/auth/request-otp',
        data: {'phoneNumber': phoneNumber},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        print('$tag.$method - Échec HTTP ${response.statusCode}');
        throw ServerException(
          'Échec de la demande OTP',
          statusCode: response.statusCode,
        );
      }
      print('$tag.$method - OTP envoyé avec succès');
    } on DioException catch (e) {
      print('$tag.$method - DioException: ${e.message}');
      throw _mapDioException(e, method);
    } catch (e) {
      print('$tag.$method - Erreur inattendue: $e');
      throw ServerException('Erreur lors de la demande OTP');
    }
  }

  /// Vérifie le code OTP et retourne les tokens et les données utilisateur.
  Future<AuthResponse> verifyOtp(String phoneNumber, String code) async {
    const method = 'verifyOtp';
    print('$tag.$method - Vérification OTP pour $phoneNumber');

    try {
      final response = await _apiClient.dio.post(
        'v1/users/auth/token/',
        data: {'phone_number': phoneNumber, 'password': code},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('$tag.$method - Vérification réussie');
        return AuthResponse.fromJson(data);
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        final data = response.data as Map<String, dynamic>?;
        final message = data?['detail'] ?? data?['non_field_errors']?.first ?? 'Identifiants invalides';
        throw AuthenticationException(message.toString());
      } else {
        print('$tag.$method - Échec HTTP ${response.statusCode}');
        throw ServerException('Échec de vérification OTP', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      print('$tag.$method - DioException: ${e.message}');
      throw _mapDioException(e, method);
    } catch (e) {
      print('$tag.$method - Erreur inattendue: $e');
      throw AuthenticationException('Erreur lors de la vérification OTP');
    }
  }

  /// Enregistre l'appareil courant pour l'authentification biométrique.
  Future<void> registerDevice(String deviceId, String biometricPublicKey) async {
    const method = 'registerDevice';
    print('$tag.$method - Enregistrement device $deviceId');

    try {
      final response = await _apiClient.dio.post(
        '/auth/register-device',
        data: {'deviceId': deviceId, 'publicKey': biometricPublicKey},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        print('$tag.$method - Échec HTTP ${response.statusCode}');
        throw ServerException(
          'Échec enregistrement device',
          statusCode: response.statusCode,
        );
      }
      print('$tag.$method - Device enregistré avec succès');
    } on DioException catch (e) {
      print('$tag.$method - DioException: ${e.message}');
      throw _mapDioException(e, method);
    } catch (e) {
      print('$tag.$method - Erreur inattendue: $e');
      throw ServerException('Erreur enregistrement device');
    }
  }

  /// Rafraîchit le token d'accès en utilisant le refresh token.
  Future<AuthResponse> refreshToken(String refreshToken) async {
    const method = 'refreshToken';
    print('$tag.$method - Rafraîchissement token');

    try {
      final response = await _apiClient.dio.post(
        '/auth/refresh',
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('$tag.$method - Tokens rafraîchis');
        return AuthResponse.fromJson(data);
      } else {
        print('$tag.$method - Échec HTTP ${response.statusCode}');
        throw AuthenticationException('Session expirée');
      }
    } on DioException catch (e) {
      print('$tag.$method - DioException: ${e.message}');
      throw _mapDioException(e, method);
    } catch (e) {
      print('$tag.$method - Erreur inattendue: $e');
      throw AuthenticationException('Erreur refresh token');
    }
  }

  /// Déconnecte l'utilisateur (révocation token côté serveur).
  Future<void> logout() async {
    const method = 'logout';
    print('$tag.$method - Déconnexion');

    try {
      await _apiClient.dio.post('/auth/logout');
      print('$tag.$method - Déconnexion réussie');
    } on DioException catch (e) {
      print('$tag.$method - DioException ignorée: ${e.message}');
    } catch (e) {
      print('$tag.$method - Erreur ignorée: $e');
    }
  }

  /// Inscription d'un nouvel utilisateur.
  Future<Map<String, dynamic>> register({
    required String name,
    required String phoneNumber,
    required String pin,
    required String role,
  }) async {
    const method = 'register';
    print('$tag.$method - Création compte pour $phoneNumber');

    try {
      final response = await _apiClient.dio.post(
        'v1/users/auth/register/',
        data: {
          'full_name': name,
          'phone_number': phoneNumber,
          'password': pin,
          'password2': pin,
          'account_type': role,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('$tag.$method - Compte créé avec succès');
        return response.data as Map<String, dynamic>;
      } else if (response.statusCode == 400) {
        final errors = response.data as Map<String, dynamic>;
        final errorMessage = _formatValidationErrors(errors);
        throw ValidationException(errorMessage);
      } else {
        throw ServerException(
          'Échec de la création du compte',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      print('$tag.$method - DioException: ${e.message}');
      if (e.response?.statusCode == 400) {
        final errors = e.response?.data as Map<String, dynamic>? ?? {};
        final errorMessage = _formatValidationErrors(errors);
        throw ValidationException(errorMessage);
      }
      throw _mapDioException(e, method);
    } catch (e) {
      print('$tag.$method - Erreur inattendue: $e');
      throw ServerException('Erreur lors de la création du compte');
    }
  }

  /// Formate les erreurs de validation Django REST Framework.
  String _formatValidationErrors(Map<String, dynamic> errors) {
    final buffer = StringBuffer();
    errors.forEach((field, messages) {
      if (messages is List) {
        buffer.writeln('$field: ${messages.join(', ')}');
      } else {
        buffer.writeln('$field: $messages');
      }
    });
    return buffer.toString().trim();
  }

  /// Mappe une DioException vers une AppException appropriée.
  AppException _mapDioException(DioException e, String method) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return TimeoutException('Délai de connexion dépassé');
    }
    if (e.type == DioExceptionType.connectionError || e.error is SocketException) {
      return NetworkException('Aucune connexion Internet');
    }
    if (e.response != null) {
      final statusCode = e.response!.statusCode;
      final message = e.response!.data?['message'] ?? 'Erreur serveur';
      return ServerException(message, statusCode: statusCode);
    }
    return ServerException('Erreur réseau inconnue');
  }
}

// lib/data/remote/auth_remote_data_source.dart

/// 🔑 Réponse complète de l'authentification (tokens + données utilisateur).
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final String userId;
  final String phoneNumber;
  final String fullName;
  final String accountType;
  final bool isAdmin;
  final bool phoneVerified;
  final bool emailVerified;
  final bool biometricEnabled;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.phoneNumber,
    required this.fullName,
    required this.accountType,
    required this.isAdmin,
    required this.phoneVerified,
    required this.emailVerified,
    required this.biometricEnabled,
  }) {
    print('AuthResponse créée - userId: $userId, accountType: $accountType, isAdmin: $isAdmin');
  }

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final accountType = (json['account_type'] as String?)?.toLowerCase() ?? 'participant';
    print('AuthResponse.fromJson - account_type reçu: $accountType');

    return AuthResponse(
      accessToken: json['access'] as String,
      refreshToken: json['refresh'] as String,
      userId: json['user_id'].toString(),
      phoneNumber: json['phone_number'] as String,
      fullName: json['full_name'] as String? ?? '',
      accountType: accountType,
      isAdmin: accountType == 'admin', // déduit du champ account_type
      phoneVerified: json['phone_verified'] as bool? ?? false,
      emailVerified: json['email_verified'] as bool? ?? false,
      biometricEnabled: json['biometric_enabled'] as bool? ?? false,
    );
  }
}
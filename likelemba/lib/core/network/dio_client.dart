// lib/core/network/dio_client.dart

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// 🌐 Client HTTP configuré pour le projet Likelemba Sécurisé.
///
/// Centralise la configuration de [Dio] :
/// - Timeouts adaptés aux réseaux instables (RDC).
/// - Intercepteurs pour l'authentification, les logs et la retry logic.
/// - Gestion des erreurs de connexion (SocketException).
class DioClient {
  static const String tag = 'DioClient';

  late final Dio _dio;

 // ✅ Ajouter un callback pour récupérer le token dynamiquement
  String? Function()? _getToken;

  DioClient({
    required String baseUrl,
    String? authToken,
    String? Function()? getToken, // nouveau paramètre
  }) : _getToken = getToken {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

   // ✅ AuthInterceptor utilise maintenant le callback dynamique
    _dio.interceptors.add(AuthInterceptor(getToken: getToken));
    _dio.interceptors.add(RetryInterceptor(dio: _dio));
    if (kDebugMode) {
      _dio.interceptors.add(LoggingInterceptor());
    }
  }

  /// Accès à l'instance Dio pour les appels personnalisés.
  Dio get instance => _dio;
}

// -----------------------------------------------------------------------------
// 🔐 Interceptor pour injecter le token d'authentification
// -----------------------------------------------------------------------------

class AuthInterceptor extends Interceptor {
  final String? Function()? getToken;

  AuthInterceptor({this.getToken});
  
    static const String tag = 'DioClient-AuthInterceptor';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = getToken?.call();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
      print('$tag.AuthInterceptor - Token ajouté aux headers.');
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('$tag.AuthInterceptor - Erreur interceptée: ${err.message}');
    if (err.response?.statusCode == 401) {
      print('$tag.AuthInterceptor - ⚠️ Token expiré ou invalide (401). Déconnexion nécessaire.');
      // TODO: Émettre un événement pour rediriger vers la page de login.
    }
    handler.next(err);
  }
}

// -----------------------------------------------------------------------------
// 🔄 Interceptor pour retry automatique en cas d'échec réseau
// -----------------------------------------------------------------------------

class RetryInterceptor extends Interceptor {
  final Dio dio;
  static const int maxRetries = 2;
   static const String tag = 'DioClient-RetryInterceptor';
  static const Duration retryDelay = Duration(seconds: 2);

  RetryInterceptor({required this.dio});

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Ne retenter que les erreurs réseau ou timeout
    if (_shouldRetry(err) && err.requestOptions.extra['retryCount'] == null) {
      int attempt = 1;
      while (attempt <= maxRetries) {
        print('$tag.RetryInterceptor - Tentative de rejeu $attempt/$maxRetries pour ${err.requestOptions.path}');
        try {
          final options = err.requestOptions;
          options.extra['retryCount'] = attempt;
          await Future.delayed(retryDelay);
          final response = await dio.fetch(options);
          return handler.resolve(response);
        } catch (e) {
          attempt++;
          if (attempt > maxRetries) {
            print('$tag.RetryInterceptor - ❌ Échec après $maxRetries tentatives.');
          }
        }
      }
    }
    handler.next(err);
  }

  bool _shouldRetry(DioException err) {
    return err.type == DioExceptionType.connectionTimeout ||
           err.type == DioExceptionType.sendTimeout ||
           err.type == DioExceptionType.receiveTimeout ||
           err.error is SocketException; // Pas de réseau
  }
}

// -----------------------------------------------------------------------------
// 📋 Interceptor pour logger les requêtes/réponses (debug uniquement)
// -----------------------------------------------------------------------------

class LoggingInterceptor extends Interceptor {
    static const String tag = 'DioClient-LoggingInterceptor';
  
    @override
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('$tag.LoggingInterceptor - 🌐 REQUEST[${options.method}] => ${options.baseUrl}${options.path}');
    print('$tag.LoggingInterceptor - Headers: ${options.headers}');
    print('$tag.LoggingInterceptor - Body: ${options.data}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('$tag.LoggingInterceptor - ✅ RESPONSE[${response.statusCode}] => ${response.requestOptions.path}');
    print('$tag.LoggingInterceptor - Data: ${response.data}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('$tag.LoggingInterceptor - ❌ ERROR[${err.type}] => ${err.requestOptions.path}');
    print('$tag.LoggingInterceptor - Message: ${err.message}');
    handler.next(err);
  }
}
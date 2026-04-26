// lib/core/network/api_client.dart

import 'dart:async';

import 'package:dio/dio.dart';

import 'dio_client.dart';

/// 📡 Client API métier pour le projet Likelemba Sécurisé.
///
/// Expose des méthodes claires pour interagir avec le backend.
/// **Règle Clean Architecture :** Ce client ne renvoie jamais d'objets Dio bruts.
/// Il retourne des `Map<String, dynamic>` ou lève des exceptions métier.
class ApiClient {
  static const String tag = 'ApiClient';
  final DioClient _dioClient;

  ApiClient({required DioClient dioClient}) : _dioClient = dioClient;

  Dio get _dio => _dioClient.instance;

  // ✅ GETTER PUBLIC POUR LES REMOTE DATA SOURCES
  Dio get dio => _dio;

  // -------------------------------------------------------------------------
  // 💱 Taux de change (USD → CDF)
  // -------------------------------------------------------------------------

  /// Récupère le taux de change actuel USD → CDF depuis une API externe gratuite.
  ///
  /// Exemple d'API utilisée : [ExchangeRate-API](https://www.exchangerate-api.com)
  /// Retourne un `double` représentant le nombre de Francs Congolais pour 1 USD.
  /// En cas d'échec, lève une [ExchangeRateException].
  Future<double> fetchExchangeRateUSDToCDF() async {
    const method = 'fetchExchangeRateUSDToCDF';
    print('$tag.$method - Début de la récupération du taux USD/CDF.');

    try {
      // Exemple d'endpoint gratuit (à remplacer par votre clé API)
      const url = 'https://api.exchangerate-api.com/v4/latest/USD';
      final response = await _dio.get(url);

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>;
        final rate = rates['CDF'] as double?;
        if (rate != null) {
          print('$tag.$method - ✅ Taux récupéré : 1 USD = $rate CDF');
          return rate;
        } else {
          throw ExchangeRateException('Clé "CDF" absente de la réponse.');
        }
      } else {
        throw ExchangeRateException('Code HTTP inattendu : ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('$tag.$method - ❌ DioException : ${e.message}');
      throw ExchangeRateException('Erreur réseau : ${e.message}');
    } catch (e) {
      print('$tag.$method - ❌ Erreur inconnue : $e');
      throw ExchangeRateException('Erreur inattendue : $e');
    }
  }

  // -------------------------------------------------------------------------
  // 🔄 Synchronisation des transactions (Outbox Pattern)
  // -------------------------------------------------------------------------

  /// Envoie une transaction locale au serveur pour synchronisation.
  ///
  /// [payload] : Données de la transaction au format JSON.
  /// Retourne `true` si la synchronisation a réussi.
  Future<bool> syncTransaction(Map<String, dynamic> payload) async {
    const method = 'syncTransaction';
    print('$tag.$method - Tentative de synchronisation.');

    try {
      final response = await _dio.post(
        '/sync/transaction',
        data: payload,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('$tag.$method - ✅ Transaction synchronisée avec succès.');
        return true;
      }
      print('$tag.$method - ⚠️ Échec sync (${response.statusCode})');
      return false;
    } on DioException catch (e) {
      print('$tag.$method - ❌ DioException : ${e.message}');
      return false;
    } catch (e) {
      print('$tag.$method - ❌ Erreur inconnue : $e');
      return false;
    }
  }

  /// Récupère l'état de santé du serveur (ping).
  Future<bool> pingServer() async {
    const method = 'pingServer';
    try {
      final response = await _dio.get('/health');
      print('$tag.$method - Réponse serveur : ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('$tag.$method - Serveur injoignable : $e');
      return false;
    }
  }
}

/// Exception personnalisée pour les erreurs de taux de change.
class ExchangeRateException implements Exception {
  final String message;
  ExchangeRateException(this.message);

  @override
  String toString() => 'ExchangeRateException: $message';
}
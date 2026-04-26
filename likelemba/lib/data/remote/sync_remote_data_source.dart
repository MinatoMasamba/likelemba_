// lib/data/remote/sync_remote_data_source.dart

import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/error/app_exception.dart';

/// 🔄 Remote Data Source pour la synchronisation Offline-First.
///
/// Méthodes pour :
/// - Pousser les messages de l'Outbox locale vers le serveur
/// - Récupérer les mises à jour incrémentielles (delta)
/// - Téléverser des images de preuve
/// - Récupérer les détails d'un groupe
class SyncRemoteDataSource {
  static const String tag = 'SyncRemoteDataSource';
  final ApiClient _apiClient;

  SyncRemoteDataSource(this._apiClient);

  /// Envoie un lot de payloads Outbox au serveur.
  ///
  /// Retourne un [PushResult] avec les IDs synchronisés et les échecs.
  Future<PushResult> pushOutboxBatch(List<Map<String, dynamic>> payloads) async {
    const method = 'pushOutboxBatch';
    print('$tag.$method - Envoi de ${payloads.length} éléments');

    if (payloads.isEmpty) {
      return PushResult(syncedIds: [], failedIds: [], conflicts: []);
    }

    try {
      final response = await _apiClient.dio.post(
        '/sync/push',
        data: {'items': payloads},
        options: Options(receiveTimeout: const Duration(seconds: 30)),
      );

      if (response.statusCode == 200 || response.statusCode == 207) {
        final data = response.data as Map<String, dynamic>;
        print('$tag.$method - Réponse ${response.statusCode}');
        return PushResult.fromJson(data);
      } else {
        print('$tag.$method - Échec HTTP ${response.statusCode}');
        throw ServerException('Échec synchronisation', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      print('$tag.$method - DioException: ${e.message}');
      throw _mapDioException(e, method);
    } catch (e) {
      print('$tag.$method - Erreur inattendue: $e');
      throw ServerException('Erreur synchronisation');
    }
  }

  /// Récupère les mises à jour depuis une date donnée pour les groupes spécifiés.
  Future<SyncDelta> pullUpdates(DateTime lastSyncTimestamp, List<int> groupIds) async {
    const method = 'pullUpdates';
    print('$tag.$method - Récupération depuis $lastSyncTimestamp');

    if (groupIds.isEmpty) {
      return SyncDelta.empty();
    }

    try {
      final response = await _apiClient.dio.post(
        '/sync/pull',
        data: {
          'lastSync': lastSyncTimestamp.toIso8601String(),
          'groupIds': groupIds,
        },
        options: Options(receiveTimeout: const Duration(seconds: 20)),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        print('$tag.$method - Delta récupéré');
        return SyncDelta.fromJson(data);
      } else {
        print('$tag.$method - Échec HTTP ${response.statusCode}');
        throw ServerException('Échec récupération delta', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      print('$tag.$method - DioException: ${e.message}');
      throw _mapDioException(e, method);
    } catch (e) {
      print('$tag.$method - Erreur inattendue: $e');
      throw ServerException('Erreur pull updates');
    }
  }

  /// Téléverse une image de preuve de paiement et retourne son URL.
  Future<String> uploadProofImage(File imageFile) async {
    const method = 'uploadProofImage';
    print('$tag.$method - Téléversement ${imageFile.path}');

    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imageFile.path),
      });

      final response = await _apiClient.dio.post(
        '/upload/proof',
        data: formData,
        options: Options(receiveTimeout: const Duration(seconds: 60)),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        final url = data['url'] as String;
        print('$tag.$method - URL: $url');
        return url;
      } else {
        print('$tag.$method - Échec HTTP ${response.statusCode}');
        throw ServerException('Échec téléversement', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      print('$tag.$method - DioException: ${e.message}');
      throw _mapDioException(e, method);
    } catch (e) {
      print('$tag.$method - Erreur inattendue: $e');
      throw ServerException('Erreur téléversement');
    }
  }

  /// Récupère les détails à jour d'un groupe.
  Future<Map<String, dynamic>> fetchGroupDetails(int groupId) async {
    const method = 'fetchGroupDetails';
    print('$tag.$method - Groupe $groupId');

    try {
      final response = await _apiClient.dio.get(
        '/groups/$groupId',
        options: Options(receiveTimeout: const Duration(seconds: 15)),
      );

      if (response.statusCode == 200) {
        print('$tag.$method - Détails récupérés');
        return response.data as Map<String, dynamic>;
      } else {
        print('$tag.$method - Échec HTTP ${response.statusCode}');
        throw ServerException('Groupe introuvable', statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      print('$tag.$method - DioException: ${e.message}');
      throw _mapDioException(e, method);
    } catch (e) {
      print('$tag.$method - Erreur inattendue: $e');
      throw ServerException('Erreur récupération groupe');
    }
  }

  AppException _mapDioException(DioException e, String method) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return TimeoutException('Délai de connexion dépassé');
    }
    if (e.type == DioExceptionType.connectionError ||
        e.error is SocketException) {
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

/// 📦 Résultat d'un push batch.
class PushResult {
  final List<int> syncedIds;
  final List<int> failedIds;
  final List<Map<String, dynamic>> conflicts;

  PushResult({
    required this.syncedIds,
    required this.failedIds,
    required this.conflicts,
  });

  factory PushResult.fromJson(Map<String, dynamic> json) {
    return PushResult(
      syncedIds: (json['syncedIds'] as List<dynamic>?)?.cast<int>() ?? [],
      failedIds: (json['failedIds'] as List<dynamic>?)?.cast<int>() ?? [],
      conflicts: (json['conflicts'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }
}

/// 📥 Delta de synchronisation.
class SyncDelta {
  final List<Map<String, dynamic>> transactions;
  final List<Map<String, dynamic>> memberUpdates;
  final List<Map<String, dynamic>> groupUpdates;

  SyncDelta({
    required this.transactions,
    required this.memberUpdates,
    required this.groupUpdates,
  });

  factory SyncDelta.fromJson(Map<String, dynamic> json) {
    return SyncDelta(
      transactions: (json['transactions'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      memberUpdates: (json['memberUpdates'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      groupUpdates: (json['groupUpdates'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }

  static SyncDelta empty() {
    return SyncDelta(transactions: [], memberUpdates: [], groupUpdates: []);
  }
}
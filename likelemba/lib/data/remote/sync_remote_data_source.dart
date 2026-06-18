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

// -----------------------------------------------------------------------------
// Helpers de parsing tolérants (mêmes conventions que GroupResponse.fromJson)
// -----------------------------------------------------------------------------

String? _safeStringOrNull(dynamic value) => value?.toString();

double _safeDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0.0;
}

int _safeInt(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

bool _safeBool(dynamic value) =>
    value is bool ? value : (value?.toString().toLowerCase() == 'true');

DateTime? _safeDateTimeOrNull(dynamic value) {
  if (value == null) return null;
  try {
    return DateTime.parse(value.toString());
  } catch (_) {
    return null;
  }
}

/// 📦 Conflit signalé par le serveur lors d'un push.
///
/// [outboxId] identifie le message local en conflit ; [serverState] contient
/// l'état actuel de la ressource côté serveur, utilisé par [resolveConflicts]
/// pour décider si la donnée locale doit être renvoyée ou abandonnée.
class SyncConflict {
  final int outboxId;
  final Map<String, dynamic> serverState;

  SyncConflict({required this.outboxId, required this.serverState});

  factory SyncConflict.fromJson(Map<String, dynamic> json) {
    return SyncConflict(
      outboxId: _safeInt(json['outboxId'] ?? json['id']),
      serverState: (json['serverState'] as Map<String, dynamic>?) ?? json,
    );
  }
}

/// 📦 Résultat d'un push batch.
class PushResult {
  final List<int> syncedIds;
  final List<int> failedIds;
  final List<SyncConflict> conflicts;

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
              ?.map((e) => SyncConflict.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// 👤 Mise à jour d'un membre reçue du serveur.
///
/// Le numéro de téléphone sert de clé de fusion locale : il n'existe pas
/// d'identifiant serveur dédié pour [UserModel] côté local (voir [UserDao]).
class MemberDeltaDto {
  final String phoneNumber;
  final String? name;
  final int? trustScore;
  final double? totalContribution;
  final bool? isBiometricEnabled;
  final bool? notificationsEnabled;

  MemberDeltaDto({
    required this.phoneNumber,
    this.name,
    this.trustScore,
    this.totalContribution,
    this.isBiometricEnabled,
    this.notificationsEnabled,
  });

  factory MemberDeltaDto.fromJson(Map<String, dynamic> json) {
    return MemberDeltaDto(
      phoneNumber: json['phone_number']?.toString() ?? '',
      name: _safeStringOrNull(json['name']),
      trustScore: json['trust_score'] != null ? _safeInt(json['trust_score']) : null,
      totalContribution:
          json['total_contribution'] != null ? _safeDouble(json['total_contribution']) : null,
      isBiometricEnabled: json['is_biometric_enabled'] as bool?,
      notificationsEnabled: json['notifications_enabled'] as bool?,
    );
  }
}

/// 👥 Mise à jour d'un groupe reçue du serveur (mêmes clés que [GroupResponse]).
class GroupDeltaDto {
  final String id;
  final String name;
  final String? description;
  final double contributionAmount;
  final double securityFeeRate;
  final double penaltyRateInitial;
  final int cycleDurationDays;
  final int regenerationTargetDays;
  final double reserveAmount;
  final int currentBeneficiaryIndex;
  final bool isLocked;
  final DateTime? startedAt;
  final DateTime createdAt;

  GroupDeltaDto({
    required this.id,
    required this.name,
    this.description,
    required this.contributionAmount,
    required this.securityFeeRate,
    required this.penaltyRateInitial,
    required this.cycleDurationDays,
    required this.regenerationTargetDays,
    required this.reserveAmount,
    required this.currentBeneficiaryIndex,
    required this.isLocked,
    this.startedAt,
    required this.createdAt,
  });

  factory GroupDeltaDto.fromJson(Map<String, dynamic> json) {
    return GroupDeltaDto(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: _safeStringOrNull(json['description']),
      contributionAmount: _safeDouble(json['contribution_amount']),
      securityFeeRate: _safeDouble(json['security_fee_rate']),
      penaltyRateInitial: _safeDouble(json['penalty_rate_initial']),
      cycleDurationDays: _safeInt(json['cycle_duration_days']),
      regenerationTargetDays: _safeInt(json['regeneration_target_days']),
      reserveAmount: _safeDouble(json['reserve_amount']),
      currentBeneficiaryIndex: _safeInt(json['current_beneficiary_index']),
      isLocked: _safeBool(json['is_locked']),
      startedAt: _safeDateTimeOrNull(json['started_at']),
      createdAt: _safeDateTimeOrNull(json['created_at']) ?? DateTime.now(),
    );
  }
}

/// 💸 Transaction reçue du serveur.
///
/// [groupId] référence [GroupDeltaDto.id] / `LikelembaModel.remoteId`.
/// [userPhoneNumber] et [recipientPhoneNumber] référencent `UserModel.phoneNumber`.
class TransactionDeltaDto {
  final String id;
  final String groupId;
  final String userPhoneNumber;
  final String? recipientPhoneNumber;
  final double amount;
  final String currency;
  final String type;
  final String status;
  final String? note;
  final String? proofImagePath;
  final DateTime timestamp;

  TransactionDeltaDto({
    required this.id,
    required this.groupId,
    required this.userPhoneNumber,
    this.recipientPhoneNumber,
    required this.amount,
    required this.currency,
    required this.type,
    required this.status,
    this.note,
    this.proofImagePath,
    required this.timestamp,
  });

  factory TransactionDeltaDto.fromJson(Map<String, dynamic> json) {
    return TransactionDeltaDto(
      id: json['id']?.toString() ?? '',
      groupId: json['group_id']?.toString() ?? '',
      userPhoneNumber: json['user_phone_number']?.toString() ?? '',
      recipientPhoneNumber: _safeStringOrNull(json['recipient_phone_number']),
      amount: _safeDouble(json['amount']),
      currency: json['currency']?.toString() ?? 'cdf',
      type: json['type']?.toString() ?? 'contribution',
      status: json['status']?.toString() ?? 'pending',
      note: _safeStringOrNull(json['note']),
      proofImagePath: _safeStringOrNull(json['proof_image_path']),
      timestamp: _safeDateTimeOrNull(json['timestamp']) ?? DateTime.now(),
    );
  }
}

/// 📥 Delta de synchronisation.
class SyncDelta {
  final List<TransactionDeltaDto> transactions;
  final List<MemberDeltaDto> memberUpdates;
  final List<GroupDeltaDto> groupUpdates;

  SyncDelta({
    required this.transactions,
    required this.memberUpdates,
    required this.groupUpdates,
  });

  factory SyncDelta.fromJson(Map<String, dynamic> json) {
    return SyncDelta(
      transactions: (json['transactions'] as List<dynamic>?)
              ?.map((e) => TransactionDeltaDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      memberUpdates: (json['memberUpdates'] as List<dynamic>?)
              ?.map((e) => MemberDeltaDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      groupUpdates: (json['groupUpdates'] as List<dynamic>?)
              ?.map((e) => GroupDeltaDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static SyncDelta empty() {
    return SyncDelta(transactions: [], memberUpdates: [], groupUpdates: []);
  }
}
// lib/data/remote/tontine_remote_data_source.dart

import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../../core/error/app_exception.dart';

/// Source de données distante pour les opérations sur les tontines.
class TontineRemoteDataSource {
  static const String tag = 'TontineRemoteDataSource';
  final ApiClient _apiClient;

  TontineRemoteDataSource(this._apiClient);


  // lib/data/remote/tontine_remote_data_source.dart

/// Récupère la liste des groupes administrés par l'utilisateur connecté.
Future<List<GroupResponse>> getManagedGroups() async {
  const method = 'getManagedGroups';
  print('${TontineRemoteDataSource.tag}.$method - Récupération des groupes administrés');

  try {
    final response = await _apiClient.dio.get(
      'v1/tontines/groups/',
      options: Options(
        receiveTimeout: const Duration(seconds: 20),
      ),
    );

    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? [];
      print('${TontineRemoteDataSource.tag}.$method - ${results.length} groupes récupérés');
      return results.map((json) => GroupResponse.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw ServerException('Échec récupération des groupes', statusCode: response.statusCode);
    }
  } on DioException catch (e) {
    print('${TontineRemoteDataSource.tag}.$method - DioException: ${e.message}');
    throw _mapDioException(e, method);
  } catch (e) {
    print('${TontineRemoteDataSource.tag}.$method - Erreur inattendue: $e');
    throw ServerException('Erreur lors de la récupération des groupes');
  }
}

  // lib/data/remote/tontine_remote_data_source.dart

Future<List<MembershipInfo>> getMembershipsForValidation(String groupUuid) async {
  const method = 'getMembershipsForValidation';
  print('${TontineRemoteDataSource.tag}.$method - Récupération membres pour groupe $groupUuid');

  try {
    final response = await _apiClient.dio.get(
      'v1/tontines/memberships/',
      queryParameters: {
        'group': groupUuid,
        'status': 'pending',   // uniquement ceux à valider
      },
      options: Options(receiveTimeout: const Duration(seconds: 20)),
    );

    if (response.statusCode == 200) {
      print('${TontineRemoteDataSource.tag}.$method - Réponse brute: ${response.data.runtimeType}');
      // Gère les deux structures : liste paginée {"results":[]} ou liste directe []
      final List<dynamic> results;
      if (response.data is List) {
        results = response.data as List<dynamic>;
      } else {
        final data = response.data as Map<String, dynamic>;
        results = data['results'] as List<dynamic>? ?? [];
      }
      print('${TontineRemoteDataSource.tag}.$method - ${results.length} membre(s) trouvé(s)');
      return results
          .map((json) => MembershipInfo.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw ServerException('Échec récupération des membres', statusCode: response.statusCode);
    }
  } on DioException catch (e) {
    print('${TontineRemoteDataSource.tag}.$method - DioException: ${e.message}');
    throw _mapDioException(e, method);
  } catch (e, stack) {
    print('${TontineRemoteDataSource.tag}.$method - Erreur ($e): $stack');
    throw ServerException('Erreur récupération des membres');
  }
}
  /// Crée une nouvelle tontine sur le serveur.
  /// Retourne une [GroupResponse] contenant les données du groupe créé.
  Future<GroupResponse> createGroup({
    required String name,
    String description = '',
    required double contributionAmount,
    required double securityFeeRate,   // taux (0.05 = 5%)
    required double penaltyRateInitial,
    required int cycleDurationDays,
    int distributionIntervalDays = 1,
    bool isActive = true,
  }) async {
    const method = 'createGroup';
    print('${TontineRemoteDataSource.tag}.$method - Création du groupe "$name"');

    try {
      final response = await _apiClient.dio.post(
        'v1/tontines/groups/',
        data: {
          'name': name,
          'description': description,
          'contribution_amount': contributionAmount.toString(),
          'security_levy': (contributionAmount * securityFeeRate).toStringAsFixed(2), // ✅ AJOUTÉ
          'security_fee_rate': securityFeeRate,        // envoi du taux
          'penalty_rate_initial': penaltyRateInitial,
          'cycle_duration_days': cycleDurationDays,
          'distribution_interval_days': distributionIntervalDays,
          'is_active': isActive,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data as Map<String, dynamic>;
        print('${TontineRemoteDataSource.tag}.$method - Groupe créé avec succès');
        return GroupResponse.fromJson(data);
      } else if (response.statusCode == 400) {
        final errors = response.data as Map<String, dynamic>;
        final errorMessage = _formatValidationErrors(errors);
        throw ValidationException(errorMessage);
      } else {
        throw ServerException(
          'Échec de la création du groupe',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      print('${TontineRemoteDataSource.tag}.$method - DioException: ${e.message}');
      if (e.response?.statusCode == 400) {
        final errors = e.response?.data as Map<String, dynamic>? ?? {};
        final errorMessage = _formatValidationErrors(errors);
        throw ValidationException(errorMessage);
      }
      throw _mapDioException(e, method);
    } catch (e) {
      print('${TontineRemoteDataSource.tag}.$method - Erreur inattendue: $e');
      throw ServerException('Erreur lors de la création du groupe');
    }
  }

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

/// Objet de transfert (DTO) représentant la réponse complète du serveur
/// pour la création d'un groupe.
class GroupResponse {
  final String id; // UUID
  final String name;
  final String? description;
  final double contributionAmount;
  final double securityFeeRate;
  final double penaltyRateInitial;
  final int cycleDurationDays;
  final int distributionIntervalDays;
  final int regenerationTargetDays;
  final double reserveAmount;
  final int currentBeneficiaryIndex;
  final bool isActive;
  final int elapsedDays;
  final bool isCycleCompleted;
  final double grossJackpot;
  final double netJackpot;
  final bool isLocked;
  final String? inviteCode;
  final String? inviteLink;
  final String adminLink; // UUID de l'administrateur
  final String createdByName;
  final int numberOfMembers;
  final DateTime createdAt;
  final DateTime? startedAt;

  GroupResponse({
    required this.id,
    required this.name,
    this.description,
    required this.contributionAmount,
    required this.securityFeeRate,
    required this.penaltyRateInitial,
    required this.cycleDurationDays,
    required this.distributionIntervalDays,
    required this.regenerationTargetDays,
    required this.reserveAmount,
    required this.currentBeneficiaryIndex,
    required this.isActive,
    required this.elapsedDays,
    required this.isCycleCompleted,
    required this.grossJackpot,
    required this.netJackpot,
    required this.isLocked,
    this.inviteCode,
    this.inviteLink,
    required this.adminLink,
    required this.createdByName,
    required this.numberOfMembers,
    required this.createdAt,
    this.startedAt,
  });

  // lib/data/remote/tontine_remote_data_source.dart

factory GroupResponse.fromJson(Map<String, dynamic> json) {
  /// Helper pour une String non null
  String _safeString(dynamic value) => value?.toString() ?? '';
  
  /// Helper pour un double
  double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
  
  /// Helper pour un int
  int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }
  
  /// Helper pour un bool
  bool _safeBool(dynamic value) => value is bool ? value : (value?.toString().toLowerCase() == 'true');
  
  /// Helper pour DateTime nullable
  DateTime? _safeDateTime(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  print('GroupResponse.fromJson - Parsing: ${json['id']}');
  
  return GroupResponse(
    id: _safeString(json['id']),
    name: _safeString(json['name']),
    description: json['description']?.toString(),
    contributionAmount: _safeDouble(json['contribution_amount']),
    securityFeeRate: _safeDouble(json['security_fee_rate']),
    penaltyRateInitial: _safeDouble(json['penalty_rate_initial']),
    cycleDurationDays: _safeInt(json['cycle_duration_days']),
    distributionIntervalDays: _safeInt(json['distribution_interval_days']),
    regenerationTargetDays: _safeInt(json['regeneration_target_days']),
    reserveAmount: _safeDouble(json['reserve_amount']),
    currentBeneficiaryIndex: _safeInt(json['current_beneficiary_index']),
    isActive: _safeBool(json['is_active']),
    elapsedDays: _safeInt(json['elapsed_days']),
    isCycleCompleted: _safeBool(json['is_cycle_completed']),
    grossJackpot: _safeDouble(json['gross_jackpot'] ?? json['contribution_net']), // fallback
    netJackpot: _safeDouble(json['contribution_net']),
    isLocked: _safeBool(json['is_locked']),
    inviteCode: json['invite_code']?.toString(),
    inviteLink: json['invite_link']?.toString(),
    adminLink: _safeString(json['admin_link']),
    createdByName: _safeString(json['created_by_name']),
    numberOfMembers: _safeInt(json['number_of_members']),
    createdAt: _safeDateTime(json['created_at']) ?? DateTime.now(),
    startedAt: _safeDateTime(json['started_at']),
  );
}
}




/// Informations complètes pour valider le paiement d'un membre (vue admin).
class MemberValidationInfo {
  final String transactionId;
  final String userId;
  final String userName;
  final String avatarInitials;
  final double amountToValidate;
  final double debtAmount;
  final double penaltyAmount;
  final String groupName;
  final String cycleInfo;
  final String adminName;
  final DateTime date;

  MemberValidationInfo({
    required this.transactionId,
    required this.userId,
    required this.userName,
    required this.avatarInitials,
    required this.amountToValidate,
    required this.debtAmount,
    required this.penaltyAmount,
    required this.groupName,
    required this.cycleInfo,
    required this.adminName,
    required this.date,
  });

  factory MemberValidationInfo.fromJson(
    Map<String, dynamic> json, {
    String groupName = '',
    String cycleInfo = '',
    String adminName = '',
  }) {
    return MemberValidationInfo(
      transactionId: json['id']?.toString() ?? '',
      userId: json['user']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? 'Membre',
      avatarInitials: json['avatar_initials']?.toString() ?? '?',
      amountToValidate: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      debtAmount: double.tryParse(json['debt_amount']?.toString() ?? '0') ?? 0.0,
      penaltyAmount: double.tryParse(json['penalty_amount']?.toString() ?? '0') ?? 0.0,
      groupName: groupName,
      cycleInfo: cycleInfo,
      adminName: adminName,
      date: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Récupère les informations de validation d'un paiement pour un membre donné.
/// Appelle /api/v1/transactions/contributions/ filtré par groupe et utilisateur.
/// Modèle d'une demande d'adhésion en attente.
class JoinRequestInfo {
  final String id;
  final String userId;
  final String userName;
  final String avatarInitials;
  final String phoneNumber;
  final DateTime requestedAt;

  JoinRequestInfo({
    required this.id,
    required this.userId,
    required this.userName,
    required this.avatarInitials,
    required this.phoneNumber,
    required this.requestedAt,
  });

  factory JoinRequestInfo.fromJson(Map<String, dynamic> json) {
    return JoinRequestInfo(
      id: json['id']?.toString() ?? '',
      userId: json['user']?.toString() ?? '',
      userName: json['user_name']?.toString() ?? 'Utilisateur',
      avatarInitials: json['avatar_initials']?.toString() ?? '?',
      phoneNumber: json['phone_number']?.toString() ?? '',
      requestedAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

extension TontineJoinAndRequests on TontineRemoteDataSource {
  /// Rejoindre un groupe via son code d'invitation.
  Future<GroupResponse> joinGroupByInviteCode(String inviteCode) async {
    const method = 'joinGroupByInviteCode';
    print('${TontineRemoteDataSource.tag}.$method - Code: $inviteCode');
    try {
      final response = await _apiClient.dio.post(
        'v1/tontines/groups/join/',
        data: {'invite_code': inviteCode},
        options: Options(receiveTimeout: const Duration(seconds: 20)),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return GroupResponse.fromJson(response.data as Map<String, dynamic>);
      } else if (response.statusCode == 400) {
        final errors = response.data as Map<String, dynamic>? ?? {};
        throw ValidationException(_formatValidationErrors(errors));
      } else {
        throw ServerException('Impossible de rejoindre le groupe.',
            statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      print('${TontineRemoteDataSource.tag}.$method - DioException: ${e.message}');
      throw _mapDioException(e, method);
    } catch (e) {
      print('${TontineRemoteDataSource.tag}.$method - Erreur: $e');
      rethrow;
    }
  }

  /// Récupère les demandes d'adhésion en attente pour un groupe.
  Future<List<JoinRequestInfo>> getPendingJoinRequests(String groupUuid) async {
    const method = 'getPendingJoinRequests';
    print('${TontineRemoteDataSource.tag}.$method - Groupe $groupUuid');
    try {
      final response = await _apiClient.dio.get(
        'v1/tontines/join-requests/',
        queryParameters: {'group': groupUuid, 'status': 'pending'},
        options: Options(receiveTimeout: const Duration(seconds: 20)),
      );
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];
        return results
            .map((j) => JoinRequestInfo.fromJson(j as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException('Erreur récupération des demandes.',
            statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      print('${TontineRemoteDataSource.tag}.$method - DioException: ${e.message}');
      throw _mapDioException(e, method);
    } catch (e) {
      print('${TontineRemoteDataSource.tag}.$method - Erreur: $e');
      rethrow;
    }
  }

  /// Approuve une demande d'adhésion.
  Future<void> approveJoinRequest(String requestId) async {
    const method = 'approveJoinRequest';
    print('${TontineRemoteDataSource.tag}.$method - Demande $requestId');
    try {
      final response = await _apiClient.dio.post(
        'v1/tontines/join-requests/$requestId/approve/',
        options: Options(receiveTimeout: const Duration(seconds: 20)),
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException('Erreur lors de l\'approbation.',
            statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      print('${TontineRemoteDataSource.tag}.$method - DioException: ${e.message}');
      throw _mapDioException(e, method);
    } catch (e) {
      print('${TontineRemoteDataSource.tag}.$method - Erreur: $e');
      rethrow;
    }
  }

  /// Rejette une demande d'adhésion.
  Future<void> rejectJoinRequest(String requestId) async {
    const method = 'rejectJoinRequest';
    print('${TontineRemoteDataSource.tag}.$method - Demande $requestId');
    try {
      final response = await _apiClient.dio.post(
        'v1/tontines/join-requests/$requestId/reject/',
        options: Options(receiveTimeout: const Duration(seconds: 20)),
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerException('Erreur lors du rejet.',
            statusCode: response.statusCode);
      }
    } on DioException catch (e) {
      print('${TontineRemoteDataSource.tag}.$method - DioException: ${e.message}');
      throw _mapDioException(e, method);
    } catch (e) {
      print('${TontineRemoteDataSource.tag}.$method - Erreur: $e');
      rethrow;
    }
  }
}

extension PayoutRequestExtension on TontineRemoteDataSource {
  /// Envoie une demande de réception de la cagnotte à l'administrateur du groupe.
  Future<void> requestPayout({
    required String groupId,
    required String userId,
  }) async {
    const method = 'requestPayout';
    print('${TontineRemoteDataSource.tag}.$method - Groupe $groupId, Membre $userId');
    try {
      final response = await _apiClient.dio.post(
        'v1/transactions/payout-requests/',
        data: {'group_id': groupId, 'user_id': userId},
        options: Options(receiveTimeout: const Duration(seconds: 20)),
      );
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ServerException(
          'Erreur lors de la demande de réception.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      print('${TontineRemoteDataSource.tag}.$method - DioException: ${e.message}');
      throw _mapDioException(e, method);
    } catch (e) {
      print('${TontineRemoteDataSource.tag}.$method - Erreur: $e');
      rethrow;
    }
  }
}

extension MemberValidationFetch on TontineRemoteDataSource {
  Future<MemberValidationInfo> getMemberValidationInfo(
      int groupId, int userId) async {
    const method = 'getMemberValidationInfo';
    print('${TontineRemoteDataSource.tag}.$method - Groupe $groupId, Utilisateur $userId');

    try {
      final response = await _apiClient.dio.get(
        'v1/transactions/contributions/',
        queryParameters: {
          'group_id': groupId,
          'user_id': userId,
          'status': 'pending',
          'page_size': 1,
        },
        options: Options(receiveTimeout: const Duration(seconds: 20)),
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>? ?? [];

        if (results.isEmpty) {
          throw ServerException('Aucune cotisation en attente pour ce membre.');
        }

        final json = results.first as Map<String, dynamic>;
        final groupName = data['group_name']?.toString() ?? 'Groupe #$groupId';
        final cycleInfo = data['cycle_info']?.toString() ?? 'Cycle en cours';
        final adminName = data['admin_name']?.toString() ?? 'Administrateur';

        return MemberValidationInfo.fromJson(
          json,
          groupName: groupName,
          cycleInfo: cycleInfo,
          adminName: adminName,
        );
      } else {
        throw ServerException(
          'Erreur lors de la récupération des informations de validation.',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      print('${TontineRemoteDataSource.tag}.$method - DioException: ${e.message}');
      throw _mapDioException(e, method);
    } catch (e) {
      print('${TontineRemoteDataSource.tag}.$method - Erreur: $e');
      rethrow;
    }
  }
}

/// Informations sur le statut de paiement d'un membre
class MembershipInfo {
  final String userId;         // UUID du membre
  final int localUserId;       // Optionnel : ID local si connu
  final String userName;
  final String avatarInitials;
  final double amountToValidate;
  final double debtAmount;
  final double penaltyAmount;
  final String status;         // "pending", "validated", "rejected"
  final DateTime date;

  MembershipInfo({
    required this.userId,
    this.localUserId = 0,
    required this.userName,
    required this.avatarInitials,
    required this.amountToValidate,
    required this.debtAmount,
    required this.penaltyAmount,
    required this.status,
    required this.date,
  });

  factory MembershipInfo.fromJson(Map<String, dynamic> json) {
    print('MembershipInfo.fromJson - clés reçues: ${json.keys.toList()}');
    final rawUser = json['user'];
    final userId = rawUser is Map ? rawUser['id']?.toString() ?? '' : rawUser?.toString() ?? '';
    final rawName = json['user_name'] ?? json['username'] ?? json['name'];
    final userName = rawName?.toString() ?? 'Membre';
    return MembershipInfo(
      userId: userId,
      localUserId: int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      userName: userName,
      avatarInitials: json['avatar_initials']?.toString() ?? (userName.isNotEmpty ? userName[0].toUpperCase() : '?'),
      amountToValidate: double.tryParse(json['amount_to_validate']?.toString() ?? '0') ?? 0.0,
      debtAmount: double.tryParse(json['debt_amount']?.toString() ?? '0') ?? 0.0,
      penaltyAmount: double.tryParse(json['penalty_amount']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString() ?? 'pending',
      date: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
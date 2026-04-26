// lib/domain/entities/outbox_entry.dart

import 'package:equatable/equatable.dart';

/// 📤 Entité représentant une action en attente de synchronisation avec le serveur.
///
/// Encapsule l'intention métier (ex: création de transaction) indépendamment
/// du format de stockage (JSON, etc.).
class OutboxEntry extends Equatable {
  final String id;
  final OutboxActionType actionType;
  final Map<String, dynamic> payload; // Objet structuré, pas une String JSON
  final DateTime createdAt;
  final int retryCount;
  final DateTime? lastAttemptAt;
  final OutboxStatus status;
  final String? lastError;

  const OutboxEntry({
    required this.id,
    required this.actionType,
    required this.payload,
    required this.createdAt,
    required this.retryCount,
    this.lastAttemptAt,
    required this.status,
    this.lastError,
  });

  /// Priorité de traitement (plus élevé = plus urgent).
  int get priority {
    int prio;
    switch (actionType) {
      case OutboxActionType.createGroup:
      case OutboxActionType.lockGroup:
        prio = 5;
        break;
      case OutboxActionType.addMember:
      case OutboxActionType.removeMember:
        prio = 4;
        break;
      case OutboxActionType.advanceBeneficiary:
        prio = 3;
        break;
      case OutboxActionType.createTransaction:
      case OutboxActionType.updateTransactionStatus:
        prio = 2;
        break;
      default:
        prio = 1;
    }
    print('OutboxEntry.priority - $actionType → $prio');
    return prio;
  }

  /// Indique si l'entrée peut être retentée.
  bool get canRetry {
    final can = retryCount < 5 && status != OutboxStatus.synced;
    print('OutboxEntry.canRetry - $id → $can (tentatives: $retryCount)');
    return can;
  }

  OutboxEntry copyWith({
    String? id,
    OutboxActionType? actionType,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    int? retryCount,
    DateTime? lastAttemptAt,
    OutboxStatus? status,
    String? lastError,
  }) {
    return OutboxEntry(
      id: id ?? this.id,
      actionType: actionType ?? this.actionType,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
    );
  }

  @override
  List<Object?> get props => [id, actionType, createdAt, retryCount, status];
}

/// Types d'actions pouvant être mises en attente.
enum OutboxActionType {
  createGroup,
  lockGroup,
  addMember,
  removeMember,
  advanceBeneficiary,
  createTransaction,
  updateTransactionStatus,
}

/// Statut d'une entrée Outbox.
enum OutboxStatus {
  pending,
  processing,
  failed,
  synced,
}
// lib/domain/entities/likelemba_group.dart

import 'package:equatable/equatable.dart';
import 'user.dart';

/// 👥 Entité représentant un groupe de tontine rotative (Likelemba).
///
/// Contient les paramètres financiers du cycle, les variables de l'Équation
/// Différentielle Ordinaire (EDO), et la liste des membres participants.
class LikelembaGroup extends Equatable {
  final int id; // identifiant local (Isar)
  final int adminId;
  final List<int> memberIds;
  final String groupName;
  final String? description;
  final DateTime createdAt;
  final DateTime cycleStartDate;
  final int cycleDurationDays; // T

  // Paramètres financiers (EDO)
  final double dailyContribution; // S
  final double securityFeeRate; // a
  final double basePenaltyRate; // α₀
  final int regenerationTargetDays; // ΔT_max
  final double currentReserveFund; // F(t)

  // État du cycle
  final int currentBeneficiaryIndex;
  final bool isLocked;
  final DateTime? lockedAt;

  // Identifiant distant (UUID du serveur), nullable
  final String? remoteId;

  const LikelembaGroup({
    required this.id,
    required this.groupName,
    this.description,
    required this.createdAt,
    required this.cycleStartDate,
    required this.cycleDurationDays,
    required this.dailyContribution,
    required this.securityFeeRate,
    required this.basePenaltyRate,
    required this.regenerationTargetDays,
    required this.currentReserveFund,
    required this.currentBeneficiaryIndex,
    required this.isLocked,
    this.lockedAt,
    required this.adminId,
    required this.memberIds,
    this.remoteId, // <-- ajouté
  });

  /// Jours écoulés depuis le début du cycle.
  int get elapsedDays {
    final days = DateTime.now().difference(cycleStartDate).inDays;
    print('LikelembaGroup.elapsedDays - Groupe $groupName → $days jours');
    return days;
  }

  /// Indique si le cycle est terminé.
  bool get isCycleCompleted {
    final completed = elapsedDays >= cycleDurationDays;
    print('LikelembaGroup.isCycleCompleted - $groupName → $completed');
    return completed;
  }

  /// Montant total de la cagnotte théorique (avant prélèvement de sécurité).
  double get grossJackpot {
  if (memberIds.length <= 1) return 0.0;
  print('LikelembaGroup.grossJackpot - $groupName → ${(memberIds.length - 1) * dailyContribution}');
  return (memberIds.length - 1) * dailyContribution;
}

  /// Montant net de la cagnotte perçue par le bénéficiaire.
  double get netJackpot {
    final net = grossJackpot * (1 - securityFeeRate);
    print('LikelembaGroup.netJackpot - $groupName → $net');
    return net;
  }

  /// Date théorique de fin du cycle.
  DateTime get cycleEndDate {
    final end = cycleStartDate.add(Duration(days: cycleDurationDays));
    print('LikelembaGroup.cycleEndDate - $groupName → $end');
    return end;
  }

  /// Nombre total de membres.
  int get memberCount => memberIds.length;

  /// Crée une copie du groupe avec des modifications.
  LikelembaGroup copyWith({
    int? id,
    String? groupName,
    String? description,
    DateTime? createdAt,
    DateTime? cycleStartDate,
    int? cycleDurationDays,
    double? dailyContribution,
    double? securityFeeRate,
    double? basePenaltyRate,
    int? regenerationTargetDays,
    double? currentReserveFund,
    int? currentBeneficiaryIndex,
    bool? isLocked,
    DateTime? lockedAt,
    int? adminId,
    List<int>? memberIds,
    String? remoteId, // <-- ajouté
  }) {
    return LikelembaGroup(
      id: id ?? this.id,
      groupName: groupName ?? this.groupName,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      cycleStartDate: cycleStartDate ?? this.cycleStartDate,
      cycleDurationDays: cycleDurationDays ?? this.cycleDurationDays,
      dailyContribution: dailyContribution ?? this.dailyContribution,
      securityFeeRate: securityFeeRate ?? this.securityFeeRate,
      basePenaltyRate: basePenaltyRate ?? this.basePenaltyRate,
      regenerationTargetDays: regenerationTargetDays ?? this.regenerationTargetDays,
      currentReserveFund: currentReserveFund ?? this.currentReserveFund,
      currentBeneficiaryIndex: currentBeneficiaryIndex ?? this.currentBeneficiaryIndex,
      isLocked: isLocked ?? this.isLocked,
      lockedAt: lockedAt ?? this.lockedAt,
      adminId: adminId ?? this.adminId,
      memberIds: memberIds ?? this.memberIds,
      remoteId: remoteId ?? this.remoteId, // <-- ajouté
    );
  }

  @override
  List<Object?> get props => [
        id,
        groupName,
        cycleStartDate,
        cycleDurationDays,
        dailyContribution,
        securityFeeRate,
        basePenaltyRate,
        currentReserveFund,
        isLocked,
        adminId,
        memberIds,
        remoteId, // <-- ajouté
      ];
}
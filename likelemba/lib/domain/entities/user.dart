// lib/domain/entities/user.dart

import 'package:equatable/equatable.dart';

/// 🧑‍🤝‍🧑 Entité représentant un participant au système Likelemba.
///
/// Cette classe est purement métier, indépendante de toute technologie de persistance.
/// Elle définit les propriétés essentielles d'un utilisateur : identité, rôle, statut,
/// et réputation (score de confiance).
class User extends Equatable {
  final int id;
  final String name;
  final String phoneNumber;
  final UserRole role;
  final UserStatus status;
  final int trustScore; // 0 à 100
  final double totalContribution;
  final bool isBiometricEnabled;
  final bool notificationsEnabled;

  const User({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.role,
    required this.status,
    required this.trustScore,
    required this.totalContribution,
    required this.isBiometricEnabled,
    this.notificationsEnabled = true,
  });

  /// Indique si l'utilisateur est considéré comme fiable selon les critères métier.
  /// Un score >= 70 est jugé suffisant pour bénéficier de certains privilèges.
  bool get isTrusted {
    final trusted = trustScore >= 70;
    print('User.isTrusted - $name (Score: $trustScore) → ${trusted ? "Fiable" : "Risqué"}');
    return trusted;
  }

  /// Indique si l'utilisateur a le droit de créer un groupe Likelemba.
  bool get canCreateGroup {
    final can = role == UserRole.admin && status == UserStatus.active;
    print('User.canCreateGroup - $name (Role: $role, Status: $status) → $can');
    return can;
  }

  /// Crée une copie de l'utilisateur avec des champs modifiés.
  User copyWith({
    int ? id,
    String? name,
    String? phoneNumber,
    UserRole? role,
    UserStatus? status,
    int? trustScore,
    double? totalContribution,
    bool? isBiometricEnabled,
    bool? notificationsEnabled,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      role: role ?? this.role,
      status: status ?? this.status,
      trustScore: trustScore ?? this.trustScore,
      totalContribution: totalContribution ?? this.totalContribution,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  @override
  List<Object?> get props => [id, phoneNumber, role, status, trustScore];
}

/// Rôle global de l'utilisateur dans l'application.
enum UserRole {
  member, // Participant simple
  admin,  // Peut créer et gérer des groupes
}

/// Statut du compte utilisateur.
enum UserStatus {
  active,    // Compte actif
  suspended, // Suspendu temporairement
  closed,    // Compte fermé définitivement
}
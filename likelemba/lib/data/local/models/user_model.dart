// lib/data/local/models/user_model.dart

import 'package:isar/isar.dart';

part 'user_model.g.dart';
/// 🧑‍🤝‍🧑 Modèle de participant au Likelemba.
///
/// Stocke les informations d'identité, de sécurité et de réputation
/// (score de confiance) de chaque utilisateur.
///
/// **Hiérarchie :** Un champ `role` détermine si l'utilisateur peut créer
/// des groupes (Admin) ou simplement y participer (Member).
@Collection()
class UserModel {
  /// Clé primaire auto-incrémentée gérée par Isar.
  Id id = Isar.autoIncrement;

  /// Nom complet du participant.
  late String name;

  /// Numéro de téléphone unique (utilisé comme identifiant de connexion).
  /// Indexé pour des recherches rapides.
  @Index(unique: true, replace: false)
  late String phoneNumber;

  /// Code secret (PIN) hashé pour l'authentification.
  late String pinHash;

  /// Indique si l'utilisateur a activé l'authentification biométrique
  /// (empreinte digitale ou reconnaissance faciale).
  bool isBiometricEnabled = false;

  /// Indique si l'utilisateur souhaite recevoir des notifications push.
  bool notificationsEnabled = true;

  /// Date de création du compte.
  late DateTime createdAt;

  /// Montant total des cotisations versées depuis l'inscription (tous groupes confondus).
  double totalContribution = 0.0;

  /// Score de confiance (0 à 100) basé sur la ponctualité des paiements.
  /// Utilisé par l'IA prédictive pour évaluer les risques de défaut.
  int trustScore = 100;

  /// Statut actif/inactif du compte.
  @enumerated
  UserStatus status = UserStatus.active;

  // -------------------------------------------------------------------------
  // 🛡️ Gestion des rôles (Administrateur vs Membre)
  // -------------------------------------------------------------------------

  /// Rôle global de l'utilisateur dans l'application.
  /// - `member` : Peut uniquement rejoindre des groupes existants.
  /// - `admin` : Peut créer de nouveaux groupes et gérer ceux qu'il a créés.
  @enumerated
  UserRole role = UserRole.member;
}

/// Statuts possibles d'un compte utilisateur.
enum UserStatus {
  active,    // Compte actif, peut participer
  suspended, // Suspendu temporairement
  closed,    // Compte fermé définitivement
}

/// Rôles globaux de l'application.
enum UserRole {
  member, // Participant simple
  admin,  // Peut créer et gérer des groupes
}
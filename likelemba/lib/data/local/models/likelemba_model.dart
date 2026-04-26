// lib/data/local/models/likelemba_model.dart

import 'package:isar/isar.dart';

import 'user_model.dart';

part 'likelemba_model.g.dart';

/// 👥 Modèle de groupe Likelemba (tontine rotative).
///
/// Contient tous les paramètres de fonctionnement du cycle, y compris
/// les variables de l'Équation Différentielle Ordinaire (EDO) qui régissent
/// le fonds de réserve.
///
/// **Administrateur :** Un lien `adminLink` désigne le propriétaire du groupe.
/// Seul cet utilisateur peut modifier les paramètres ou valider des transactions.
@Collection()
class LikelembaModel {
  /// Identifiant unique du groupe.
  Id id = Isar.autoIncrement;

  /// Nom du groupe (ex: "Solidarité Kinshasa").
  late String groupName;

  /// Description optionnelle du groupe.
  String? description;

  /// Date de création du groupe.
  late DateTime createdAt;

  /// Date de début du cycle actuel.
  late DateTime cycleStartDate;

  /// Durée totale du cycle en jours ($T$).
  int cycleDurationDays = 30;

  // -------------------------------------------------------------------------
  // Paramètres financiers (EDO)
  // -------------------------------------------------------------------------

  /// Montant de la cotisation quotidienne par membre ($S$).
  double dailyContribution = 5000.0;

  /// Taux de prélèvement de sécurité ($a$) – pourcentage prélevé sur chaque cotisation
  /// pour alimenter le fonds de réserve. Exprimé en décimal (ex: 0.05 = 5%).
  double securityFeeRate = 0.05;

  /// Pénalité initiale ($\alpha_0$) – taux maximal de retenue en cas de départ anticipé.
  double basePenaltyRate = 0.20;

  /// Délai cible de régénération du fonds de réserve ($\Delta T_{max}$) en jours.
  int regenerationTargetDays = 3;

  /// Montant actuel du fonds de réserve ($F(t)$).
  double currentReserveFund = 0.0;

  // -------------------------------------------------------------------------
  // État du cycle
  // -------------------------------------------------------------------------

  /// Index (position) du bénéficiaire actuel dans la liste des membres.
  int currentBeneficiaryIndex = 0;

  /// Jours écoulés depuis le début du cycle.
  int get elapsedDays => DateTime.now().difference(cycleStartDate).inDays;

  /// Indique si le cycle est terminé.
  bool get isCycleCompleted => elapsedDays >= cycleDurationDays;

  /// Montant total de la cagnotte théorique (avant prélèvement de sécurité).
  double get grossJackpot {
  if (memberLinks.length <= 1) return 0.0;  // ← éviter le négatif
  return (memberLinks.length - 1) * dailyContribution;
}

  /// Montant net de la cagnotte perçue par le bénéficiaire.
  double get netJackpot => grossJackpot * (1 - securityFeeRate);

  // -------------------------------------------------------------------------
  // 🔒 Contrôle administrateur
  // -------------------------------------------------------------------------

  /// Lien vers l'utilisateur propriétaire du groupe (l'administrateur).
  final adminLink = IsarLink<UserModel>();

  /// Verrouillage des paramètres du groupe.
  /// Une fois le cycle démarré, l'admin peut verrouiller les paramètres
  /// pour garantir l'immutabilité des règles financières.
  bool isLocked = false;

  /// Date de verrouillage (si applicable).
  DateTime? lockedAt;


  String? remoteId;

  // -------------------------------------------------------------------------
  // Relations
  // -------------------------------------------------------------------------

  /// Liste des membres participants au groupe.
  /// `IsarLinks` gère la relation many-to-many avec `UserModel`.
  final memberLinks = IsarLinks<UserModel>();
}

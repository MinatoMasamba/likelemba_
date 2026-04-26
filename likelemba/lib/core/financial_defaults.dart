// lib/core/constants/financial_defaults.dart

/// 📊 Paramètres financiers fondamentaux du Likelemba Sécurisé.
///
/// Ce fichier centralise les constantes issues des modèles mathématiques
/// (Équations Différentielles Ordinaires) décrits dans la documentation technique.
/// Ces valeurs servent de référence par défaut et peuvent être ajustées
/// par l'administrateur lors de la création d'un groupe.
class FinancialDefaults {
  // -------------------------------------------------------------------------
  // 🧮 Cotisation de base (Membre individuel)
  // -------------------------------------------------------------------------

  /// Cotisation journalière de référence par membre.
  /// Exprimée en unité monétaire locale (Franc Congolais dans l'exemple).
  /// Valeur indicative issue de l'exemple Cadeco : 5 000 FC.
  static const double defaultDailyContribution = 5000.0;

  /// Durée standard d'un cycle de tontine (en jours).
  /// Un cycle correspond à un tour complet où chaque membre reçoit la cagnotte une fois.
  static const int defaultCycleDurationDays = 30;

  // -------------------------------------------------------------------------
  // 🛡️ Paramètres du Fonds de Réserve (Sécurisation)
  // -------------------------------------------------------------------------

  /// Taux de prélèvement de sécurité (a) appliqué à chaque cotisation quotidienne.
  ///
  /// Ce pourcentage est prélevé pour alimenter le fonds de réserve collectif,
  /// appelé "roue de secours". Il garantit la solvabilité en cas de départ anticipé.
  /// Référence PDF : "prélèvement journalier de sécurité par membre".
  static const double reserveContributionRate = 0.05; // 5%

  /// Seuil minimal recommandé pour le fonds de réserve (en % de la cagnotte totale).
  ///
  /// Permet d'alerter l'administrateur si le fonds descend en dessous
  /// d'un niveau critique pour absorber les chocs.
  static const double minReserveRatio = 0.10; // 10% de la cagnotte nominale

  // -------------------------------------------------------------------------
  // ⚖️ Pénalités de sortie (Modèle Dégressif Linéaire)
  // -------------------------------------------------------------------------

  /// Pénalité initiale (alpha_0) appliquée lors d'un départ au tout début du cycle.
  ///
  /// Représente la retenue maximale sur les cotisations versées par un membre sortant.
  /// La pénalité décroît linéairement avec le temps passé dans le groupe.
  /// Formule : alpha(tau) = alpha_0 * (1 - tau / T)
  static const double basePenaltyRate = 0.20; // 20%

  /// Facteur optionnel de décroissance non-linéaire (lambda).
  /// Actuellement non utilisé dans le modèle linéaire de base, mais réservé
  /// pour des extensions futures (pénalité exponentielle).
  static const double penaltyDecayFactor = 1.0; // Neutre par défaut

  // -------------------------------------------------------------------------
  // ⏱️ Résilience Temporelle (Optimisation EDO)
  // -------------------------------------------------------------------------

  /// Délai maximal de régénération du fonds de réserve après un départ (Delta t_max).
  ///
  /// Objectif de résilience : le système doit retrouver un solde positif ou
  /// un niveau de sécurité en moins de ce nombre de jours.
  /// Référence PDF : "moins de 3 jours".
  static const int regenerationTargetDays = 3;

  /// Tolérance acceptable en cas de léger déficit temporaire (marge de sécurité).
  static const double deficitTolerance = 0.001; // 0.1%

  // -------------------------------------------------------------------------
  // 📈 Calculs Dérivés (Utilitaires)
  // -------------------------------------------------------------------------

  /// Calcule le montant de la cagnotte nette perçue par un bénéficiaire.
  ///
  /// Formule : Cagnotte = (n - 1) * CotisationJournalière * (1 - TauxPrélèvement)
  /// où n est le nombre total de membres.
  static double computeNetJackpot({
    required int memberCount,
    required double dailyContribution,
    required double reserveRate,
  }) {
    if (memberCount <= 1) return 0.0;
    final gross = (memberCount - 1) * dailyContribution;
    final reserveAmount = gross * reserveRate;
    return gross - reserveAmount;
  }

  /// Calcule le montant quotidien versé au fonds de réserve par l'ensemble du groupe.
  static double computeDailyReserveInflow({
    required int memberCount,
    required double dailyContribution,
    required double reserveRate,
  }) {
    return memberCount * dailyContribution * reserveRate;
  }

  /// Calcule la pénalité dégressive théorique à un instant tau (en jours).
  ///
  /// Retourne un taux entre 0 et basePenaltyRate.
  static double computePenaltyRateAtDay({
    required int elapsedDays,
    required int totalCycleDays,
    required double basePenalty,
  }) {
    if (elapsedDays < 0) elapsedDays = 0;
    if (elapsedDays >= totalCycleDays) return 0.0;
    final factor = 1.0 - (elapsedDays / totalCycleDays);
    return basePenalty * factor;
  }

  /// Vérifie si le fonds de réserve actuel est considéré comme "sain"
  /// par rapport au seuil minimal recommandé.
  static bool isReserveHealthy({
    required double currentReserve,
    required double nominalJackpot,
    required double minRatio,
  }) {
    return currentReserve >= (nominalJackpot * minRatio);
  }
}
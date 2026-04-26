
// lib/core/constants/app_strings.dart

/// 🗣️ Ressources textuelles centralisées du projet Likelemba Sécurisé.
///
/// Tous les textes affichés dans l'interface utilisateur doivent être référencés ici.
/// Cela garantit :
/// - La cohérence terminologique (ex: "Fonds de réserve" et non "Caisse").
/// - La facilité d'internationalisation future (L10n).
/// - La maintenabilité et la réduction du "hardcoding".
class AppStrings {
  // -------------------------------------------------------------------------
  // 🌍 Global – Identité de l'application
  // -------------------------------------------------------------------------

  static const String appName = 'Likelemba Sécurisé';
  static const String appTagline = 'La solidarité renforcée par la science';
  static const String ok = 'OK';
  static const String cancel = 'Annuler';
  static const String confirm = 'Confirmer';
  static const String close = 'Fermer';
  static const String retry = 'Réessayer';
  static const String loading = 'Chargement...';
  static const String save = 'Enregistrer';
  static const String delete = 'Supprimer';
  static const String edit = 'Modifier';
  static const String back = 'Retour';
  static const String continueText = 'Continuer';
  static const String submit = 'Valider';

  // -------------------------------------------------------------------------
  // 🏠 Dashboard – Interface Participant
  // -------------------------------------------------------------------------

  static const String dashboardWelcome = 'Bonjour';
  static const String myPosition = 'Ma position';
  static const String currentBeneficiary = 'Bénéficiaire actuel';
  static const String nextBeneficiary = 'Prochain bénéficiaire';
  static const String totalPot = 'Montant de la Cagnotte';
  static const String myContributionStatus = 'Statut de ma cotisation';
  static const String contributionPaid = 'Cotisation versée';
  static const String contributionPending = 'En attente de paiement';
  static const String daysRemaining = 'Jours restants';
  static const String cycleProgress = 'Progression du cycle';
  static const String groupMembers = 'Membres du groupe';
  static const String member = 'Membre';
  static const String you = 'Vous';

  // -------------------------------------------------------------------------
  // 🛡️ Fonds de Réserve & Sécurité (Termes spécifiques Likelemba)
  // -------------------------------------------------------------------------

  static const String reserveFund = 'Bouclier de Sécurité';
  static const String reserveFundDescription = 'Fonds collectif pour absorber les départs imprévus';
  static const String reserveFundAmount = 'Montant disponible';
  static const String reserveFundHealth = 'Santé du fonds';
  static const String reserveHealthy = 'Solide';
  static const String reserveWarning = 'Surveillance';
  static const String reserveCritical = 'Critique';
  static const String reserveContributionLabel = 'Prélèvement de sécurité';
  static const String reserveRegenerationTime = 'Temps de régénération estimé';
  static const String reserveRegenerationUnit = 'jours';

  // -------------------------------------------------------------------------
  // 📉 Modélisation EDO & Risques Financiers
  // -------------------------------------------------------------------------

  static const String solvencyStatus = 'Statut de Solvabilité';
  static const String riskLevel = 'Niveau de risque';
  static const String riskLow = 'Faible';
  static const String riskMedium = 'Modéré';
  static const String riskHigh = 'Élevé';
  static const String stabilityWarning = 'Alerte : Stabilité du cycle compromise';
  static const String deficitAlert = 'Attention : Fonds de réserve insuffisant pour ce retrait';
  static const String regenerationPrediction = 'Le fonds sera reconstitué en';
  static const String financialProjection = 'Projection financière';
  static const String predictedShortfall = 'Déficit prévisionnel';

  // -------------------------------------------------------------------------
  // 🎯 Actions Principales (Boutons)
  // -------------------------------------------------------------------------

  static const String contribute = 'Verser ma cotisation';
  static const String contributeNow = 'Payer maintenant';
  static const String requestFunds = 'Demander la cagnotte';
  static const String requestFundsDisabled = 'Cagnotte non disponible';
  static const String requestFundsHint = 'Vous devez attendre votre tour';
  static const String viewHistory = 'Voir l\'historique';
  static const String simulateExit = 'Simuler une sortie';
  static const String joinGroup = 'Rejoindre un groupe';
  static const String createGroup = 'Créer un Likelemba';

  // -------------------------------------------------------------------------
  // 🚪 Gestion des départs (Exit)
  // -------------------------------------------------------------------------

  static const String exitTitle = 'Sortie du groupe';
  static const String exitConfirmation = 'Confirmer la sortie';
  static const String exitWarning = 'Vous allez quitter le Likelemba avant la fin du cycle.';
  static const String exitRefundDetails = 'Remboursement estimé de vos cotisations';
  static const String exitPenalty = 'Frais de sortie anticipée';
  static const String exitPenaltyExplanation = 'Ces frais compensent la perturbation du cycle et renforcent le fonds commun.';
  static const String exitLoyaltyReward = 'Bonus de fidélité (pénalité réduite)';
  static const String exitRemainingDays = 'Jours restants si vous restez';
  static const String exitProceed = 'Quitter définitivement';
  static const String exitSuccess = 'Votre sortie a été enregistrée. Merci pour votre participation.';
  static const String exitImpossible = 'Sortie impossible à ce stade du cycle.';

  // -------------------------------------------------------------------------
  // 👥 Admin – Poste de Commandement
  // -------------------------------------------------------------------------

  static const String adminDashboard = 'Supervision du Groupe';
  static const String adminMembersList = 'Liste des participants';
  static const String adminSegmentedView = 'Vue par statut';
  static const String adminContributors = 'Contributeurs';
  static const String adminLeavers = 'Sortants';
  static const String adminFutureCommitments = 'Engagements futurs';
  static const String adminNewAdditions = 'Nouveaux ajouts';
  static const String adminReplaceMember = 'Remplacer un membre';
  static const String adminDragDropHint = 'Glissez un candidat ici pour remplacer';
  static const String adminAnomalyDetection = 'Détection d\'anomalies';
  static const String adminForceSync = 'Forcer la synchronisation';
  static const String adminRecalculateEDO = 'Recalculer la solvabilité';

  // -------------------------------------------------------------------------
  // 🔄 Synchronisation & Mode Offline
  // -------------------------------------------------------------------------

  static const String syncPending = 'En attente de synchronisation';
  static const String syncInProgress = 'Synchronisation en cours...';
  static const String syncCompleted = 'Données à jour';
  static const String syncFailed = 'Échec de synchronisation';
  static const String offlineMode = 'Mode hors-ligne';
  static const String offlineDataSaved = 'Votre action a été enregistrée localement.';
  static const String syncRetryScheduled = 'Nouvelle tentative planifiée.';

  // -------------------------------------------------------------------------
  // 🔐 Authentification & Sécurité
  // -------------------------------------------------------------------------

  static const String login = 'Connexion';
  static const String logout = 'Déconnexion';
  static const String register = 'Créer un compte';
  static const String phoneNumber = 'Numéro de téléphone';
  static const String password = 'Mot de passe';
  static const String biometricSetup = 'Activer la connexion biométrique';
  static const String biometricAuthTitle = 'Vérification d\'identité';
  static const String biometricAuthReason = 'Authentifiez-vous pour accéder à votre Likelemba sécurisé';
  static const String useFingerprint = 'Utiliser l\'empreinte digitale';
  static const String useFaceId = 'Utiliser la reconnaissance faciale';

  // -------------------------------------------------------------------------
  // ⚠️ Messages d'erreur "Humains"
  // -------------------------------------------------------------------------

  static const String errorGeneric = 'Une erreur est survenue. Veuillez réessayer.';
  static const String errorNetwork = 'Problème de connexion. Vérifiez votre réseau.';
  static const String errorInsufficientFunds = 'Fonds insuffisants pour cette opération.';
  static const String errorNotYourTurn = 'Ce n\'est pas votre tour de recevoir la cagnotte.';
  static const String errorGroupFull = 'Ce groupe est complet.';
  static const String errorInvalidAmount = 'Montant invalide.';
  static const String errorReserveTooLow = 'Le fonds de réserve est trop bas pour autoriser cette sortie.';
  static const String errorAlreadyExited = 'Vous avez déjà quitté ce groupe.';
  static const String errorMemberNotFound = 'Membre introuvable.';
  static const String errorCalculation = 'Erreur dans le calcul financier. Contactez l\'administrateur.';

  // -------------------------------------------------------------------------
  // ♿ Accessibilité (Semantics / Labels pour lecteurs d'écran)
  // -------------------------------------------------------------------------

  static const String sematicBackButton = 'Bouton retour';
  static const String sematicMenuButton = 'Menu principal';
  static const String sematicReserveFundGauge = 'Jauge du fonds de réserve';
  static const String sematicQueuePosition = 'Position dans la file d\'attente';
  static const String sematicPaymentSuccess = 'Paiement réussi';
  static const String sematicPaymentFailed = 'Paiement échoué';
  static const String sematicHapticFeedback = 'Retour haptique activé';

  // -------------------------------------------------------------------------
  // 📅 Formats de dates & devises
  // -------------------------------------------------------------------------

  static String currency(double amount) => '${amount.toStringAsFixed(0)} FC';
  static String percentage(double value) => '${(value * 100).toStringAsFixed(1)}%';
  static String days(int count) => '$count jour${count > 1 ? 's' : ''}';
  static String queuePosition(int position, int total) => 'Position $position sur $total';
  static String regenerationTime(double days) => '${days.toStringAsFixed(1)} jour${days > 1 ? 's' : ''}';

  // -------------------------------------------------------------------------
  // 🧮 Formules mathématiques affichées (Explications simplifiées)
  // -------------------------------------------------------------------------

  static const String formulaPenaltyExplanation = 'La pénalité diminue avec votre ancienneté.';
  static const String formulaReserveExplanation = 'Le fonds se remplit chaque jour grâce à une petite part de chaque cotisation.';
  static const String formulaSolvabilityExplanation = 'Nous vérifions que la caisse peut absorber votre départ sans mettre le groupe en danger.';
}

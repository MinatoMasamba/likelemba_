// lib/core/utils/edo_solver.dart

/// 🧮 Résolution numérique de l'Équation Différentielle Ordinaire (EDO) du fonds de réserve.
///
/// Ce fichier contient des fonctions **pures** (sans dépendances Flutter ou base de données)
/// qui modélisent l'évolution du fonds de réserve `F(t)` selon l'équation :
///
///     dF/dt = n * a - λ * R(t)
///
/// où :
/// - `n` : nombre de membres actifs
/// - `a` : prélèvement de sécurité quotidien par membre
/// - `λ` : coefficient de risque de défaillance (optionnel)
/// - `R(t)` : fonction de remboursement en cas de sortie
///
/// La résolution utilise la méthode d'Euler (1er ordre) pour rester légère et compréhensible.
/// Pour une précision accrue, une méthode de Runge-Kutta d'ordre 4 peut être implémentée.
class EDOSolver {
  /// Résout l'EDO et retourne l'évolution du fonds sur une période donnée.
  ///
  /// [initialFund] : montant initial du fonds de réserve.
  /// [memberCount] : nombre de membres actifs (n).
  /// [dailySecurityFee] : prélèvement de sécurité quotidien par membre (a).
  /// [days] : durée de la simulation en jours.
  /// [exitEvents] : liste des jours où un départ survient, avec le montant remboursé.
  /// [step] : pas de temps en jours (par défaut 0.1 jour pour une bonne précision).
  ///
  /// Retourne une liste de `FundState` représentant l'état du fonds à chaque pas de temps.
  static List<FundState> simulate({
    required double initialFund,
    required int memberCount,
    required double dailySecurityFee,
    required int days,
    List<ExitEvent> exitEvents = const [],
    double step = 0.1,
  }) {
    final List<FundState> results = [];
    double currentFund = initialFund;
    double t = 0.0;

    // ✅ Créer une copie modifiable de la liste avant de trier
    // (car la liste peut être une constante non modifiable)
    final mutableEvents = List<ExitEvent>.from(exitEvents);
    mutableEvents.sort((a, b) => a.day.compareTo(b.day));

    while (t <= days) {
      // Enregistre l'état actuel
      results.add(FundState(day: t, fund: currentFund));

      // Vérifie si un départ survient à ce pas de temps
      // ✅ Utilise mutableEvents au lieu de exitEvents
      final eventsToday = mutableEvents.where((e) => (e.day - t).abs() < step / 2).toList();
      for (final event in eventsToday) {
        currentFund -= event.refundAmount;
      }

      // Calcule la variation du fonds (dF/dt) sur ce pas
      // Ici, on suppose λ = 0 (pas de risque continu) pour simplifier
      final dFdt = memberCount * dailySecurityFee;
      currentFund += dFdt * step;

      t += step;
    }

    return results;
  }

  /// Évalue le niveau de risque du fonds de réserve à un instant donné.
  ///
  /// [currentFund] : montant actuel du fonds.
  /// [totalJackpot] : montant total de la cagnotte à distribuer.
  /// Retourne un enum `RiskLevel` (Low, Medium, High).
  static RiskLevel evaluateRisk({
    required double currentFund,
    required double totalJackpot,
  }) {
    if (totalJackpot <= 0) return RiskLevel.low; // ✅ Éviter la division par zéro
    final ratio = currentFund / totalJackpot;
    if (ratio >= 0.2) {
      return RiskLevel.low;
    } else if (ratio >= 0.1) {
      return RiskLevel.medium;
    } else {
      return RiskLevel.high;
    }
  }

  /// Prédit le temps nécessaire pour que le fonds atteigne un seuil cible.
  ///
  /// [currentFund] : montant actuel.
  /// [targetFund] : montant souhaité.
  /// [memberCount] : nombre de membres actifs.
  /// [dailySecurityFee] : prélèvement quotidien par membre.
  ///
  /// Retourne le nombre de jours estimé. Si le fonds décroît, retourne `double.infinity`.
  static double estimateRegenerationDays({
    required double currentFund,
    required double targetFund,
    required int memberCount,
    required double dailySecurityFee,
  }) {
    final dailyInflow = memberCount * dailySecurityFee;
    if (dailyInflow <= 0) return double.infinity;
    final needed = targetFund - currentFund;
    if (needed <= 0) return 0.0;
    return needed / dailyInflow;
  }
}

/// 📦 État du fonds à un instant `t`.
class FundState {
  final double day;
  final double fund;

  FundState({required this.day, required this.fund});

  @override
  String toString() => 'Jour ${day.toStringAsFixed(1)} : ${fund.toStringAsFixed(2)} FC';
}

/// 🚪 Événement de départ (ponction sur le fonds).
class ExitEvent {
  final int day;
  final double refundAmount;

  ExitEvent({required this.day, required this.refundAmount});
}

/// 🚦 Niveaux de risque pour l'interface utilisateur.
enum RiskLevel {
  low,   // Vert
  medium,// Orange
  high   // Rouge
}
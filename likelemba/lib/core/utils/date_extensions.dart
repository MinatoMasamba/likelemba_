// lib/core/utils/date_extensions.dart

/// 📅 Extensions Dart sur `DateTime` pour faciliter la gestion des cycles de tontine.
///
/// Ces méthodes métier sont pures et ne dépendent pas de Flutter.
extension LikelembaDateExtensions on DateTime {
  /// Nombre de jours entre cette date et [other].
  /// Retourne un entier positif (différence absolue en jours).
  int daysDifference(DateTime other) {
    final thisDate = DateTime(year, month, day);
    final otherDate = DateTime(other.year, other.month, other.day);
    return (thisDate.difference(otherDate).inDays).abs();
  }

  /// Indique si la date actuelle est dans le même cycle que [cycleStartDate]
  /// pour une durée de cycle donnée [cycleDurationDays].
  bool isInSameCycle(DateTime cycleStartDate, int cycleDurationDays) {
    final daysSinceStart = daysDifference(cycleStartDate);
    return daysSinceStart < cycleDurationDays;
  }

  /// Progression dans le cycle en pourcentage (0.0 à 1.0).
  double cycleProgress(DateTime cycleStartDate, int cycleDurationDays) {
    final daysElapsed = daysDifference(cycleStartDate);
    if (daysElapsed >= cycleDurationDays) return 1.0;
    return daysElapsed / cycleDurationDays;
  }

  /// Jours restants avant la fin du cycle.
  int daysRemainingInCycle(DateTime cycleStartDate, int cycleDurationDays) {
    final daysElapsed = daysDifference(cycleStartDate);
    final remaining = cycleDurationDays - daysElapsed;
    return remaining > 0 ? remaining : 0;
  }

  /// Vérifie si la date est un jour de paiement (par exemple tous les jours).
  /// Pour le Likelemba, on peut définir des règles spécifiques (ex: jours ouvrés).
  bool get isContributionDay {
    // Par défaut, tous les jours sont des jours de cotisation.
    // On pourrait exclure les dimanches ou jours fériés ici.
    return true;
  }

  /// Retourne une nouvelle date à minuit (début de journée).
  DateTime get startOfDay => DateTime(year, month, day);

  /// Retourne une nouvelle date à 23:59:59.999 (fin de journée).
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);
}
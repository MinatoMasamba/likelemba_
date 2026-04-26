// lib/core/utils/penalty_calculator.dart

import 'dart:math';

import 'package:likelemba/core/financial_defaults.dart';



/// ⚖️ Calculateur de pénalité dégressive pour sortie anticipée du Likelemba.
///
/// La formule de pénalité est donnée par :
///
///     α(τ) = α₀ * (1 - τ / T)    (décroissance linéaire)
///
/// ou, pour une décroissance exponentielle :
///
///     α(τ) = α₀ * e^(-λ * τ)
///
/// où :
/// - `α₀` : pénalité initiale (basePenaltyRate)
/// - `τ`   : nombre de jours écoulés depuis le début du cycle
/// - `T`   : durée totale du cycle en jours
/// - `λ`   : facteur d'amortissement (penaltyDecayFactor)
///
/// Tous les calculs sont arrondis à 2 décimales pour éviter les erreurs de virgule flottante.
class PenaltyCalculator {
  /// Calcule le taux de pénalité à appliquer au jour `elapsedDays`.
  ///
  /// [elapsedDays] : jours écoulés depuis le début du cycle.
  /// [totalCycleDays] : durée totale du cycle (T).
  /// [basePenalty] : pénalité initiale (α₀), par défaut `FinancialDefaults.basePenaltyRate`.
  /// [useExponential] : si `true`, utilise la décroissance exponentielle.
  /// [lambda] : facteur de décroissance exponentielle, par défaut `FinancialDefaults.penaltyDecayFactor`.
  ///
  /// Retourne un taux entre 0.0 et `basePenalty`.
  static double calculatePenaltyRate({
    required int elapsedDays,
    required int totalCycleDays,
    double basePenalty = FinancialDefaults.basePenaltyRate,
    bool useExponential = false,
    double lambda = FinancialDefaults.penaltyDecayFactor,
  }) {
    // Protection contre les entrées invalides
    if (elapsedDays < 0) elapsedDays = 0;
    if (elapsedDays >= totalCycleDays) return 0.0;

    double rate;
    if (useExponential) {
      // Décroissance exponentielle : α(τ) = α₀ * e^(-λ * τ)
      rate = basePenalty * exp(-lambda * elapsedDays);
    } else {
      // Décroissance linéaire (par défaut) : α(τ) = α₀ * (1 - τ/T)
      final factor = 1.0 - (elapsedDays / totalCycleDays);
      rate = basePenalty * factor;
    }

    // Arrondi à 4 décimales (0.0001 = 0.01%) pour éviter les problèmes de précision
    return (rate * 10000).round() / 10000;
  }

  /// Calcule le montant du remboursement pour un membre qui quitte le groupe.
  ///
  /// [totalContributed] : somme totale cotisée par le membre jusqu'à présent.
  /// [elapsedDays] : jours écoulés depuis le début du cycle.
  /// [totalCycleDays] : durée totale du cycle.
  /// [basePenalty] : pénalité initiale (α₀).
  /// [useExponential] : type de décroissance.
  /// [lambda] : facteur exponentiel.
  ///
  /// Retourne le montant à rembourser (après application de la pénalité).
  static double calculateRefund({
    required double totalContributed,
    required int elapsedDays,
    required int totalCycleDays,
    double basePenalty = FinancialDefaults.basePenaltyRate,
    bool useExponential = false,
    double lambda = FinancialDefaults.penaltyDecayFactor,
  }) {
    final penaltyRate = calculatePenaltyRate(
      elapsedDays: elapsedDays,
      totalCycleDays: totalCycleDays,
      basePenalty: basePenalty,
      useExponential: useExponential,
      lambda: lambda,
    );

    final penaltyAmount = totalContributed * penaltyRate;
    final refund = totalContributed - penaltyAmount;

    // Arrondi à 2 décimales (centimes)
    return (refund * 100).round() / 100.0;
  }

  /// Calcule le montant de la pénalité seule (pour affichage).
  static double calculatePenaltyAmount({
    required double totalContributed,
    required int elapsedDays,
    required int totalCycleDays,
    double basePenalty = FinancialDefaults.basePenaltyRate,
    bool useExponential = false,
    double lambda = FinancialDefaults.penaltyDecayFactor,
  }) {
    final penaltyRate = calculatePenaltyRate(
      elapsedDays: elapsedDays,
      totalCycleDays: totalCycleDays,
      basePenalty: basePenalty,
      useExponential: useExponential,
      lambda: lambda,
    );
    final amount = totalContributed * penaltyRate;
    return (amount * 100).round() / 100.0;
  }
}
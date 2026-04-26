// lib/core/utils/money_formatter.dart

import 'package:intl/intl.dart';

/// 💵 Formatage monétaire et conversion de devises (CDF / USD).
///
/// **IMPORTANT – Architecture :**
/// Ce fichier fait partie de la couche `core/utils`. Il doit rester **pur** :
/// - Aucun appel réseau (pas de `http.get` pour récupérer le taux de change).
/// - Aucune dépendance à Flutter (`dart:ui`, `BuildContext`).
/// - Toutes les méthodes sont synchrones.
///
/// Le taux de change (`exchangeRate`) doit être fourni par la couche `data` (via un
/// `ExchangeRateRepository`) et injecté dans l'UI par un `StateProvider` Riverpod.
class MoneyFormatter {
  // -------------------------------------------------------------------------
  // 📛 Symboles monétaires
  // -------------------------------------------------------------------------
  static const String symbolCDF = 'FC';
  static const String symbolUSD = '\$';

  // -------------------------------------------------------------------------
  // 🇨🇩 Formatage Franc Congolais (CDF)
  // -------------------------------------------------------------------------

  /// Formate un montant en Francs Congolais (FC) avec séparateur de milliers.
  ///
  /// Exemple : `12500` -> `"12 500 FC"`
  static String formatCDF(double amount) {
    final formatter = NumberFormat('#,##0', 'fr');
    return '${formatter.format(amount)} $symbolCDF';
  }

  // -------------------------------------------------------------------------
  // 🇺🇸 Formatage Dollar Américain (USD)
  // -------------------------------------------------------------------------

  /// Formate un montant en Dollars américains (USD) avec 2 décimales.
  ///
  /// Exemple : `50.5` -> `"$50.50"`
  static String formatUSD(double amount) {
    final formatter = NumberFormat('#,##0.00', 'en_US');
    return '$symbolUSD${formatter.format(amount)}';
  }

  // -------------------------------------------------------------------------
  // 🔁 Formatage générique selon devise
  // -------------------------------------------------------------------------

  /// Formate un montant dans la devise spécifiée.
  static String format(double amount, AppCurrency currency) {
    switch (currency) {
      case AppCurrency.cdf:
        return formatCDF(amount);
      case AppCurrency.usd:
        return formatUSD(amount);
    }
  }

  // -------------------------------------------------------------------------
  // 📈 Formatage des pourcentages
  // -------------------------------------------------------------------------

  /// Formate un taux (0.0 à 1.0) en pourcentage avec le nombre de décimales souhaité.
  ///
  /// Exemple : `0.0523` -> `"5,2 %"`
  static String formatPercentage(double rate, {int decimalDigits = 1}) {
    final formatter = NumberFormat.decimalPattern('fr');
    formatter.minimumFractionDigits = decimalDigits;
    formatter.maximumFractionDigits = decimalDigits;
    final percentValue = rate * 100;
    return '${formatter.format(percentValue)} %';
  }

  // -------------------------------------------------------------------------
  // 💱 Conversion de devises (pure, basée sur un taux fourni)
  // -------------------------------------------------------------------------

  /// Convertit un montant d'une devise à une autre.
  ///
  /// [amount] : montant à convertir.
  /// [from]   : devise source.
  /// [to]     : devise cible.
  /// [exchangeRate] : taux de change (1 USD = X CDF).
  ///                  Ce taux DOIT être récupéré au préalable via une API
  ///                  et stocké dans l'état de l'application (Riverpod).
  ///
  /// Retourne le montant converti. Si les devises sont identiques ou si le taux
  /// est invalide (<=0), retourne le montant original.
  static double convert(
    double amount, {
    required AppCurrency from,
    required AppCurrency to,
    required double exchangeRate,
  }) {
    if (from == to) return amount;
    if (exchangeRate <= 0.0) return amount; // Évite les divisions par zéro

    if (from == AppCurrency.usd && to == AppCurrency.cdf) {
      return amount * exchangeRate;
    } else {
      // Conversion inverse : CDF -> USD
      return amount / exchangeRate;
    }
  }

  // -------------------------------------------------------------------------
  // 🔍 Parsing de chaînes monétaires
  // -------------------------------------------------------------------------

  /// Parse une chaîne formatée (ex: "12 500 FC" ou "12 500") en `double`.
  ///
  /// Gère les espaces et les virgules décimales.
  static double parseCDF(String input) {
    String cleaned = input.replaceAll(symbolCDF, '').trim();
    cleaned = cleaned.replaceAll(' ', '').replaceAll('\u00A0', '');
    cleaned = cleaned.replaceAll(',', '.');
    return double.tryParse(cleaned) ?? 0.0;
  }

  /// Parse une chaîne formatée USD (ex: "$50.99") en `double`.
  static double parseUSD(String input) {
    String cleaned = input.replaceAll(symbolUSD, '').trim();
    cleaned = cleaned.replaceAll(',', ''); // Supprime les séparateurs de milliers
    return double.tryParse(cleaned) ?? 0.0;
  }
}

/// 🌍 Devises supportées par l'application.
enum AppCurrency {
  cdf, // Franc Congolais
  usd  // Dollar Américain
}
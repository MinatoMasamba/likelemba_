// lib/core/constants/app_colors.dart

import 'dart:ui';
import 'package:flutter/material.dart';

/// 🧊 Palette du système de design "Liquid Glass 2026" pour le projet Likelemba Sécurisé.
///
/// Cette palette est optimisée pour :
/// - L'effet de verre dépoli (backdrop-filter) avec des opacités précises.
/// - La lisibilité en mode contraste élevé (accessibilité).
/// - La visualisation des états financiers critiques (solvabilité, risque).
class AppColors {
  // -------------------------------------------------------------------------
  // 🌊 Identité de Marque – Likelemba Sécurisé
  // -------------------------------------------------------------------------

  /// Couleur primaire : Bleu profond "Électrique" évoquant la confiance et la fluidité financière.
  static const Color primaryDeepBlue = Color(0xFF0A2540); // Fond sombre pour contraste élevé

  /// Accent Turquoise / Cyan pour les actions principales et la progression.
  static const Color accentTeal = Color(0xFF00C9A7);

  /// Or "Solidarité" utilisé pour les cagnottes et les montants positifs.
  static const Color solidarityGold = Color(0xFFFFB800);

  // -------------------------------------------------------------------------
  // 🥂 Effet "Liquid Glass" – Couches de transparence
  // -------------------------------------------------------------------------

  /// Fond blanc pour l'effet verre. Opacité variable selon le contexte.
  static const Color glassBase = Color(0xFFFFFFFF);

  /// Opacité standard pour une carte en verre (10%).
  static const Color glassCardFill = Color(0x1AFFFFFF); // 0x1A = 10%

  /// Opacité plus dense pour les surfaces de navigation (25%).
  static const Color glassNavFill = Color(0x40FFFFFF); // 0x40 = 25%

  /// Opacité très légère pour les bordures (10% blanc).
  static const Color glassStroke = Color(0x1AFFFFFF);

  /// Ombre spécifique pour donner de la profondeur au verre.
  static Color glassShadow = Colors.black.withOpacity(0.15);

  // -------------------------------------------------------------------------
  // 📈 Statuts Financiers (Basés sur les Équations Différentielles - EDO)
  // -------------------------------------------------------------------------

  /// Solvabilité / Fonds de réserve sain. Vert émeraude.
  static const Color solvencyGreen = Color(0xFF00A86B);

  /// Alerte de risque modéré (Pénalité dégressive, délai de reconstitution).
  static const Color warningAmber = Color(0xFFFF9F1C);

  /// Alerte de risque élevé (Défaut, Fonds négatif). Rouge intense.
  static const Color riskRed = Color(0xFFE63946);

  /// Couleur dédiée au "Fonds de Réserve / Roue de Secours" pour le différencier.
  static const Color reserveFundCyan = Color(0xFF00B4D8);

  // -------------------------------------------------------------------------
  // 📝 Typographie & Accessibilité (Contraste Élevé)
  // -------------------------------------------------------------------------

  /// Texte principal sur fond verre clair (Doit être très foncé pour lisibilité).
  static const Color textPrimaryOnGlass = Color(0xFF1A1C20);

  /// Texte secondaire (moins d'emphase).
  static const Color textSecondaryOnGlass = Color(0xFF5E636B);

  /// Texte sur fond sombre (Ex: AppBar, Admin Dashboard).
  static const Color textOnDark = Color(0xFFFFFFFF);

  /// Texte désactivé / Placeholder.
  static const Color textDisabled = Color(0xFF9DA3AC);

  // -------------------------------------------------------------------------
  // ♿ Mode Contraste Élevé (Accessibilité – Page 11 du doc technique)
  // -------------------------------------------------------------------------

  /// Fond opaque remplaçant l'effet verre flou en mode contraste élevé.
  static const Color highContrastBackground = Color(0xFF121212); // Noir profond

  /// Surface secondaire pour le mode contraste élevé.
  static const Color highContrastSurface = Color(0xFF1E1E1E);

  /// Texte très lumineux pour le mode contraste élevé.
  static const Color highContrastText = Color(0xFFFFFFFF);

  /// Bordures bien visibles pour le mode contraste élevé.
  static const Color highContrastBorder = Color(0xFFB0B0B0);

  // -------------------------------------------------------------------------
  // 🎨 Gradients "Liquid Glass" Réutilisables
  // -------------------------------------------------------------------------

  /// Dégradé de fond pour les en-têtes (Liquid Glass Premium).
  static const LinearGradient glassHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x33FFFFFF), // 20% blanc
      Color(0x0DFFFFFF), // 5% blanc
    ],
    stops: [0.0, 1.0],
  );

  /// Dégradé de fond pour les cartes importantes (solde, cagnotte).
  static const LinearGradient glassCardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x26FFFFFF), // 15%
      Color(0x0DFFFFFF), // 5%
    ],
  );

  /// Dégradé pour le bouton d'action principal (CTA).
  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      accentTeal,
      solidarityGold,
    ],
  );

  /// Dégradé pour le fond de l'Admin Dashboard (Poste de Commandement).
  static const LinearGradient adminDashboardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      primaryDeepBlue,
      Color(0xFF001220), // Très foncé pour la profondeur
    ],
  );

  // Méthode utilitaire pour obtenir une couleur de fond verre adaptative
  static Color adaptiveGlassBackground(BuildContext context, {double opacity = 0.1}) {
    final brightness = Theme.of(context).brightness;
    if (brightness == Brightness.dark) {
      // En mode sombre, le verre est une couche sombre subtile
      return Colors.black.withOpacity(opacity * 2); 
    } else {
      // En mode clair, on garde ta base blanche originale
      return AppColors.glassBase.withOpacity(opacity);
    }
  }
}
// lib/core/theme/text_styles.dart

import 'package:flutter/material.dart';
import 'package:likelemba/core/app_colors.dart';


/// 📝 Styles de texte optimisés pour la lisibilité sur fond "Liquid Glass".
///
/// Chaque méthode prend un paramètre `isDark` pour s'adapter au thème
/// (mode clair ou sombre). Les ombres portées garantissent le contraste
/// même sur fond flouté.
class AppTextStyles {

  // ──────────────────────────────────────────────
  // 🏷️ Titres & En-têtes
  // ──────────────────────────────────────────────
  static TextStyle appBarTitle({required bool isDark}) => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textOnDark : AppColors.textPrimaryOnGlass,
        shadows: _textShadow,
        letterSpacing: -0.5,
      );

  static TextStyle sectionTitle({required bool isDark}) => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textOnDark : AppColors.textPrimaryOnGlass,
        shadows: _textShadow,
      );

  static TextStyle cardTitle({required bool isDark}) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textOnDark : AppColors.textPrimaryOnGlass,
        shadows: _textShadow,
      );

  // ──────────────────────────────────────────────
  // 💰 Montants financiers (Accentués)
  // ──────────────────────────────────────────────
  static TextStyle moneyLarge({bool isDark = true}) => TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: AppColors.solidarityGold,
        shadows: _textShadow,
        letterSpacing: -1.0,
      );

  static TextStyle moneyMedium({bool isDark = true}) => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.solidarityGold,
        shadows: _textShadow,
      );

  static TextStyle moneySmall({bool isDark = true}) => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.solidarityGold,
        shadows: _textShadow,
      );

  // ──────────────────────────────────────────────
  // 📊 Valeurs et statuts (Solvabilité, Risque)
  // ──────────────────────────────────────────────
  static TextStyle statusSolvent({bool isDark = true}) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.solvencyGreen,
        shadows: _textShadow,
      );

  static TextStyle statusWarning({bool isDark = true}) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.warningAmber,
        shadows: _textShadow,
      );

  static TextStyle statusRisk({bool isDark = true}) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.riskRed,
        shadows: _textShadow,
      );

  // ──────────────────────────────────────────────
  // 📄 Corps de texte & labels
  // ──────────────────────────────────────────────
  static TextStyle bodyLarge({required bool isDark}) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: isDark ? AppColors.textOnDark : AppColors.textPrimaryOnGlass,
        shadows: _textShadow,
      );

  static TextStyle bodyMedium({required bool isDark}) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: isDark
            ? AppColors.textOnDark.withOpacity(0.8)
            : AppColors.textSecondaryOnGlass,
        shadows: _textShadow,
      );

  static TextStyle bodySmall({required bool isDark}) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: isDark
            ? AppColors.textOnDark.withOpacity(0.7)
            : AppColors.textSecondaryOnGlass,
        shadows: _textShadow,
      );

  static TextStyle inputLabel({required bool isDark}) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.textOnDark : AppColors.textSecondaryOnGlass,
      );

  static TextStyle inputHint({required bool isDark}) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textDisabled,
      );

  static TextStyle buttonLabel({bool isDark = true}) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textOnDark,
        letterSpacing: 0.5,
      );

  // ──────────────────────────────────────────────
  // ♿ Mode Contraste Élevé – Styles alternatifs
  // ──────────────────────────────────────────────
  static TextStyle highContrastBody({bool isDark = true}) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.highContrastText,
      );

  static TextStyle highContrastTitle({bool isDark = true}) => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.highContrastText,
      );

  static TextStyle highContrastMoney({bool isDark = true}) => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: AppColors.solidarityGold,
      );

  // Ombre portée standard pour améliorer la lisibilité sur fond flou.
  static const List<Shadow> _textShadow = [
    Shadow(
      offset: Offset(0, 2),
      blurRadius: 8,
      color: Color(0x40000000),
    ),
    Shadow(
      offset: Offset(0, 1),
      blurRadius: 2,
      color: Color(0x80000000),
    ),
  ];
}
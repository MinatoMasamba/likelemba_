// lib/core/theme/liquid_glass_theme.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likelemba/core/app_colors.dart';

import 'text_styles.dart';

/// 🧊 Thème global "Liquid Glass 2026" pour le projet Likelemba Sécurisé.
class LiquidGlassTheme {

  /// Construit un thème selon la luminosité [brightness].
  static ThemeData _build(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? AppColors.primaryDeepBlue : Colors.white,

      // 🌊 AppBar transparente
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        titleTextStyle: AppTextStyles.appBarTitle(isDark: isDark),
        iconTheme: IconThemeData(color: isDark ? Colors.white : AppColors.primaryDeepBlue),
      ),

      // 🥂 Cartes en verre
      cardTheme: CardThemeData(
        color: isDark ? AppColors.glassCardFill : Colors.white.withOpacity(0.9),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.glassStroke, width: 1.0),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // 🔘 Boutons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: AppTextStyles.buttonLabel(isDark: isDark),
          backgroundColor: AppColors.accentTeal,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),

      // 🧾 Champs de saisie
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: AppTextStyles.inputLabel(isDark: isDark),
        hintStyle: AppTextStyles.inputHint(isDark: isDark),
        filled: true,
        fillColor: isDark ? AppColors.glassCardFill : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.glassStroke),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.glassStroke),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accentTeal, width: 2),
        ),
      ),
    );
  }

  /// Thème clair.
  static ThemeData get lightTheme => _build(Brightness.light);

  /// Thème sombre.
  static ThemeData get darkTheme => _build(Brightness.dark);
}
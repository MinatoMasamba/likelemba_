// lib/presentation/shared/widgets/liquid_glass_card.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:likelemba/core/app_colors.dart';


/// 🧊 Carte en verre liquide – Conteneur universel pour l'interface Likelemba.
///
/// Utilise un `BackdropFilter` pour créer l'effet de flou "Liquid Glass".
/// Inclut un mode contraste élevé pour l'accessibilité.
class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final double blurSigma;
  final double opacity;
  final double borderOpacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool highContrast;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.blurSigma = 15.0,
    this.opacity = 0.1,
    this.borderOpacity = 0.2,
    this.borderRadius,
    this.padding,
    this.highContrast = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(24);

    // Mode accessibilité : fond opaque sans flou
    if (highContrast) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.highContrastSurface,
          borderRadius: radius,
          border: Border.all(color: AppColors.highContrastBorder, width: 2),
        ),
        padding: padding,
        child: child,
      );
    }

    // Mode Liquid Glass
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(opacity),
                Colors.white.withOpacity(opacity * 0.5),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(borderOpacity),
              width: 1.5,
            ),
            borderRadius: radius,
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
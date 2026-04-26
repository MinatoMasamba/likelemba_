// lib/core/theme/glass_backdrop_scope.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likelemba/core/app_colors.dart';



/// 🎛️ Gestionnaire de flou partagé pour l'effet "Liquid Glass".
///
/// **Problème :** Chaque `BackdropFilter` capture l'arrière-plan et applique un flou,
/// ce qui est très coûteux en performances (GPU). Si plusieurs widgets empilent
/// leurs propres filtres, l'application peut ralentir.
///
/// **Solution :** `GlassBackdropScope` est un `InheritedWidget` qui fournit un
/// filtre de flou unique (ou une configuration) à tous ses descendants.
/// Les widgets enfants peuvent utiliser `GlassBackdropScope.of(context)`
/// pour récupérer les paramètres de flou et éviter les captures redondantes.
class GlassBackdropScope extends InheritedWidget {
  /// Intensité du flou (sigma X et Y).
  final double blurSigma;

  /// Active ou désactive l'effet de verre (pour le mode contraste élevé).
  final bool isGlassEnabled;

  /// Couleur de remplacement lorsque le verre est désactivé.
  final Color fallbackColor;

  const GlassBackdropScope({
    super.key,
    required this.blurSigma,
    required this.isGlassEnabled,
    required this.fallbackColor,
    required super.child,
  });

  /// Récupère la configuration de verre la plus proche dans l'arbre.
  static GlassBackdropScopeData of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<GlassBackdropScope>();
    if (scope == null) {
      // Valeurs par défaut si aucun scope n'est défini (mode verre activé, flou moyen)
      return const GlassBackdropScopeData(
        blurSigma: 15.0,
        isGlassEnabled: true,
        fallbackColor: AppColors.highContrastSurface,
      );
    }
    return GlassBackdropScopeData(
      blurSigma: scope.blurSigma,
      isGlassEnabled: scope.isGlassEnabled,
      fallbackColor: scope.fallbackColor,
    );
  }

  @override
  bool updateShouldNotify(GlassBackdropScope oldWidget) {
    return blurSigma != oldWidget.blurSigma ||
        isGlassEnabled != oldWidget.isGlassEnabled ||
        fallbackColor != oldWidget.fallbackColor;
  }
}

/// Conteneur de données immuable retourné par `GlassBackdropScope.of()`.
class GlassBackdropScopeData {
  final double blurSigma;
  final bool isGlassEnabled;
  final Color fallbackColor;

  const GlassBackdropScopeData({
    required this.blurSigma,
    required this.isGlassEnabled,
    required this.fallbackColor,
  });
}

/// 🧩 Widget utilitaire pour appliquer le verre selon la configuration du Scope.
///
/// Utilisation recommandée :
/// ```dart
/// GlassContainer(
///   child: Text('Mon contenu'),
/// )
/// ```
class GlassContainer extends ConsumerWidget {
  final Widget child;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? customBlurSigma;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius,
    this.padding,
    this.customBlurSigma,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = GlassBackdropScope.of(context);
    final sigma = customBlurSigma ?? scope.blurSigma;

    // Mode contraste élevé : pas de flou, fond opaque
    if (!scope.isGlassEnabled) {
      return Container(
        decoration: BoxDecoration(
          color: scope.fallbackColor,
          borderRadius: borderRadius ?? BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.highContrastBorder,
            width: 1.5,
          ),
        ),
        padding: padding,
        child: child,
      );
    }

    // Mode Liquid Glass : flou + transparence
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.glassCardFill,
            borderRadius: borderRadius ?? BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.glassStroke,
              width: 1.0,
            ),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

/// 🏁 Racine de l'application qui enveloppe tout avec un GlassBackdropScope.
///
/// À placer au niveau du `MaterialApp` ou du `Scaffold` principal.
class GlassThemeWrapper extends StatelessWidget {
  final Widget child;
  final bool isGlassEnabled;
  final double blurSigma;

  const GlassThemeWrapper({
    super.key,
    required this.child,
    this.isGlassEnabled = true,
    this.blurSigma = 15.0,
  });

  @override
  Widget build(BuildContext context) {
    return GlassBackdropScope(
      blurSigma: blurSigma,
      isGlassEnabled: isGlassEnabled,
      fallbackColor: AppColors.highContrastBackground,
      child: child,
    );
  }
}
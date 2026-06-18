// lib/presentation/features/tontine/widgets/solvency_shield_widget.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import '../../../../core/utils/money_formatter.dart';

/// 🛡️ Widget Bouclier de Solvabilité – Indicateur visuel de la santé du fonds de réserve.
///
/// Affiche un ratio de solvabilité (issu des calculs EDO) avec un design "Liquid Glass".
/// Respecte les contraintes d'accessibilité non-chromatique (icônes + haptique).
class SolvencyShieldWidget extends StatefulWidget {
  /// Ratio de solvabilité (entre 0.0 et 1.0).
  final double solvencyRatio;

  /// Montant actuel du fonds de réserve.
  final double currentReserveFund;

  /// Montant cible (seuil de sécurité, ex: cagnotte nette).
  final double targetReserveFund;

  /// Callback appelé lors du tap sur le bouclier.
  final VoidCallback? onTap;

  const SolvencyShieldWidget({
    super.key,
    required this.solvencyRatio,
    required this.currentReserveFund,
    required this.targetReserveFund,
    this.onTap,
  });

  @override
  State<SolvencyShieldWidget> createState() => _SolvencyShieldWidgetState();
}

class _SolvencyShieldWidgetState extends State<SolvencyShieldWidget> {
  static const String tag = 'SolvencyShieldWidget';
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _logger.d('$tag.initState - Widget créé avec ratio=${widget.solvencyRatio}');
  }

  void _handleTap() {
    const method = '_handleTap';
    _logger.i('$tag.$method - Bouclier tapé. Ratio=${widget.solvencyRatio}');

    // Retour haptique différencié selon le niveau de risque
    if (widget.solvencyRatio >= 0.7) {
      HapticFeedback.lightImpact();
    } else if (widget.solvencyRatio >= 0.4) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }

    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    // Validation des entrées (gestion d'erreur silencieuse)
    final ratio = widget.solvencyRatio.clamp(0.0, 1.0);
    final isStable = ratio >= 0.7;
    final isWarning = ratio >= 0.4 && ratio < 0.7;
    final isCritical = ratio < 0.4;

    // Couleurs et icônes non-chromatiques (accessibilité)
    final Color shieldColor = isStable
        ? Colors.greenAccent
        : isWarning
            ? Colors.orangeAccent
            : Colors.redAccent;
    final IconData shieldIcon = isStable
        ? Icons.shield_rounded
        : isWarning
            ? Icons.warning_amber_rounded
            : Icons.error_outline_rounded;
    final String statusText = isStable
        ? 'Système Stable'
        : isWarning
            ? 'Vigilance Recommandée'
            : 'Risque Critique';

    return GestureDetector(
      onTap: _handleTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: shieldColor.withOpacity(0.08),
              border: Border.all(
                color: shieldColor.withOpacity(0.35),
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: shieldColor.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                // Icône de statut
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: shieldColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(shieldIcon, color: shieldColor, size: 32),
                ),
                const SizedBox(width: 16),
                // Informations textuelles
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          color: shieldColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Barre de progression du ratio
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: ratio,
                          backgroundColor: Colors.white10,
                          color: shieldColor,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Détails du fonds
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Fonds actuel',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              MoneyFormatter.formatCDF(widget.currentReserveFund),
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Objectif sécurité',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              MoneyFormatter.formatCDF(widget.targetReserveFund),
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
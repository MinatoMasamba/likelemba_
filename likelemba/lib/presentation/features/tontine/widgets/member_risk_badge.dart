// lib/presentation/features/tontine/widgets/member_risk_badge.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

/// 🏷️ Badge de risque de membre – Visualise le score de confiance (IA).
///
/// Utilise des icônes et des couleurs non-chromatiques pour l'accessibilité.
/// Inclut un retour haptique au clic pour plus d'information.
class MemberRiskBadge extends StatelessWidget {
  static const String tag = 'MemberRiskBadge';
  final Logger _logger = Logger();

  final int trustScore;
  final double size;
  final VoidCallback? onTap;

   MemberRiskBadge({
    super.key,
    required this.trustScore,
    this.size = 24,
    this.onTap,
  });

  /// Détermine le niveau de risque à partir du score de confiance.
  static RiskLevel getRiskLevel(int trustScore) {
    if (trustScore >= 75) return RiskLevel.low;
    if (trustScore >= 50) return RiskLevel.medium;
    return RiskLevel.high;
  }

  RiskLevel get _riskLevel => getRiskLevel(trustScore);

  IconData _getIcon() {
    switch (_riskLevel) {
      case RiskLevel.low:
        return Icons.shield_rounded;
      case RiskLevel.medium:
        return Icons.warning_amber_rounded;
      case RiskLevel.high:
        return Icons.error_outline_rounded;
    }
  }

  Color _getColor() {
    switch (_riskLevel) {
      case RiskLevel.low:
        return Colors.greenAccent;
      case RiskLevel.medium:
        return Colors.orangeAccent;
      case RiskLevel.high:
        return Colors.redAccent;
    }
  }

  String _getLabel() {
    switch (_riskLevel) {
      case RiskLevel.low:
        return 'Fiable';
      case RiskLevel.medium:
        return 'Surveillance';
      case RiskLevel.high:
        return 'Critique';
    }
  }

  void _handleTap() {
    const method = '_handleTap';
    _logger.i('$tag.$method - Badge tapé, score: $trustScore');
    // Retour haptique proportionnel au risque
    switch (_riskLevel) {
      case RiskLevel.low:
        HapticFeedback.selectionClick();
        break;
      case RiskLevel.medium:
        HapticFeedback.mediumImpact();
        break;
      case RiskLevel.high:
        HapticFeedback.heavyImpact();
        break;
    }
    onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Tooltip(
        message: 'Score de confiance : $trustScore/100\n${_getLabel()}',
        child: Container(
          padding: EdgeInsets.all(size * 0.2),
          decoration: BoxDecoration(
            color: _getColor().withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: _getColor().withOpacity(0.5), width: 1),
          ),
          child: Icon(
            _getIcon(),
            size: size * 0.8,
            color: _getColor(),
          ),
        ),
      ),
    );
  }
}

enum RiskLevel { low, medium, high }
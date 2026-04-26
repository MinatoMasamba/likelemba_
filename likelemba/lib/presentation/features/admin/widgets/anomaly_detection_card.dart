// lib/presentation/features/tontine/screens/admin/widgets/anomaly_detection_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likelemba/presentation/shared/widgets/liquid_glass_card.dart';
import 'package:logger/logger.dart';


/// Carte de détection d'anomalies prédictives basée sur le modèle EDO.
/// Affiche le niveau de risque et un message explicatif.
class AnomalyDetectionCard extends StatelessWidget {
  static const String tag = 'AnomalyDetectionCard';
  final Logger _logger = Logger();

  final double riskLevel; // 0.0 à 1.0
  final String message;
  final VoidCallback? onCorrectiveAction;

   AnomalyDetectionCard({
    super.key,
    required this.riskLevel,
    required this.message,
    this.onCorrectiveAction,
  });

  @override
  Widget build(BuildContext context) {
    final isCritical = riskLevel > 0.7;
    final color = isCritical ? Colors.redAccent : Colors.cyanAccent;

    _logger.d('$tag.build - RiskLevel: $riskLevel, isCritical: $isCritical');

    return LiquidGlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Jauge circulaire de risque
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  value: riskLevel.clamp(0.0, 1.0),
                  backgroundColor: Colors.white10,
                  color: color,
                  strokeWidth: 4,
                ),
              ),
              Icon(
                isCritical ? Icons.warning_amber_rounded : Icons.psychology,
                color: color,
                size: 24,
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Message contextuel
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCritical ? "ANOMALIE SYSTÉMIQUE" : "ANALYSE PRÉDICTIVE",
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          // Bouton d'action corrective (si critique)
          if (isCritical && onCorrectiveAction != null)
            IconButton(
              icon: const Icon(Icons.flash_on, color: Colors.redAccent),
              onPressed: () {
                HapticFeedback.heavyImpact();
                _logger.i('$tag - Action corrective déclenchée.');
                onCorrectiveAction!();
              },
              tooltip: 'Action corrective immédiate',
            ),
        ],
      ),
    );
  }
}
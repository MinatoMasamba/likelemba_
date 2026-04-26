// lib/presentation/features/transactions/widgets/contribution_button.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:likelemba/core/app_colors.dart';
import 'package:logger/logger.dart';

/// 💸 Bouton de cotisation sécurisé "Hold-to-Confirm".
///
/// L'utilisateur doit maintenir le bouton enfoncé pendant 1.5 seconde pour valider.
/// Une jauge visuelle et un retour haptique progressif accompagnent l'action.
class ContributionButton extends StatefulWidget {
  final VoidCallback onContributionConfirmed;
  final bool isDelayed; // Si le membre est en retard, affiche une pulsation

  const ContributionButton({
    super.key,
    required this.onContributionConfirmed,
    this.isDelayed = false,
  });

  @override
  State<ContributionButton> createState() => _ContributionButtonState();
}

class _ContributionButtonState extends State<ContributionButton> with SingleTickerProviderStateMixin {
  static const String tag = 'ContributionButton';
  final Logger _logger = Logger();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _holdTimer;
  bool _isHolding = false;
  double _progress = 0.0;
  static const Duration _holdDuration = Duration(milliseconds: 1500);

  @override
  void initState() {
    super.initState();
    _logger.d('$tag.initState - Bouton de cotisation initialisé.');
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(_pulseController);
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startHolding() {
    const method = '_startHolding';
    _logger.i('$tag.$method - Début du maintien.');
    setState(() {
      _isHolding = true;
      _progress = 0.0;
    });
    HapticFeedback.lightImpact();

    final startTime = DateTime.now();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      final elapsed = DateTime.now().difference(startTime);
      setState(() {
        _progress = (elapsed.inMilliseconds / _holdDuration.inMilliseconds).clamp(0.0, 1.0);
      });

      // Retour haptique progressif
      if (_progress >= 0.33 && _progress < 0.34) {
        HapticFeedback.mediumImpact();
      } else if (_progress >= 0.66 && _progress < 0.67) {
        HapticFeedback.heavyImpact();
      }

      if (_progress >= 1.0) {
        timer.cancel();
        _completeHolding();
      }
    });
  }

  void _cancelHolding() {
    const method = '_cancelHolding';
    _logger.i('$tag.$method - Maintien annulé.');
    _holdTimer?.cancel();
    setState(() {
      _isHolding = false;
      _progress = 0.0;
    });
  }

  void _completeHolding() {
    const method = '_completeHolding';
    _logger.i('$tag.$method - Maintien complété, validation de la cotisation.');
    setState(() {
      _isHolding = false;
      _progress = 0.0;
    });
    HapticFeedback.heavyImpact();
    widget.onContributionConfirmed();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.isDelayed ? _pulseController : const AlwaysStoppedAnimation(1.0),
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isDelayed ? _pulseAnimation.value : 1.0,
          child: GestureDetector(
            onTapDown: (_) => _startHolding(),
            onTapUp: (_) => _cancelHolding(),
            onTapCancel: () => _cancelHolding(),
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [AppColors.accentTeal, AppColors.solidarityGold],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentTeal.withOpacity(_progress * 0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Jauge de progression
                  if (_isHolding)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            width: MediaQuery.of(context).size.width * _progress,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Contenu
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _isHolding ? 'Maintenez...' : 'Cotiser maintenant',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
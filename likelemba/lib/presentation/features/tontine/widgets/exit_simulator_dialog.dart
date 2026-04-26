// lib/presentation/features/tontine/widgets/exit_simulator_dialog.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likelemba/core/app_colors.dart';
import 'package:logger/logger.dart';
import '../../../../application/notifiers/tontine_notifier.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/utils/penalty_calculator.dart';
import '../../../../domain/entities/likelemba_group.dart';
import '../../../shared/widgets/glass_button.dart';

/// 🧮 Dialogue de simulation de sortie – "Formule de Paix".
///
/// Affiche le calcul détaillé du remboursement avec pénalité dégressive α(τ).
class ExitSimulatorDialog extends ConsumerStatefulWidget {
  static const String tag = 'ExitSimulatorDialog';
  final Logger _logger = Logger();

  final String groupId;
  final String userId;
  final double totalContributed;
  final int elapsedDays;

   ExitSimulatorDialog({
    super.key,
    required this.groupId,
    required this.userId,
    required this.totalContributed,
    required this.elapsedDays,
  });

  @override
  ConsumerState<ExitSimulatorDialog> createState() => _ExitSimulatorDialogState();
}

class _ExitSimulatorDialogState extends ConsumerState<ExitSimulatorDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _penaltyAnimation;
  late Animation<double> _refundAnimation;
  bool _isConfirmed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _penaltyAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutExpo),
    );
    _refundAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack)),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _confirmExit() {
    const method = '_confirmExit';
    widget._logger.i('$ExitSimulatorDialog.tag.$method - Sortie confirmée.');
    HapticFeedback.heavyImpact();
    setState(() => _isConfirmed = true);
    Navigator.pop(context, true);
  }

  void _cancel() {
    const method = '_cancel';
    widget._logger.i('$ExitSimulatorDialog.tag.$method - Sortie annulée.');
    Navigator.pop(context, false);
  }

  @override
  Widget build(BuildContext context) {
    final tontineState = ref.watch(tontineNotifierProvider);
    final group = tontineState.value?.selectedGroup;

    if (group == null) {
      return const Dialog(
        backgroundColor: Colors.transparent,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final penaltyRate = PenaltyCalculator.calculatePenaltyRate(
      elapsedDays: widget.elapsedDays,
      totalCycleDays: group.cycleDurationDays,
      basePenalty: group.basePenaltyRate,
    );
    final penaltyAmount = widget.totalContributed * penaltyRate;
    final refundAmount = widget.totalContributed - penaltyAmount;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primaryDeepBlue.withOpacity(0.8),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calculate_outlined, size: 48, color: Colors.cyanAccent),
                  const SizedBox(height: 16),
                  const Text(
                    'Formule de Paix',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Simulation de sortie anticipée',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  _buildAnimatedRow(
                    'Total cotisé',
                    MoneyFormatter.formatCDF(widget.totalContributed),
                    Colors.white,
                    1.0,
                  ),
                  const SizedBox(height: 8),
                  _buildAnimatedRow(
                    'Pénalité (${(penaltyRate * 100).toStringAsFixed(1)}%)',
                    '- ${MoneyFormatter.formatCDF(penaltyAmount)}',
                    Colors.redAccent,
                    _penaltyAnimation.value,
                  ),
                  const Divider(color: Colors.white24, height: 32),
                  _buildAnimatedRow(
                    'Remboursement net',
                    MoneyFormatter.formatCDF(refundAmount),
                    Colors.cyanAccent,
                    _refundAnimation.value,
                    isHighlight: true,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer_outlined, size: 16, color: Colors.white54),
                        const SizedBox(width: 8),
                        Text(
                          'Jours restants : ${group.cycleDurationDays - widget.elapsedDays}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'R = Argent Versé - (Pénalité × Temps)',
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _cancel,
                          child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GlassButton(
                          label: 'Confirmer la sortie',
                          icon: Icons.exit_to_app,
                          impact: HapticImpact.heavy,
                          onPressed: _confirmExit,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedRow(String label, String value, Color valueColor, double animValue, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
        AnimatedOpacity(
          opacity: animValue,
          duration: const Duration(milliseconds: 200),
          child: Transform.scale(
            scale: 1.0 + (isHighlight ? 0.05 * animValue : 0),
            child: Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: isHighlight ? 22 : 16,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
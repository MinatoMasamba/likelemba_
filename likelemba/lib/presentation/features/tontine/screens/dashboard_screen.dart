// lib/presentation/features/tontine/screens/dashboard_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likelemba/core/app_strings.dart';
import 'package:likelemba/domain/entities/likelemba_group.dart';
import 'package:likelemba/presentation/features/tontine/widgets/solvency_shield_widget.dart';
import 'package:likelemba/presentation/shared/widgets/money_display.dart';
import 'package:logger/logger.dart';
import '../../../../application/notifiers/tontine_notifier.dart';

import '../../../../core/theme/liquid_glass_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../shared/animations/fade_slide_transition.dart';
import '../../../shared/widgets/liquid_glass_card.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/error_snackbar.dart';

import '../widgets/horizontal_member_queue.dart';

/// 📱 Dashboard Participant – Vue principale du membre Likelemba.
///
/// Affiche la cagnotte, le bouclier de solvabilité (EDO), la file d'attente
/// et permet les actions de cotisation et de demande de réception.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  static const String tag = 'DashboardScreen';
  final Logger _logger = Logger();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _logger.i('$tag.initState - Dashboard participant initialisé.');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadGroupData();
    });
  }

  Future<void> _loadGroupData() async {
    const method = '_loadGroupData';
    _logger.i('$tag.$method - Chargement des données du groupe.');
    try {
      // TODO: Récupérer l'ID du groupe actif depuis le provider ou les préférences
      // await ref.read(tontineNotifierProvider.notifier).selectGroup('groupId');
    } catch (e, stack) {
      _logger.e('$tag.$method - Erreur: $e', error: e, stackTrace: stack);
    }
  }

  Future<void> _handleContribution() async {
    const method = '_handleContribution';
    setState(() => _isLoading = true);
    _logger.i('$tag.$method - Action de cotisation déclenchée.');
    try {
      // TODO: Appeler le use case de cotisation
      // await ref.read(submitContributionUseCaseProvider).call(...);
      HapticFeedback.mediumImpact();
      ErrorSnackbar.show(context, 'Cotisation enregistrée (simulation).');
    } catch (e, stack) {
      _logger.e('$tag.$method - Erreur: $e', error: e, stackTrace: stack);
      ErrorSnackbar.show(context, 'Erreur lors de la cotisation.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRequestPayout() async {
    const method = '_handleRequestPayout';
    _logger.i('$tag.$method - Demande de réception.');
    // Afficher le dialogue de la "Formule de Paix"
    await _showExitSimulationDialog();
  }

  Future<void> _showExitSimulationDialog() async {
    final result = await showDialog<ExitSimulationResult>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const _ExitSimulationDialog(),
    );
    if (result != null) {
      _logger.i('$tag._showExitSimulationDialog - Confirmation: ${result.confirmed}');
      if (result.confirmed) {
        // TODO: Déclencher la sortie effective
        ErrorSnackbar.show(context, 'Demande de réception envoyée à l\'administrateur.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tontineState = ref.watch(tontineNotifierProvider);
    final group = tontineState.value?.selectedGroup;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(AppStrings.appName, style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () => _logger.i('$tag - Statistiques EDO'),
            icon: const Icon(Icons.analytics_outlined),
          ),
          IconButton(
            onPressed: () => _logger.i('$tag - Profil'),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadGroupData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: StaggeredList(
                baseDelayMs: 100,
                delayIncrementMs: 80,
                children: [
                  // Carte de cagnotte avec pénalité dégressive
                  LiquidGlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Ma Cagnotte Attendue',
                              style: TextStyle(color: Colors.white70),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Pénalité: ${_formatPenalty(group)}',
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        MoneyDisplay(
                          amount: group?.netJackpot ?? 0,
                          currency: AppCurrency.cdf,
                        ),
                        const SizedBox(height: 15),
                        Text(
                          'Disponibilité estimée : ${_formatEstimatedDate(group)}',
                          style: const TextStyle(color: Colors.cyanAccent, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Bouton "Demander la réception"
                  FadeSlideTransition(
                    delayMs: 200,
                    child: GlassButton(
                      label: 'DEMANDER LA RÉCEPTION',
                      icon: Icons.account_balance_wallet_outlined,
                      impact: HapticImpact.heavy,
                      onPressed: _handleRequestPayout,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Bouclier de Solvabilité (EDO)
                  const Text(
                    'Indice de Résilience (EDO)',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  SolvencyShieldWidget(
                    solvencyRatio: _computeSolvencyRatio(group),
                    currentReserveFund: group?.currentReserveFund ?? 0,
                    targetReserveFund: group?.netJackpot ?? 0,
                    onTap: () => _logger.i('$tag - Bouclier tapé'),
                  ),

                  const SizedBox(height: 30),

                  // File d'attente horizontale
                  const Text(
                    'Ordre de réception',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 15),
                  HorizontalMemberQueue(),

                  const SizedBox(height: 30),

                  // Stats rapides
                  _buildQuickStats(group),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleContribution,
        backgroundColor: Colors.cyanAccent.withOpacity(0.8),
        label: const Text('Cotiser', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  String _formatPenalty(LikelembaGroup? group) {
    if (group == null) return '-- %';
    final elapsed = group.elapsedDays;
    final penalty = group.basePenaltyRate * (1 - elapsed / group.cycleDurationDays);
    return '${(penalty * 100).toStringAsFixed(1)}%';
  }

  String _formatEstimatedDate(LikelembaGroup? group) {
    if (group == null) return '--';
    // Simulation simple : date de fin de cycle
    final endDate = group.cycleStartDate.add(Duration(days: group.cycleDurationDays));
    return '${endDate.day}/${endDate.month}/${endDate.year}';
  }

  double _computeSolvencyRatio(LikelembaGroup? group) {
    if (group == null) return 0.0;
    final target = group.netJackpot;
    if (target <= 0) return 0.0;
    return (group.currentReserveFund / target).clamp(0.0, 1.0);
  }

  Widget _buildQuickStats(LikelembaGroup? group) {
    return Row(
      children: [
        Expanded(
          child: _statTile('Membres', group?.memberCount.toString() ?? '--'),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _statTile(
            'Fonds Réserve',
            MoneyFormatter.formatCDF(group?.currentReserveFund ?? 0),
          ),
        ),
      ],
    );
  }

  Widget _statTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// Dialogue de simulation de sortie ("Formule de Paix")
class _ExitSimulationDialog extends StatefulWidget {
  const _ExitSimulationDialog();

  @override
  State<_ExitSimulationDialog> createState() => _ExitSimulationDialogState();
}

class _ExitSimulationDialogState extends State<_ExitSimulationDialog> {
  static const String tag = '_ExitSimulationDialog';
  final Logger _logger = Logger();
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    // Valeurs simulées (à remplacer par les données réelles du provider)
    const totalContributed = 5000.0;
    const penaltyRate = 0.15;
    final penaltyAmount = totalContributed * penaltyRate;
    final refund = totalContributed - penaltyAmount;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: LiquidGlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calculate_outlined, size: 40, color: Colors.cyanAccent),
            const SizedBox(height: 16),
            const Text(
              'Formule de Paix',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Total cotisé', MoneyFormatter.formatCDF(totalContributed)),
            _buildInfoRow('Pénalité actuelle', '${(penaltyRate * 100).toStringAsFixed(1)}%'),
            _buildInfoRow('Montant retenu', MoneyFormatter.formatCDF(penaltyAmount)),
            const Divider(color: Colors.white24, height: 32),
            _buildInfoRow('Remboursement net', MoneyFormatter.formatCDF(refund), isHighlight: true),
            const SizedBox(height: 24),
            Text(
              'R = Argent Versé - (Pénalité × Temps)',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context, ExitSimulationResult(confirmed: false)),
                    child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassButton(
                    label: 'Confirmer',
                    impact: HapticImpact.heavy,
                    onPressed: () {
                      _logger.i('$tag - Sortie confirmée.');
                      Navigator.pop(context, ExitSimulationResult(confirmed: true));
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: TextStyle(
              color: isHighlight ? Colors.cyanAccent : Colors.white,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class ExitSimulationResult {
  final bool confirmed;
  ExitSimulationResult({required this.confirmed});
}
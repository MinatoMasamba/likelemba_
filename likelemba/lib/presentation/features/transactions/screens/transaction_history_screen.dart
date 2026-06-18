// lib/presentation/features/transactions/screens/transaction_history_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likelemba/core/app_colors.dart';
import 'package:logger/logger.dart';
import '../../../../application/notifiers/transaction_notifier.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../domain/entities/transaction.dart';
import '../../../shared/animations/fade_slide_transition.dart';
import '../../../shared/widgets/liquid_glass_card.dart';
import '../../../shared/widgets/error_snackbar.dart';

/// 📜 Écran d'historique des transactions – Registre transparent du Likelemba.
///
/// Affiche toutes les transactions du groupe actif avec une distinction visuelle
/// claire (entrée, sortie, pénalité) et un en-tête récapitulatif.
class TransactionHistoryScreen extends ConsumerStatefulWidget {
  final String groupId;

  const TransactionHistoryScreen({super.key, required this.groupId});

  @override
  ConsumerState<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends ConsumerState<TransactionHistoryScreen> {
  static const String tag = 'TransactionHistoryScreen';
  final Logger _logger = Logger();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _logger.i('$tag.initState - Chargement historique pour groupe ${widget.groupId}');
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTransactions());
  }

  Future<void> _loadTransactions() async {
    const method = '_loadTransactions';
    setState(() => _isLoading = true);
    _logger.i('$tag.$method - Récupération des transactions.');
    try {
      await ref.read(transactionNotifierProvider.notifier).loadTransactions(widget.groupId);
    } catch (e, stack) {
      _logger.e('$tag.$method - Erreur: $e', error: e, stackTrace: stack);
      ErrorSnackbar.show(context, 'Impossible de charger l\'historique.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionState = ref.watch(transactionNotifierProvider);
    final transactions = transactionState.value?.recentTransactions ?? [];

    // Calcul des totaux (simulation si vide)
    final totalIn = transactions
        .where((t) => t.type == TransactionType.contribution && t.status == TransactionStatus.validated)
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalOut = transactions
        .where((t) => t.type == TransactionType.payout && t.status == TransactionStatus.validated)
        .fold(0.0, (sum, t) => sum + t.amount);

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // AppBar en verre avec résumé
          SliverAppBar(
            expandedHeight: 160,
            collapsedHeight: 70,
            floating: true,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: FlexibleSpaceBar(
                  title: const Text(
                    'Historique',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primaryDeepBlue.withOpacity(0.9),
                          AppColors.primaryDeepBlue.withOpacity(0.3),
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 80, left: 20, right: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _SummaryChip(
                            label: 'Cotisations',
                            amount: totalIn,
                            icon: Icons.arrow_downward,
                            color: AppColors.solvencyGreen,
                          ),
                          _SummaryChip(
                            label: 'Réceptions',
                            amount: totalOut,
                            icon: Icons.arrow_upward,
                            color: AppColors.solidarityGold,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Liste des transactions
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: _isLoading
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : transactions.isEmpty
                    ? const SliverFillRemaining(
                        child: Center(
                          child: Text(
                            'Aucune transaction',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final tx = transactions[index];
                            return FadeSlideTransition(
                              delayMs: index * 50,
                              child: _TransactionTile(transaction: tx),
                            );
                          },
                          childCount: transactions.length,
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;

  const _SummaryChip({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
              Text(
                MoneyFormatter.formatCDF(amount),
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;

  const _TransactionTile({required this.transaction});

  IconData _getIcon() {
    switch (transaction.type) {
      case TransactionType.contribution:
        return Icons.arrow_downward;
      case TransactionType.payout:
        return Icons.arrow_upward;
      case TransactionType.penalty:
        return Icons.shield;
      case TransactionType.refund:
        return Icons.undo;
      case TransactionType.reserveFund:
        return Icons.savings;
    }
  }

  Color _getColor() {
    switch (transaction.type) {
      case TransactionType.contribution:
        return AppColors.solvencyGreen;
      case TransactionType.payout:
        return AppColors.solidarityGold;
      case TransactionType.penalty:
        return AppColors.riskRed;
      case TransactionType.refund:
        return Colors.orangeAccent;
      case TransactionType.reserveFund:
        return AppColors.reserveFundCyan;
    }
  }

  BoxShape _getShape() {
    switch (transaction.type) {
      case TransactionType.contribution:
        return BoxShape.circle;
      case TransactionType.payout:
        return BoxShape.rectangle;
      case TransactionType.penalty:
        // Hexagone simplifié en rectangle très arrondi
        return BoxShape.rectangle;
      default:
        return BoxShape.circle;
    }
  }

  String _getTitle() {
    switch (transaction.type) {
      case TransactionType.contribution:
        return 'Cotisation';
      case TransactionType.payout:
        return 'Réception cagnotte';
      case TransactionType.penalty:
        return 'Pénalité (Fonds de réserve)';
      case TransactionType.refund:
        return 'Remboursement';
      case TransactionType.reserveFund:
        return 'Alimentation fonds';
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeStr = '${transaction.timestamp.hour.toString().padLeft(2, '0')}:${transaction.timestamp.minute.toString().padLeft(2, '0')}';
    final color = _getColor();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LiquidGlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Icône typée
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: _getShape(),
                borderRadius: _getShape() == BoxShape.rectangle ? BorderRadius.circular(12) : null,
                border: Border.all(color: color.withOpacity(0.5)),
              ),
              child: Icon(_getIcon(), color: color, size: 24),
            ),
            const SizedBox(width: 16),
            // Détails
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getTitle(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        transaction.note ?? '',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      _StatusBadge(status: transaction.status),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Montant
            Text(
              MoneyFormatter.formatCDF(transaction.amount),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final TransactionStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    switch (status) {
      case TransactionStatus.pending:
        color = Colors.orangeAccent;
        text = 'En attente';
        break;
      case TransactionStatus.validated:
        color = AppColors.solvencyGreen;
        text = 'Validé';
        break;
      case TransactionStatus.rejected:
        color = AppColors.riskRed;
        text = 'Rejeté';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
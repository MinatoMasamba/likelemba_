// lib/presentation/features/tontine/screens/member_profile_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likelemba/core/app_colors.dart';
import 'package:likelemba/core/theme/text_styles.dart';
import 'package:likelemba/core/utils/money_formatter.dart';
import 'package:likelemba/domain/entities/transaction.dart';
import 'package:likelemba/presentation/shared/animations/fade_slide_transition.dart';
import 'package:likelemba/presentation/shared/widgets/liquid_glass_card.dart';
import 'package:likelemba/presentation/shared/widgets/error_snackbar.dart';
import 'package:logger/logger.dart';

import '../../../../application/providers/repository_providers.dart';
import '../../../features/admin/widgets/member_segmented_list.dart';

/// Écran de profil détaillé d'un membre.
class MemberProfileScreen extends ConsumerStatefulWidget {
  final int userId;
  final String userName;
  final int trustScore;
  final RiskLevel riskLevel;
  final String? groupId;

  const MemberProfileScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.trustScore,
    required this.riskLevel,
    this.groupId,
  });

  factory MemberProfileScreen.fromSegmentData(
    MemberSegmentData member, {
    String? groupId,
  }) {
    return MemberProfileScreen(
      userId: member.id,
      userName: member.name,
      trustScore: member.trustScore,
      riskLevel: member.riskLevel,
      groupId: groupId,
    );
  }

  @override
  ConsumerState<MemberProfileScreen> createState() => _MemberProfileScreenState();
}

class _MemberProfileScreenState extends ConsumerState<MemberProfileScreen> {
  static const String tag = 'MemberProfileScreen';
  final Logger _logger = Logger();

  List<Transaction> _transactions = [];
  double _totalContributed = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _logger.i('$tag._loadData - Chargement pour userId=${widget.userId}');
    try {
      final txResult = await ref
          .read(transactionRepositoryProvider)
          .getTransactionsByUser(widget.userId, limit: 20);

      txResult.fold(
        (failure) {
          _logger.e('$tag._loadData - Échec transactions: ${failure.message}');
          if (mounted) ErrorSnackbar.show(context, 'Impossible de charger les transactions.');
        },
        (transactions) {
          final contributed = transactions
              .where((t) =>
                  t.type == TransactionType.contribution &&
                  t.status == TransactionStatus.validated)
              .fold(0.0, (sum, t) => sum + t.amount);

          if (mounted) {
            setState(() {
              _transactions = transactions;
              _totalContributed = contributed;
              _isLoading = false;
            });
          }
        },
      );
    } catch (e, stack) {
      _logger.e('$tag._loadData - Exception: $e', error: e, stackTrace: stack);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = widget.userName.isNotEmpty
        ? widget.userName.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : '?';
    final avatarColor = _riskColor(widget.riskLevel);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profil du Membre',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF1A1C20), Color(0xFF0F2027), Color(0xFF203A43)],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: StaggeredList(
                      baseDelayMs: 80,
                      delayIncrementMs: 60,
                      children: [
                        // ── Carte héros ──────────────────────────────────
                        LiquidGlassCard(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // Avatar + score de confiance
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 100,
                                    height: 100,
                                    child: CircularProgressIndicator(
                                      value: widget.trustScore / 100.0,
                                      strokeWidth: 4,
                                      backgroundColor: Colors.white10,
                                      color: avatarColor,
                                    ),
                                  ),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(50),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                      child: Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: avatarColor.withOpacity(0.2),
                                          border: Border.all(color: avatarColor, width: 2),
                                        ),
                                        child: Center(
                                          child: Text(
                                            initials,
                                            style: TextStyle(
                                              color: avatarColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 28,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widget.userName,
                                style: AppTextStyles.sectionTitle(isDark: true),
                              ),
                              const SizedBox(height: 8),
                              _TrustBadge(
                                score: widget.trustScore,
                                riskLevel: widget.riskLevel,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Statistiques ─────────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                label: 'Total cotisé',
                                value: MoneyFormatter.formatCDF(_totalContributed),
                                icon: Icons.savings_outlined,
                                color: AppColors.solvencyGreen,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                label: 'Transactions',
                                value: '${_transactions.length}',
                                icon: Icons.receipt_long_outlined,
                                color: AppColors.accentTeal,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ── Score de confiance ────────────────────────────
                        LiquidGlassCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Score de Confiance',
                                style: AppTextStyles.cardTitle(isDark: true),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: LinearProgressIndicator(
                                      value: widget.trustScore / 100.0,
                                      backgroundColor: Colors.white12,
                                      color: avatarColor,
                                      minHeight: 10,
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '${widget.trustScore}/100',
                                    style: TextStyle(
                                      color: avatarColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _trustDescription(widget.trustScore),
                                style: AppTextStyles.bodySmall(isDark: true),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Historique des transactions ───────────────────
                        Text(
                          'Historique des transactions',
                          style: AppTextStyles.sectionTitle(isDark: true),
                        ),
                        const SizedBox(height: 12),

                        if (_transactions.isEmpty)
                          LiquidGlassCard(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Text(
                                'Aucune transaction enregistrée.',
                                style: AppTextStyles.bodyMedium(isDark: true),
                              ),
                            ),
                          )
                        else
                          ...List.generate(_transactions.length, (i) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _TransactionRow(transaction: _transactions[i]),
                            );
                          }),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Color _riskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return AppColors.solvencyGreen;
      case RiskLevel.medium:
        return AppColors.warningAmber;
      case RiskLevel.high:
        return AppColors.riskRed;
    }
  }

  String _trustDescription(int score) {
    if (score >= 80) return 'Membre très fiable — ponctuel et engagé.';
    if (score >= 60) return 'Membre fiable — quelques retards mineurs.';
    if (score >= 40) return 'Membre à surveiller — retards fréquents.';
    return 'Membre à risque — intervention recommandée.';
  }
}

class _TrustBadge extends StatelessWidget {
  final int score;
  final RiskLevel riskLevel;

  const _TrustBadge({required this.score, required this.riskLevel});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (riskLevel) {
      case RiskLevel.low:
        color = AppColors.solvencyGreen;
        label = 'Fiable';
        icon = Icons.verified_rounded;
        break;
      case RiskLevel.medium:
        color = AppColors.warningAmber;
        label = 'Modéré';
        icon = Icons.warning_amber_rounded;
        break;
      case RiskLevel.high:
        color = AppColors.riskRed;
        label = 'À risque';
        icon = Icons.error_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final Transaction transaction;

  const _TransactionRow({required this.transaction});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (transaction.type) {
      case TransactionType.contribution:
        color = AppColors.solvencyGreen;
        icon = Icons.arrow_downward;
        break;
      case TransactionType.payout:
        color = AppColors.solidarityGold;
        icon = Icons.arrow_upward;
        break;
      case TransactionType.penalty:
        color = AppColors.riskRed;
        icon = Icons.shield;
        break;
      case TransactionType.refund:
        color = Colors.orangeAccent;
        icon = Icons.undo;
        break;
      case TransactionType.reserveFund:
        color = AppColors.reserveFundCyan;
        icon = Icons.savings;
        break;
    }

    final date = transaction.timestamp;
    final dateStr = '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';

    Color statusColor;
    String statusText;
    switch (transaction.status) {
      case TransactionStatus.pending:
        statusColor = Colors.orangeAccent;
        statusText = 'En attente';
        break;
      case TransactionStatus.validated:
        statusColor = AppColors.solvencyGreen;
        statusText = 'Validé';
        break;
      case TransactionStatus.rejected:
        statusColor = AppColors.riskRed;
        statusText = 'Rejeté';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                if (transaction.note != null)
                  Text(
                    transaction.note!,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                MoneyFormatter.formatCDF(transaction.amount),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

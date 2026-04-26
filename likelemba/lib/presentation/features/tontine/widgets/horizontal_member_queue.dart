// lib/presentation/features/tontine/widgets/queue_horizontal_list.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likelemba/presentation/shared/widgets/liquid_glass_card.dart';
import 'package:logger/logger.dart';
import '../../../../application/notifiers/tontine_notifier.dart';
import '../../../../core/theme/liquid_glass_theme.dart';
import '../../../../domain/entities/likelemba_group.dart';
import '../../../../domain/entities/user.dart';
import 'member_risk_badge.dart' hide RiskLevel;

/// 📋 File d'attente horizontale dynamique des membres du Likelemba.
///
/// Affiche l'ordre de réception avec indicateurs de progression et de risque.
/// Le bénéficiaire actuel est mis en évidence par un halo lumineux.
class HorizontalMemberQueue extends ConsumerWidget {
  static const String tag = 'HorizontalMemberQueue';
  final Logger _logger = Logger();

  HorizontalMemberQueue({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    _logger.d('$tag.build - Construction de la file d\'attente.');
    final tontineState = ref.watch(tontineNotifierProvider);
    final group = tontineState.value?.selectedGroup;
    final members = _getMemberList(group);

    if (members.isEmpty) {
      return const LiquidGlassCard(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            'Aucun membre dans la file',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: RepaintBoundary(
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            final isCurrentBeneficiary = index == group?.currentBeneficiaryIndex;
            return _QueueItem(
              member: member,
              rank: index + 1,
              isCurrentBeneficiary: isCurrentBeneficiary,
              contributionProgress: _computeContributionProgress(member, group),
            );
          },
        ),
      ),
    );
  }

  List<User> _getMemberList(LikelembaGroup? group) {
    // Simulation : à remplacer par le chargement réel des membres via le repository
    // Dans l'implémentation réelle, on récupère les User à partir des memberIds
    const method = '_getMemberList';
    _logger.d('$tag.$method - Récupération des membres simulée.');
    return [
      const User(
        id: 1,
        name: 'Moi',
        phoneNumber: '+243123456789',
        role: UserRole.member,
        status: UserStatus.active,
        trustScore: 85,
        totalContribution: 5000,
        isBiometricEnabled: true,
      ),
      const User(
        id: 2,
        name: 'Jean P.',
        phoneNumber: '+243987654321',
        role: UserRole.member,
        status: UserStatus.active,
        trustScore: 70,
        totalContribution: 4500,
        isBiometricEnabled: false,
      ),
      const User(
        id: 3,
        name: 'Marie L.',
        phoneNumber: '+243555666777',
        role: UserRole.member,
        status: UserStatus.active,
        trustScore: 95,
        totalContribution: 5200,
        isBiometricEnabled: true,
      ),
      const User(
        id: 4,
        name: 'Marc A.',
        phoneNumber: '+243111222333',
        role: UserRole.member,
        status: UserStatus.active,
        trustScore: 45,
        totalContribution: 3000,
        isBiometricEnabled: false,
      ),
      const User(
        id: 5,
        name: 'Julie K.',
        phoneNumber: '+243444555666',
        role: UserRole.member,
        status: UserStatus.active,
        trustScore: 60,
        totalContribution: 3800,
        isBiometricEnabled: true,
      ),
    ];
  }

  double _computeContributionProgress(User member, LikelembaGroup? group) {
    if (group == null) return 0.0;
    // Simulation : calculer le ratio cotisations versées / attendues
    // À remplacer par un appel au TransactionRepository
    const method = '_computeContributionProgress';
    final progress = member.trustScore / 100.0; // Exemple simplifié
    _logger.d('$tag.$method - Progression pour ${member.name}: $progress');
    return progress.clamp(0.0, 1.0);
  }
}

/// Élément individuel de la file d'attente.
class _QueueItem extends StatefulWidget {
  final User member;
  final int rank;
  final bool isCurrentBeneficiary;
  final double contributionProgress;

  const _QueueItem({
    required this.member,
    required this.rank,
    required this.isCurrentBeneficiary,
    required this.contributionProgress,
  });

  @override
  State<_QueueItem> createState() => _QueueItemState();
}

class _QueueItemState extends State<_QueueItem> with SingleTickerProviderStateMixin {
  static const String tag = '_QueueItem';
  final Logger _logger = Logger();
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.4, end: 0.8).animate(_glowController);
    _logger.d('$tag.initState - Item pour ${widget.member.name} initialisé.');
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _showRiskDetails() {
    HapticFeedback.lightImpact();
    _logger.i('$tag._showRiskDetails - Affichage détail risque pour ${widget.member.name}.');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: Text('Score de confiance : ${widget.member.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score actuel : ${widget.member.trustScore}/100'),
            const SizedBox(height: 8),
            const Text('Historique de ponctualité : 3 mois'),
            const Text('Dernier paiement : à l\'heure'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final riskLevel = MemberRiskBadge.getRiskLevel(widget.member.trustScore);
    final bool isAtRisk = riskLevel == RiskLevel.medium || riskLevel == RiskLevel.high;

    return GestureDetector(
      onTap: _showRiskDetails,
      child: Container(
        margin: const EdgeInsets.only(right: 20),
        width: 90,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Cercle de progression
                SizedBox(
                  width: 78,
                  height: 78,
                  child: CircularProgressIndicator(
                    value: widget.contributionProgress,
                    strokeWidth: 3,
                    backgroundColor: Colors.white10,
                    color: widget.isCurrentBeneficiary ? Colors.cyanAccent : Colors.white38,
                  ),
                ),
                // Avatar avec effet Glass
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(50),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.isCurrentBeneficiary
                                ? Colors.cyanAccent.withOpacity(0.2)
                                : Colors.white.withOpacity(0.1),
                            border: Border.all(
                              color: widget.isCurrentBeneficiary ? Colors.cyanAccent : Colors.white24,
                              width: 1.5,
                            ),
                            boxShadow: widget.isCurrentBeneficiary
                                ? [
                                    BoxShadow(
                                      color: Colors.cyanAccent.withOpacity(_glowAnimation.value),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    )
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              widget.member.name[0],
                              style: TextStyle(
                                color: widget.isCurrentBeneficiary ? Colors.cyanAccent : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Badge de rang
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: widget.isCurrentBeneficiary ? Colors.cyanAccent : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${widget.rank}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Indicateur de risque (tremblement si à risque)
                if (isAtRisk)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: _ShakeWidget(
                      child: MemberRiskBadge(trustScore: widget.member.trustScore, size: 18),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.member.name,
              style: TextStyle(
                color: widget.isCurrentBeneficiary ? Colors.cyanAccent : Colors.white70,
                fontSize: 12,
                fontWeight: widget.isCurrentBeneficiary ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.isCurrentBeneficiary)
              const Text(
                "BÉNÉFICIAIRE",
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontSize: 8,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget provoquant une légère vibration (shake) pour attirer l'attention.
class _ShakeWidget extends StatefulWidget {
  final Widget child;
  const _ShakeWidget({required this.child});

  @override
  State<_ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<_ShakeWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat(reverse: true);
    _offset = Tween<Offset>(
      begin: const Offset(-0.02, 0),
      end: const Offset(0.02, 0),
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.translate(
          offset: _offset.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
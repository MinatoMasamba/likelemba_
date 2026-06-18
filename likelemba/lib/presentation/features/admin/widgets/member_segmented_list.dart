// lib/presentation/features/tontine/screens/admin/widgets/member_segmented_list.dart

import 'package:flutter/material.dart';
import 'package:likelemba/presentation/features/tontine/screens/member_profile_screen.dart';
import 'package:likelemba/presentation/shared/widgets/liquid_glass_card.dart';
import 'package:logger/logger.dart';


/// Liste segmentée des membres par niveau de risque (calculé par l'EDO).
/// Permet à l'admin de prioriser les actions de gestion.
class MemberSegmentedList extends StatelessWidget {
  static const String tag = 'MemberSegmentedList';
  final Logger _logger = Logger();

  final List<MemberSegmentData> members;

   MemberSegmentedList({super.key, required this.members});

  @override
  Widget build(BuildContext context) {
    _logger.d('$tag.build - Construction avec ${members.length} membres.');

    // Segmentation logique basée sur le statut de risque
    final contributors = members.where((m) => m.riskLevel == RiskLevel.low).toList();
    final pending = members.where((m) => m.riskLevel == RiskLevel.medium).toList();
    final risks = members.where((m) => m.riskLevel == RiskLevel.high).toList();

    return Column(
      children: [
        if (risks.isNotEmpty) ...[
          _buildSegment(context, "Membres à Risque (Alertes EDO)", risks, Colors.redAccent),
          const SizedBox(height: 16),
        ],
        if (pending.isNotEmpty) ...[
          _buildSegment(context, "Engagements en attente", pending, Colors.orangeAccent),
          const SizedBox(height: 16),
        ],
        if (contributors.isNotEmpty) ...[
          _buildSegment(context, "Contributeurs Actifs", contributors, Colors.greenAccent),
        ],
        if (members.isEmpty)
          const Center(
            child: Text(
              'Aucun membre à afficher',
              style: TextStyle(color: Colors.white54),
            ),
          ),
      ],
    );
  }

  Widget _buildSegment(BuildContext context, String title, List<MemberSegmentData> list, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        LiquidGlassCard(
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: list.length,
            separatorBuilder: (context, index) => Divider(
              color: Colors.white.withOpacity(0.05),
              height: 1,
            ),
            itemBuilder: (context, index) {
              final member = list[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.2),
                  child: Text(
                    member.name[0],
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  member.name,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                subtitle: Text(
                  "Score de confiance: ${member.trustScore}%",
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.3),
                  size: 14,
                ),
                onTap: () {
                  _logger.i('$tag - Membre sélectionné: ${member.name} (ID: ${member.id})');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MemberProfileScreen.fromSegmentData(member),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Données d'un membre pour l'affichage segmenté.
class MemberSegmentData {
  final int id;
  final String name;
  final int trustScore;
  final RiskLevel riskLevel;

  const MemberSegmentData({
    required this.id,
    required this.name,
    required this.trustScore,
    required this.riskLevel,
  });
}

enum RiskLevel { low, medium, high }
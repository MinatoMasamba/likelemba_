// lib/presentation/features/tontine/widgets/reserve_fund_chart.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:logger/logger.dart';
import '../../../../application/notifiers/tontine_notifier.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../domain/entities/likelemba_group.dart';
import '../../../shared/widgets/liquid_glass_card.dart';

/// 📈 Graphique du fonds de réserve F(t) – Visualisation de l'EDO.
///
/// Affiche une courbe d'aire avec un dégradé et une ligne de seuil critique.
/// Les données sont fournies par le TontineNotifier.
class ReserveFundChart extends ConsumerStatefulWidget {
  static const String tag = 'ReserveFundChart';
  final Logger _logger = Logger();

   ReserveFundChart({super.key, required LikelembaGroup group});

  @override
  ConsumerState<ReserveFundChart> createState() => _ReserveFundChartState();
}

class _ReserveFundChartState extends ConsumerState<ReserveFundChart> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _animation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showChartDetails() {
    HapticFeedback.mediumImpact();
    widget._logger.i('${ReserveFundChart.tag}._showChartDetails - Affichage détail graphique.');

    final tontineState = ref.read(tontineNotifierProvider);
    final group = tontineState.value?.selectedGroup;
    final projection = tontineState.value?.projections[group?.id ?? ''];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ChartDetailSheet(
        group: group,
        projection: projection,
        buildChartData: _buildChartData,
        buildLegend: _buildLegend,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tontineState = ref.watch(tontineNotifierProvider);
    final group = tontineState.value?.selectedGroup;
    final projection = tontineState.value?.projections[group?.id ?? ''];

    return GestureDetector(
      onTap: _showChartDetails,
      child: LiquidGlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Fonds de réserve F(t)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  MoneyFormatter.formatCDF(group?.currentReserveFund ?? 0),
                  style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return LineChart(
                      _buildChartData(group, projection, _animation.value),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildLegend(group),
          ],
        ),
      ),
    );
  }

  LineChartData _buildChartData(LikelembaGroup? group, FundProjection? projection, double animValue) {
    final spots = _generateSpots(group, projection, animValue);
    final criticalThreshold = (group?.netJackpot ?? 0) * 0.2;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: criticalThreshold > 0 ? criticalThreshold / 2 : 1000,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.white.withOpacity(0.1),
            strokeWidth: 0.5,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: group != null ? group.cycleDurationDays / 5 : 5,
            getTitlesWidget: (value, meta) {
              return Text(
                'J${value.toInt()}',
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            getTitlesWidget: (value, meta) {
              return Text(
                MoneyFormatter.formatCDF(value).replaceAll(' FC', ''),
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: group?.cycleDurationDays.toDouble() ?? 30,
      minY: 0,
      maxY: _computeMaxY(group, spots),
      lineBarsData: [
        // Courbe principale
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          color: Colors.cyanAccent,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.cyanAccent.withOpacity(0.3),
                Colors.cyanAccent.withOpacity(0.0),
              ],
            ),
          ),
        ),
        // Ligne de seuil critique
        LineChartBarData(
          spots: [
            FlSpot(0, criticalThreshold),
            FlSpot(group?.cycleDurationDays.toDouble() ?? 30, criticalThreshold),
          ],
          isCurved: false,
          color: Colors.redAccent,
          barWidth: 1.5,
          dashArray: [5, 5],
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                '${spot.x.toInt()}j : ${MoneyFormatter.formatCDF(spot.y)}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              );
            }).toList();
          },
          //tooltipBgColor: Colors.black87,
        ),
        handleBuiltInTouches: true,
      ),
    );
  }

  List<FlSpot> _generateSpots(LikelembaGroup? group, FundProjection? projection, double animValue) {
    if (group == null) return [const FlSpot(0, 0), const FlSpot(30, 5000)];
    // Simulation simplifiée : pente = n * a (cotisations quotidiennes)
    final dailyInflow = group.memberCount * group.dailyContribution * group.securityFeeRate;
    final List<FlSpot> spots = [];
    final currentFund = group.currentReserveFund;
    for (int day = 0; day <= group.cycleDurationDays; day++) {
      final projected = currentFund + dailyInflow * day;
      spots.add(FlSpot(day.toDouble(), projected * animValue));
    }
    return spots;
  }

  double _computeMaxY(LikelembaGroup? group, List<FlSpot> spots) {
    if (spots.isEmpty) return group?.netJackpot ?? 10000;
    final maxSpot = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    return maxSpot * 1.1;
  }

  Widget _buildLegend(LikelembaGroup? group) {
    final dailyInflow = group != null
        ? group.memberCount * group.dailyContribution * group.securityFeeRate
        : 0.0;
    final isHealthy = (group?.currentReserveFund ?? 0) >= (group?.netJackpot ?? 0) * 0.2;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Row(
          children: [
            Container(width: 12, height: 12, color: Colors.cyanAccent),
            const SizedBox(width: 4),
            Text('Fonds F(t)', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
          ],
        ),
        Row(
          children: [
            Container(
              width: 12,
              height: 2,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.redAccent, width: 1),
              ),
            ),
            const SizedBox(width: 4),
            Text('Seuil critique', style: TextStyle(color: Colors.redAccent.withOpacity(0.7), fontSize: 12)),
          ],
        ),
        Row(
          children: [
            Icon(
              isHealthy ? Icons.trending_up : Icons.trending_down,
              size: 14,
              color: isHealthy ? Colors.greenAccent : Colors.orangeAccent,
            ),
            const SizedBox(width: 4),
            Text(
              '${dailyInflow.toStringAsFixed(0)} FC/jour',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Vue agrandie du graphique ──────────────────────────────────────────────
class _ChartDetailSheet extends StatefulWidget {
  final LikelembaGroup? group;
  final FundProjection? projection;
  final LineChartData Function(LikelembaGroup?, FundProjection?, double) buildChartData;
  final Widget Function(LikelembaGroup?) buildLegend;

  const _ChartDetailSheet({
    required this.group,
    required this.projection,
    required this.buildChartData,
    required this.buildLegend,
  });

  @override
  State<_ChartDetailSheet> createState() => _ChartDetailSheetState();
}

class _ChartDetailSheetState extends State<_ChartDetailSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final criticalThreshold = (group?.netJackpot ?? 0) * 0.2;
    final currentFund = group?.currentReserveFund ?? 0;
    final isHealthy = currentFund >= criticalThreshold;
    final dailyInflow = group != null
        ? group.memberCount * group.dailyContribution * group.securityFeeRate
        : 0.0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          // Poignée
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          // Titre + statut
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'Évolution du Fonds F(t)',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isHealthy ? Colors.greenAccent : Colors.orangeAccent).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (isHealthy ? Colors.greenAccent : Colors.orangeAccent).withOpacity(0.4),
                    ),
                  ),
                  child: Text(
                    isHealthy ? 'SOLVABLE' : 'ALERTE',
                    style: TextStyle(
                      color: isHealthy ? Colors.greenAccent : Colors.orangeAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Graphique agrandi
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: AnimatedBuilder(
                animation: _anim,
                builder: (_, __) => LineChart(
                  widget.buildChartData(widget.group, widget.projection, _anim.value),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Légende
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: widget.buildLegend(widget.group),
          ),
          const SizedBox(height: 20),
          // KPIs bas de fiche
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _KpiTile(
                  label: 'Fonds actuel',
                  value: MoneyFormatter.formatCDF(currentFund),
                  color: Colors.cyanAccent,
                ),
                const SizedBox(width: 12),
                _KpiTile(
                  label: 'Seuil critique',
                  value: MoneyFormatter.formatCDF(criticalThreshold),
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 12),
                _KpiTile(
                  label: 'Afflux/jour',
                  value: '${dailyInflow.toStringAsFixed(0)} FC',
                  color: Colors.greenAccent,
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _KpiTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

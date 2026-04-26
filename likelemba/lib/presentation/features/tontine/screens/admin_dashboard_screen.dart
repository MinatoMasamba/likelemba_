// lib/presentation/features/tontine/screens/admin_dashboard_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likelemba/application/notifiers/auth_notifier.dart';
import 'package:likelemba/application/providers/repository_providers.dart';
import 'package:likelemba/core/app_colors.dart';
import 'package:likelemba/presentation/features/tontine/screens/create_tontine_screen.dart';
import 'package:likelemba/presentation/features/tontine/screens/payment_validation_screen.dart';
import 'package:logger/logger.dart';

import '../../../../application/notifiers/tontine_notifier.dart';
import '../../../../application/notifiers/sync_notifier.dart';

import '../../../../core/theme/liquid_glass_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../domain/entities/likelemba_group.dart';
import '../../../shared/animations/fade_slide_transition.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/liquid_glass_card.dart';
import '../../../shared/widgets/error_snackbar.dart';
import '../widgets/horizontal_member_queue.dart';
import '../widgets/reserve_fund_chart.dart';

/// 📊 Dashboard Administrateur – Poste de commandement du Likelemba.
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  static const String tag = 'AdminDashboardScreen';
  final Logger _logger = Logger();

  LikelembaGroup? _selectedGroup;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _logger.i('$tag.initState - Dashboard administrateur initialisé.');
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadManagedGroups());
  }

  Future<void> _loadManagedGroups() async {
    const method = '_loadManagedGroups';
    _logger.i('$tag.$method - Chargement des groupes administrés.');
    try {
      await ref.read(tontineNotifierProvider.notifier).loadManagedGroups();
    } catch (e, stack) {
      _logger.e('$tag.$method - Erreur: $e', error: e, stackTrace: stack);
    }
  }

  Future<void> _selectGroup(LikelembaGroup group) async {
    const method = '_selectGroup';
    _logger.i('$tag.$method - Sélection du groupe ${group.groupName} (ID: ${group.id})');
    HapticFeedback.mediumImpact();
    setState(() => _selectedGroup = group);
    try {
      // ID est un int, le notifier attend probablement un int aussi
      await ref.read(tontineNotifierProvider.notifier).selectGroup(group.id.toString());
    } catch (e, stack) {
      _logger.e('$tag.$method - Erreur chargement groupe: $e', error: e, stackTrace: stack);
      ErrorSnackbar.show(context, 'Impossible de charger les données du groupe.');
      setState(() => _selectedGroup = null);
    }
  }

  void _deselectGroup() {
    const method = '_deselectGroup';
    _logger.i('$tag.$method - Retour au Hub.');
    HapticFeedback.lightImpact();
    setState(() => _selectedGroup = null);
  }

  Future<void> _handleLockGroup() async {
    if (_selectedGroup == null) return;
    const method = '_handleLockGroup';
    setState(() => _isLoading = true);
    _logger.i('$tag.$method - Verrouillage du groupe ${_selectedGroup!.id}');
    try {
      HapticFeedback.heavyImpact();
      await ref.read(tontineNotifierProvider.notifier).lockGroup(_selectedGroup!.id);
      ErrorSnackbar.show(context, 'Groupe verrouillé avec succès.');
    } catch (e, stack) {
      _logger.e('$tag.$method - Erreur: $e', error: e, stackTrace: stack);
      ErrorSnackbar.show(context, 'Erreur lors du verrouillage.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleReplaceMember() async {
    if (_selectedGroup == null) return;
    const method = '_handleReplaceMember';
    _logger.i('$tag.$method - Remplacement d\'un membre.');
    ErrorSnackbar.show(context, 'Fonctionnalité de remplacement à venir.');
  }

  Future<void> _handleForceSync() async {
    const method = '_handleForceSync';
    _logger.i('$tag.$method - Synchronisation forcée.');
    try {
      await ref.read(syncNotifierProvider.notifier).triggerSync();
      ErrorSnackbar.show(context, 'Synchronisation lancée.');
    } catch (e, stack) {
      _logger.e('$tag.$method - Erreur: $e', error: e, stackTrace: stack);
      ErrorSnackbar.show(context, 'Erreur de synchronisation.');
    }
  }

  // lib/presentation/features/tontine/screens/admin_dashboard_screen.dart

Future<void> _handleValidatePayments() async {
  if (_selectedGroup == null) return;
  final tontineDataSource = ref.read(tontineRemoteDataSourceProvider);
  final groupUuid = _selectedGroup!.remoteId;   // ⚠️ Assurez-vous que remoteId est défini
  if (groupUuid == null) {
    ErrorSnackbar.show(context, 'UUID du groupe inconnu');
    return;
  }

  try {
    final members = await tontineDataSource.getMembershipsForValidation(groupUuid);
    if (members.isEmpty) {
      ErrorSnackbar.show(context, 'Aucun paiement en attente.');
      return;
    }

    // Afficher un BottomSheet pour choisir le membre
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MemberSelectionSheet(
        members: members,
        onSelect: (member) {
          Navigator.pop(ctx);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PaymentValidationScreen(
                groupId: _selectedGroup!.id,
                memberInfo: member,  // on passera l'objet complet
              ),
            ),
          );
        },
      ),
    );
  } catch (e) {
    ErrorSnackbar.show(context, 'Erreur lors du chargement des membres.');
  }
}



  /// Action de création d'une nouvelle tontine (bouton + FAB)
  Future<void> _handleCreateTontine() async {
  const method = '_handleCreateTontine';
  _logger.i('$tag.$method - Navigation vers création de tontine.');
  final result = await Navigator.push<bool>(
    context,
    MaterialPageRoute(builder: (_) => const CreateTontineScreen()),
  );
  if (result == true) {
    // Rafraîchir la liste des groupes après création réussie
    _loadManagedGroups();
  }
}

  @override
  Widget build(BuildContext context) {
    final tontineState = ref.watch(tontineNotifierProvider);
    final managedGroups = (tontineState.value?.managedGroups as List<LikelembaGroup>?) ?? [];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _selectedGroup == null ? 'Mes Makelembas' : _selectedGroup!.groupName,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: _selectedGroup != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: _deselectGroup,
              )
            : null,
        actions: [
          if (_selectedGroup != null) ...[
            IconButton(
              onPressed: _handleLockGroup,
              icon: Icon(
                _selectedGroup!.isLocked ? Icons.lock : Icons.lock_open,
                color: _selectedGroup!.isLocked ? Colors.orangeAccent : Colors.white,
              ),
              tooltip: _selectedGroup!.isLocked ? 'Groupe verrouillé' : 'Verrouiller le groupe',
            ),
          ],
          IconButton(
            onPressed: () => _logger.i('$tag - Paramètres'),
            icon: const Icon(Icons.settings),
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
            colors: [Color(0xFF1A1C20), Color(0xFF0F2027), Color(0xFF203A43)],
          ),
        ),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: child,
            ),
            child: _selectedGroup == null
                ? _buildHubView(managedGroups)
                : _buildCockpitView(_selectedGroup!),
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (_selectedGroup != null) {
      // Cockpit : bouton de validation des paiements
      return FloatingActionButton.extended(
        onPressed: _handleValidatePayments,
        backgroundColor: Colors.cyanAccent.withOpacity(0.8),
        label: const Text('Valider Paiements',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.check_circle, color: Colors.black),
      );
    } else {
      // Hub : bouton de création d'une nouvelle tontine
      return FloatingActionButton.extended(
        onPressed: _handleCreateTontine,
        backgroundColor: AppColors.accentTeal.withOpacity(0.9),
        label: const Text('Nouvelle Tontine',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.white),
      );
    }
  }

  // -------------------------------------------------------------------------
  // Vue Hub : Sélecteur de tontines
  // -------------------------------------------------------------------------

  Widget _buildHubView(List<LikelembaGroup> groups) {
    return RefreshIndicator(
      onRefresh: _loadManagedGroups,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'Sélectionnez une unité de gestion',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          groups.isEmpty
              ? const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Aucune tontine administrée.\nCréez-en une pour commencer.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.9,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final group = groups[index];
                        return _GroupTile(
                          group: group,
                          onTap: () => _selectGroup(group),
                        );
                      },
                      childCount: groups.length,
                    ),
                  ),
                ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 20)),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Vue Cockpit : Dashboard détaillé
  // -------------------------------------------------------------------------

  Widget _buildCockpitView(LikelembaGroup group) {
    return RefreshIndicator(
      onRefresh: () => _selectGroup(group),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: StaggeredList(
          baseDelayMs: 100,
          delayIncrementMs: 80,
          children: [
            LiquidGlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.groupName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  if (group.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      group.description!,
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip('${group.memberCount} membres', Icons.people),
                      _buildChip(
                        'Cycle: ${group.elapsedDays}/${group.cycleDurationDays} j',
                        Icons.calendar_today,
                      ),
                      _buildChip(
                        MoneyFormatter.formatCDF(group.netJackpot),
                        Icons.account_balance_wallet,
                      ),
                      if (group.isLocked)
                        _buildChip('VERROUILLÉ', Icons.lock, color: Colors.orangeAccent),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Évolution du Fonds de Réserve F(t)',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            ReserveFundChart(group: group),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GlassButton(
                    label: 'Remplacer',
                    icon: Icons.person_add,
                    impact: HapticImpact.medium,
                    onPressed: _handleReplaceMember,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GlassButton(
                    label: 'synchro',
                    icon: Icons.sync,
                    impact: HapticImpact.light,
                    onPressed: _handleForceSync,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Gestion des Participants',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildMemberSegmentedList(group),
            const SizedBox(height: 24),
            const Text(
              'File d\'attente actuelle',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
             HorizontalMemberQueue(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color ?? Colors.white70),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color ?? Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMemberSegmentedList(LikelembaGroup group) {
    final int totalMembers = group.memberCount;
    final int upToDate = (totalMembers * 0.7).round();
    final int future = (totalMembers * 0.2).round();
    final int late = totalMembers - upToDate - future;

    final segments = [
      {'title': 'Contributeurs', 'count': upToDate, 'icon': Icons.check_circle, 'color': Colors.greenAccent},
      {'title': 'Engagements futurs', 'count': future, 'icon': Icons.schedule, 'color': Colors.orangeAccent},
      {'title': 'Retards', 'count': late, 'icon': Icons.warning, 'color': Colors.redAccent},
    ];

    return LiquidGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: segments.map((seg) {
          return ListTile(
            leading: Icon(seg['icon'] as IconData, color: seg['color'] as Color),
            title: Text(seg['title'] as String, style: const TextStyle(color: Colors.white)),
            trailing: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (seg['color'] as Color).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${seg['count']}', style: TextStyle(color: seg['color'] as Color, fontWeight: FontWeight.bold)),
            ),
            onTap: () => _logger.i('$tag - Segment sélectionné: ${seg['title']}'),
          );
        }).toList(),
      ),
    );
  }
}


// ─── BottomSheet de sélection ──────────────────────────────
class _MemberSelectionSheet extends StatelessWidget {
  final List<MembershipInfo> members;
  final void Function(MembershipInfo) onSelect;

  const _MemberSelectionSheet({required this.members, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryDeepBlue.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          Text('Paiements en attente', style: AppTextStyles.sectionTitle(isDark: isDark)),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: members.length,
              itemBuilder: (_, i) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.accentTeal.withOpacity(0.2),
                  child: Text(members[i].avatarInitials,
                      style: TextStyle(color: AppColors.accentTeal, fontWeight: FontWeight.bold)),
                ),
                title: Text(members[i].userName, style: AppTextStyles.bodyLarge(isDark: isDark)),
                subtitle: Text('${members[i].amountToValidate.toStringAsFixed(0)} FC',
                    style: AppTextStyles.bodySmall(isDark: isDark)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white),
                onTap: () => onSelect(members[i]),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}


class _GroupTile extends StatelessWidget {
  final LikelembaGroup group;
  final VoidCallback onTap;

  const _GroupTile({required this.group, required this.onTap});

  Color _getHealthColor() {
    // Éviter la division par zéro si netJackpot = 0
    if (group.netJackpot <= 0) return AppColors.warningAmber;
    final ratio = group.currentReserveFund / group.netJackpot;
    if (ratio >= 0.5) return AppColors.solvencyGreen;
    if (ratio >= 0.25) return AppColors.warningAmber;
    return AppColors.riskRed;
  }

  @override
  Widget build(BuildContext context) {
    final healthColor = _getHealthColor();
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: LiquidGlassCard(
        padding: const EdgeInsets.all(12), // réduit
        child: Column(
          mainAxisSize: MainAxisSize.min,  // ← important pour éviter l'expansion infinie
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: healthColor.withOpacity(0.15),
                border: Border.all(color: healthColor.withOpacity(0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: healthColor.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(Icons.shield_rounded, color: healthColor, size: 24),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: Text(
                group.groupName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${group.memberCount} membres',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: healthColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                group.isLocked ? 'VERROUILLÉ' : 'ACTIF',
                style: TextStyle(
                  color: healthColor,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
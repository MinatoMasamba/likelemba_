// lib/presentation/features/tontine/screens/join_requests_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likelemba/core/app_colors.dart';
import 'package:likelemba/core/theme/text_styles.dart';
import 'package:likelemba/presentation/shared/widgets/glass_button.dart';
import 'package:likelemba/presentation/shared/widgets/liquid_glass_card.dart';
import 'package:likelemba/presentation/shared/widgets/error_snackbar.dart';
import 'package:logger/logger.dart';

import '../../../../application/providers/repository_providers.dart';
import '../../../../data/remote/tontine_remote_data_source.dart';

/// Écran de gestion des demandes d'adhésion (admin uniquement).
class JoinRequestsScreen extends ConsumerStatefulWidget {
  final String groupUuid;
  final String groupName;

  const JoinRequestsScreen({
    super.key,
    required this.groupUuid,
    required this.groupName,
  });

  @override
  ConsumerState<JoinRequestsScreen> createState() => _JoinRequestsScreenState();
}

class _JoinRequestsScreenState extends ConsumerState<JoinRequestsScreen> {
  static const String tag = 'JoinRequestsScreen';
  final Logger _logger = Logger();

  List<JoinRequestInfo> _requests = [];
  bool _isLoading = true;
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    _logger.i('$tag._loadRequests - Groupe ${widget.groupUuid}');
    setState(() => _isLoading = true);
    try {
      final dataSource = ref.read(tontineRemoteDataSourceProvider);
      final requests = await dataSource.getPendingJoinRequests(widget.groupUuid);
      if (mounted) {
        setState(() {
          _requests = requests;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      _logger.e('$tag._loadRequests - Erreur: $e', error: e, stackTrace: stack);
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorSnackbar.show(context, 'Impossible de charger les demandes d\'adhésion.');
      }
    }
  }

  Future<void> _handleApprove(JoinRequestInfo request) async {
    _logger.i('$tag._handleApprove - Approbation demande ${request.id}');
    setState(() => _processingIds.add(request.id));
    HapticFeedback.mediumImpact();

    try {
      final dataSource = ref.read(tontineRemoteDataSourceProvider);
      await dataSource.approveJoinRequest(request.id);

      if (mounted) {
        HapticFeedback.heavyImpact();
        setState(() {
          _requests.removeWhere((r) => r.id == request.id);
          _processingIds.remove(request.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${request.userName} a été accepté dans le groupe.'),
            backgroundColor: AppColors.solvencyGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e, stack) {
      _logger.e('$tag._handleApprove - Erreur: $e', error: e, stackTrace: stack);
      if (mounted) {
        setState(() => _processingIds.remove(request.id));
        ErrorSnackbar.show(context, 'Erreur lors de l\'approbation.');
      }
    }
  }

  Future<void> _handleReject(JoinRequestInfo request) async {
    _logger.i('$tag._handleReject - Rejet demande ${request.id}');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.primaryDeepBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rejeter la demande', style: TextStyle(color: Colors.white)),
        content: Text(
          'Rejeter la demande de ${request.userName} ?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rejeter', style: TextStyle(color: AppColors.riskRed)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _processingIds.add(request.id));
    HapticFeedback.mediumImpact();

    try {
      final dataSource = ref.read(tontineRemoteDataSourceProvider);
      await dataSource.rejectJoinRequest(request.id);

      if (mounted) {
        setState(() {
          _requests.removeWhere((r) => r.id == request.id);
          _processingIds.remove(request.id);
        });
        ErrorSnackbar.show(context, 'Demande de ${request.userName} rejetée.');
      }
    } catch (e, stack) {
      _logger.e('$tag._handleReject - Erreur: $e', error: e, stackTrace: stack);
      if (mounted) {
        setState(() => _processingIds.remove(request.id));
        ErrorSnackbar.show(context, 'Erreur lors du rejet.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Demandes d\'adhésion',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              widget.groupName,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadRequests,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.adminDashboardGradient),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadRequests,
                  child: _requests.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _requests.length,
                          itemBuilder: (context, index) {
                            final request = _requests[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _JoinRequestCard(
                                request: request,
                                isProcessing: _processingIds.contains(request.id),
                                onApprove: () => _handleApprove(request),
                                onReject: () => _handleReject(request),
                              ),
                            );
                          },
                        ),
                ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 64,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune demande en attente',
            style: AppTextStyles.sectionTitle(isDark: true),
          ),
          const SizedBox(height: 8),
          Text(
            'Toutes les demandes ont été traitées.',
            style: AppTextStyles.bodyMedium(isDark: true),
          ),
        ],
      ),
    );
  }
}

class _JoinRequestCard extends StatelessWidget {
  final JoinRequestInfo request;
  final bool isProcessing;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _JoinRequestCard({
    required this.request,
    required this.isProcessing,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final date = request.requestedAt;
    final dateStr = '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';

    return LiquidGlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.accentTeal.withOpacity(0.2),
                child: Text(
                  request.avatarInitials,
                  style: const TextStyle(
                    color: AppColors.accentTeal,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (request.phoneNumber.isNotEmpty)
                      Text(
                        request.phoneNumber,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    Text(
                      'Demande du $dateStr',
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
              // Badge en attente
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warningAmber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warningAmber.withOpacity(0.4)),
                ),
                child: const Text(
                  'EN ATTENTE',
                  style: TextStyle(
                    color: AppColors.warningAmber,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Colors.white10, height: 1),
          const SizedBox(height: 14),
          // Boutons d'action
          if (isProcessing)
            const Center(
              child: SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: GlassButton(
                    label: 'Rejeter',
                    icon: Icons.close_rounded,
                    isPrimary: false,
                    impact: HapticImpact.medium,
                    onPressed: onReject,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlassButton(
                    label: 'Accepter',
                    icon: Icons.check_rounded,
                    impact: HapticImpact.heavy,
                    onPressed: onApprove,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

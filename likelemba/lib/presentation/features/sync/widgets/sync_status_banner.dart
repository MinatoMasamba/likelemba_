// lib/presentation/features/sync/widgets/sync_status_banner.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:likelemba/core/app_colors.dart';
import 'package:logger/logger.dart';
import '../../../../application/notifiers/sync_notifier.dart';
import '../../../shared/widgets/liquid_glass_card.dart';

/// Bannière de statut de synchronisation – Indicateur Offline-First non intrusif.
class SyncStatusBanner extends ConsumerStatefulWidget {
  const SyncStatusBanner({super.key});

  @override
  ConsumerState<SyncStatusBanner> createState() => _SyncStatusBannerState();
}

class _SyncStatusBannerState extends ConsumerState<SyncStatusBanner>
    with SingleTickerProviderStateMixin {
  static const String tag = 'SyncStatusBanner';
  final Logger _logger = Logger();

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController); 
    _logger.d('$tag.initState - Bannière de synchronisation initialisée.');
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _triggerHaptic(SyncState state) {
    if (state.isSyncing) {
      HapticFeedback.lightImpact();
    } else if (state.pendingActionsCount > 0 && !state.isOnline) {
      // Ne rien faire
    } else if (state.lastSyncAt != null && state.pendingActionsCount == 0) {
      HapticFeedback.selectionClick();
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(syncNotifierProvider);

    // ✅ Correction : Utiliser .when pour accéder à la valeur
    return asyncState.when(
      data: (syncState) => _buildContent(syncState),
      loading: () => _buildLoading(),
      error: (error, stack) => _buildError(error.toString()),
    );
  }

  Widget _buildContent(SyncState syncState) {
    final hasPending = syncState.pendingActionsCount > 0;
    final isOnline = syncState.isOnline;
    final isSyncing = syncState.isSyncing;

    if (!hasPending && !isSyncing && isOnline) {
      return const SizedBox.shrink();
    }

    _fadeController.forward();
    _triggerHaptic(syncState);

    IconData icon;
    String statusText;
    Color accentColor;
    Widget? trailing;

    if (isSyncing) {
      icon = Icons.sync;
      statusText = 'Synchronisation en cours...';
      accentColor = AppColors.accentTeal;
      trailing = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentTeal),
        ),
      );
    } else if (!isOnline) {
      icon = Icons.cloud_off;
      statusText = 'Mode hors-ligne · $hasPending action(s) en attente';
      accentColor = Colors.grey;
      trailing = Icon(Icons.wifi_off, color: accentColor, size: 18);
    } else if (hasPending) {
      icon = Icons.cloud_queue;
      statusText = '$hasPending action(s) en attente de synchronisation';
      accentColor = AppColors.warningAmber;
      trailing = Icon(Icons.arrow_upward, color: accentColor, size: 18);
    } else {
      icon = Icons.check_circle_outline;
      statusText = 'Synchronisé';
      accentColor = AppColors.solvencyGreen;
      trailing = Icon(Icons.check, color: accentColor, size:18);
    }

    _logger.d('$tag.build - État: online=$isOnline, syncing=$isSyncing, pending=$hasPending');

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: LiquidGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 12),
                trailing,
              ],
              if (hasPending && isOnline && !isSyncing)
                TextButton(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    _logger.i('$tag - Synchronisation manuelle déclenchée.');
                    await ref.read(syncNotifierProvider.notifier).triggerSync();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('SYNC'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LiquidGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Chargement...'),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LiquidGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.riskRed, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Erreur sync: $error',
                style: const TextStyle(color: AppColors.riskRed),
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(syncNotifierProvider),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
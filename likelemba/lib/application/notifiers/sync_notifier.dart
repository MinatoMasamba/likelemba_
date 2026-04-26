// lib/application/notifiers/sync_notifier.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../core/network/connectivity_monitor.dart';
import '../../domain/usecases/sync/process_outbox_use_case.dart';
import '../../domain/usecases/sync/retry_failed_sync_use_case.dart';
import '../providers/repository_providers.dart';
import '../providers/use_case_providers.dart';

/// État de synchronisation
class SyncState {
  final bool isOnline;
  final bool isSyncing;
  final int pendingActionsCount;
  final DateTime? lastSyncAt;
  final String? errorMessage;

  const SyncState({
    this.isOnline = false,
    this.isSyncing = false,
    this.pendingActionsCount = 0,
    this.lastSyncAt,
    this.errorMessage,
  });

  SyncState copyWith({
    bool? isOnline,
    bool? isSyncing,
    int? pendingActionsCount,
    DateTime? lastSyncAt,
    String? errorMessage,
  }) {
    return SyncState(
      isOnline: isOnline ?? this.isOnline,
      isSyncing: isSyncing ?? this.isSyncing,
      pendingActionsCount: pendingActionsCount ?? this.pendingActionsCount,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// 🔄 Notifier gérant la synchronisation Offline-First (Outbox Pattern).
class SyncNotifier extends AsyncNotifier<SyncState> {
  final Logger _logger = Logger();
  StreamSubscription? _connectivitySubscription;

  @override
  Future<SyncState> build() async {
    const method = 'SyncNotifier.build';
    _logger.i('$method - Initialisation du moniteur de synchronisation.');

    // Surveiller la connectivité
    _listenToConnectivity();

    // Compter les actions en attente
    final pending = await _countPendingActions();
    final isOnline = await ref.read(connectivityMonitorProvider).isConnected;

    return SyncState(
      isOnline: isOnline,
      pendingActionsCount: pending,
    );
  }

  void _listenToConnectivity() {
    final monitor = ref.read(connectivityMonitorProvider);
    _connectivitySubscription = monitor.onConnectivityChanged.listen((isOnline) async {
      final current = state.value ?? const SyncState();
      state = AsyncValue.data(current.copyWith(isOnline: isOnline));

      if (isOnline) {
        _logger.i('SyncNotifier - Réseau disponible, déclenchement synchronisation.');
        await triggerSync();
      }
    });
  }

  /// Déclenche la synchronisation des actions en attente.
  Future<void> triggerSync() async {
    final current = state.value;
    if (current == null || current.isSyncing || !current.isOnline) return;

    state = AsyncValue.data(current.copyWith(isSyncing: true));

    final useCase = ref.read(processOutboxUseCaseProvider);
    final result = await useCase.call();

    result.fold(
      (failure) {
        state = AsyncValue.data(current.copyWith(
          isSyncing: false,
          errorMessage: failure.message,
        ));
      },
      (pushResult) async {
        _logger.i('SyncNotifier.triggerSync - ${pushResult.syncedIds.length} actions synchronisées.');

        // Mettre à jour le compteur d'actions en attente
        final pending = await _countPendingActions();
        state = AsyncValue.data(current.copyWith(
          isSyncing: false,
          pendingActionsCount: pending,
          lastSyncAt: DateTime.now(),
        ));
      },
    );
  }

  /// Réessaie les synchronisations échouées.
  Future<void> retryFailed() async {
    final useCase = ref.read(retryFailedSyncUseCaseProvider);
    final result = await useCase.call();
    result.fold(
      (failure) {
        _logger.e('SyncNotifier.retryFailed - Échec: ${failure.message}');
      },
      (_) {
        _logger.i('SyncNotifier.retryFailed - Reprise terminée.');
      },
    );
  }

  Future<int> _countPendingActions() async {
    final messages = await ref.read(outboxDaoProvider).getPendingMessages();
    return messages.length;
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}

final syncNotifierProvider = AsyncNotifierProvider<SyncNotifier, SyncState>(SyncNotifier.new);
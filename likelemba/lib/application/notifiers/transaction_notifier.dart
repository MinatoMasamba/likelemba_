// lib/application/notifiers/transaction_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likelemba/application/providers/repository_providers.dart';
import 'package:logger/logger.dart';
import '../../data/remote/tontine_remote_data_source.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/usecases/transaction/submit_contribution_use_case.dart';
import '../../domain/usecases/transaction/validate_payment_use_case.dart';
import '../providers/use_case_providers.dart';

/// État des transactions
class TransactionState {
  final List<Transaction> recentTransactions;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;

  const TransactionState({
    this.recentTransactions = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  TransactionState copyWith({
    List<Transaction>? recentTransactions,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return TransactionState(
      recentTransactions: recentTransactions ?? this.recentTransactions,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// 💸 Notifier gérant les flux financiers (cotisations, retraits, validations).
class TransactionNotifier extends AsyncNotifier<TransactionState> {
  final Logger _logger = Logger();

  @override
  Future<TransactionState> build() async {
    return const TransactionState();
  }

  /// Soumet une cotisation quotidienne.
  Future<void> submitContribution({
    required String groupId,
    required String userId,
    required double amount,
    String? proofImageUrl,
  }) async {
    state = AsyncValue.data(state.value?.copyWith(isSubmitting: true) ?? const TransactionState(isSubmitting: true));

    final useCase = ref.read(submitContributionUseCaseProvider);
    final result = await useCase.call(
      groupId: groupId,
      userId: userId,
      amount: amount,
      proofImageUrl: proofImageUrl,
    );

    result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
      },
      (transaction) {
        _logger.i('TransactionNotifier.submitContribution - Transaction créée: ${transaction.id}');
        final current = state.value ?? const TransactionState();
        state = AsyncValue.data(current.copyWith(
          isSubmitting: false,
          recentTransactions: [transaction, ...current.recentTransactions],
        ));
      },
    );
  }

  /// Valide une transaction (admin uniquement).
  Future<void> validateTransaction(String transactionId, String adminUserId) async {
    state = AsyncValue.data(state.value?.copyWith(isLoading: true) ?? const TransactionState(isLoading: true));

    final useCase = ref.read(validatePaymentUseCaseProvider);
    final result = await useCase.call(transactionId, adminUserId);

    result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
      },
      (_) {
        _logger.i('TransactionNotifier.validateTransaction - Transaction $transactionId validée.');
        state = AsyncValue.data(state.value!.copyWith(isLoading: false));
      },
    );
  }

  /// Demande un retrait anticipé (calcul de la pénalité dégressive).
  Future<double?> requestExit(String groupId, String userId) async {
    final result = await ref.read(transactionRepositoryProvider).calculateExitRefund(int.parse(groupId), int.parse(userId));
    return result.fold(
      (failure) {
        _logger.e('TransactionNotifier.requestExit - Échec: ${failure.message}');
        return null;
      },
      (refund) => refund,
    );
  }

  /// Envoie une demande de réception de la cagnotte à l'admin via l'API distante.
  Future<void> requestPayout({
    required String groupId,
    required String userId,
  }) async {
    const method = 'requestPayout';
    _logger.i('TransactionNotifier.$method - Groupe $groupId, Membre $userId');
    final dataSource = ref.read(tontineRemoteDataSourceProvider);
    await dataSource.requestPayout(groupId: groupId, userId: userId);
    _logger.i('TransactionNotifier.$method - Demande envoyée avec succès.');
  }

  Future<void> loadTransactions(String groupId) async {
    const method = 'loadTransactions';
    _logger.i('$method - Chargement des transactions pour groupe $groupId');

    final current = state.value ?? const TransactionState();
    state = AsyncValue.data(current.copyWith(isLoading: true));

    final result = await ref
        .read(transactionRepositoryProvider)
        .getTransactionsByGroup(int.parse(groupId));

    result.fold(
      (failure) {
        _logger.e('$method - Échec: ${failure.message}');
        state = AsyncValue.error(failure.message, StackTrace.current);
      },
      (transactions) {
        _logger.i('$method - ${transactions.length} transactions chargées.');
        state = AsyncValue.data(
          (state.value ?? const TransactionState()).copyWith(
            isLoading: false,
            recentTransactions: transactions,
          ),
        );
      },
    );
  }
}

final transactionNotifierProvider = AsyncNotifierProvider<TransactionNotifier, TransactionState>(TransactionNotifier.new);
// lib/application/providers/use_case_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likelemba/domain/usecases/auth/register_user_use_case.dart';
import 'package:likelemba/domain/usecases/tontine/create_group_use_case.dart';

import '../../domain/usecases/auth/login_use_case.dart';
import '../../domain/usecases/auth/register_biometric_use_case.dart';
import '../../domain/usecases/tontine/calculate_cycle_projection_use_case.dart';
import '../../domain/usecases/tontine/process_member_exit_use_case.dart';
import '../../domain/usecases/tontine/get_queue_position_use_case.dart';
import '../../domain/usecases/transaction/submit_contribution_use_case.dart';
import '../../domain/usecases/transaction/validate_payment_use_case.dart';
import '../../domain/usecases/sync/process_outbox_use_case.dart';
import '../../domain/usecases/sync/retry_failed_sync_use_case.dart';

import 'repository_providers.dart';

// -----------------------------------------------------------------------------
// 🔐 Providers pour les Use Cases d'Authentification
// -----------------------------------------------------------------------------

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  print('loginUseCaseProvider - Création de LoginUseCase.');
  final authRepo = ref.watch(authRepositoryProvider);
  final syncRepo = ref.watch(syncRepositoryProvider);
  return LoginUseCase(authRepo, syncRepo);
});

final registerBiometricUseCaseProvider = Provider<RegisterBiometricUseCase>((ref) {
  print('registerBiometricUseCaseProvider - Création de RegisterBiometricUseCase.');
  final authRepo = ref.watch(authRepositoryProvider);
  return RegisterBiometricUseCase(authRepo);
});

final registerUserUseCaseProvider = Provider<RegisterUserUseCase>((ref) {
  print('registerUserUseCaseProvider - Création.');
  final authRepo = ref.watch(authRepositoryProvider);
  return RegisterUserUseCase(authRepo);
});


// lib/application/providers/use_case_providers.dart
// Ajouter le provider pour CreateGroupUseCase

final createGroupUseCaseProvider = Provider<CreateGroupUseCase>((ref) {
  print('createGroupUseCaseProvider - Création.');
  final tontineRepo = ref.watch(tontineRepositoryProvider);
  return CreateGroupUseCase(tontineRepo);
});
// -----------------------------------------------------------------------------
// 🌀 Providers pour les Use Cases de Tontine (Groupes)
// -----------------------------------------------------------------------------

final calculateCycleProjectionUseCaseProvider = Provider<CalculateCycleProjectionUseCase>((ref) {
  print('calculateCycleProjectionUseCaseProvider - Création.');
  final tontineRepo = ref.watch(tontineRepositoryProvider);
  return CalculateCycleProjectionUseCase(tontineRepo);
});

final processMemberExitUseCaseProvider = Provider<ProcessMemberExitUseCase>((ref) {
  print('processMemberExitUseCaseProvider - Création.');
  final tontineRepo = ref.watch(tontineRepositoryProvider);
  final transactionRepo = ref.watch(transactionRepositoryProvider);
  return ProcessMemberExitUseCase(tontineRepo, transactionRepo);
});

final getQueuePositionUseCaseProvider = Provider<GetQueuePositionUseCase>((ref) {
  print('getQueuePositionUseCaseProvider - Création.');
  final tontineRepo = ref.watch(tontineRepositoryProvider);
  return GetQueuePositionUseCase(tontineRepo);
});

// -----------------------------------------------------------------------------
// 💸 Providers pour les Use Cases de Transactions
// -----------------------------------------------------------------------------

final submitContributionUseCaseProvider = Provider<SubmitContributionUseCase>((ref) {
  print('submitContributionUseCaseProvider - Création.');
  final transactionRepo = ref.watch(transactionRepositoryProvider);
  final tontineRepo = ref.watch(tontineRepositoryProvider);
  return SubmitContributionUseCase(transactionRepo, tontineRepo);
});

final validatePaymentUseCaseProvider = Provider<ValidatePaymentUseCase>((ref) {
  print('validatePaymentUseCaseProvider - Création.');
  final transactionRepo = ref.watch(transactionRepositoryProvider);
  final tontineRepo = ref.watch(tontineRepositoryProvider);
  return ValidatePaymentUseCase(transactionRepo, tontineRepo);
});

// -----------------------------------------------------------------------------
// 🔄 Providers pour les Use Cases de Synchronisation
// -----------------------------------------------------------------------------

final processOutboxUseCaseProvider = Provider<ProcessOutboxUseCase>((ref) {
  print('processOutboxUseCaseProvider - Création.');
  final syncRepo = ref.watch(syncRepositoryProvider);
  return ProcessOutboxUseCase(syncRepo);
});

final retryFailedSyncUseCaseProvider = Provider<RetryFailedSyncUseCase>((ref) {
  print('retryFailedSyncUseCaseProvider - Création.');
  final syncRepo = ref.watch(syncRepositoryProvider);
  return RetryFailedSyncUseCase(syncRepo);
});
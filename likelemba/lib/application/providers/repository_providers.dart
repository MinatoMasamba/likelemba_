// lib/application/providers/repository_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../data/local/isar_service.dart';
import '../../data/local/daos/user_dao.dart';
import '../../data/local/daos/likelemba_dao.dart';
import '../../data/local/daos/transaction_dao.dart';
import '../../data/local/daos/outbox_dao.dart';

import '../../data/remote/auth_remote_data_source.dart';
import '../../data/remote/sync_remote_data_source.dart';
import '../../data/remote/tontine_remote_data_source.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/tontine_repository_impl.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../data/repositories/sync_repository_impl.dart';

import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/repositories/i_tontine_repository.dart';
import '../../domain/repositories/i_transaction_repository.dart';
import '../../domain/repositories/i_sync_repository.dart';

import '../../core/network/api_client.dart';
import '../../core/network/dio_client.dart';
import '../../core/network/connectivity_monitor.dart';

import '../../application/notifiers/auth_notifier.dart';
import 'isar_provider.dart';

// -----------------------------------------------------------------------------
// 🔐 Provider pour le token d'authentification
// -----------------------------------------------------------------------------

final authTokenProvider = StateProvider<String?>((ref) => null);

// -----------------------------------------------------------------------------
// 🗄️ Providers pour les DAOs (Data Access Objects)
// -----------------------------------------------------------------------------

final userDaoProvider = Provider<UserDao>((ref) {
  print('userDaoProvider - Création du UserDao.');
  final isarService = ref.watch(isarServiceProvider);
  return UserDao(isarService);
});

final likelembaDaoProvider = Provider<LikelembaDao>((ref) {
  print('likelembaDaoProvider - Création du LikelembaDao.');
  final isarService = ref.watch(isarServiceProvider);
  return LikelembaDao(isarService);
});

final transactionDaoProvider = Provider<TransactionDao>((ref) {
  print('transactionDaoProvider - Création du TransactionDao.');
  final isarService = ref.watch(isarServiceProvider);
  return TransactionDao(isarService);
});

final outboxDaoProvider = Provider<OutboxDao>((ref) {
  print('outboxDaoProvider - Création du OutboxDao.');
  final isarService = ref.watch(isarServiceProvider);
  return OutboxDao(isarService);
});

// -----------------------------------------------------------------------------
// 🌐 Providers pour les Remote Data Sources
// -----------------------------------------------------------------------------

final dioClientProvider = Provider<DioClient>((ref) {
  print('dioClientProvider - Création du DioClient.');
  const baseUrl = 'http://192.168.72.58:8000/api/';
  return DioClient(
    baseUrl: baseUrl,
    getToken: () => ref.read(authTokenProvider),
    onUnauthorized: () {
      print('dioClientProvider - 401 reçu, déconnexion automatique.');
      ref.read(authNotifierProvider.notifier).logout();
    },
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  print('apiClientProvider - Création de l\'ApiClient.');
  final dioClient = ref.watch(dioClientProvider);
  return ApiClient(dioClient: dioClient);
});

final connectivityMonitorProvider = Provider<ConnectivityMonitor>((ref) {
  print('connectivityMonitorProvider - Création du ConnectivityMonitor.');
  return ConnectivityMonitor();
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  print('authRemoteDataSourceProvider - Création de AuthRemoteDataSource.');
  final apiClient = ref.watch(apiClientProvider);
  return AuthRemoteDataSource(apiClient);
});

final syncRemoteDataSourceProvider = Provider<SyncRemoteDataSource>((ref) {
  print('syncRemoteDataSourceProvider - Création de SyncRemoteDataSource.');
  final apiClient = ref.watch(apiClientProvider);
  return SyncRemoteDataSource(apiClient);
});

final tontineRemoteDataSourceProvider = Provider<TontineRemoteDataSource>((ref) {
  print('tontineRemoteDataSourceProvider - Création de TontineRemoteDataSource.');
  final apiClient = ref.watch(apiClientProvider);
  return TontineRemoteDataSource(apiClient);
});

// -----------------------------------------------------------------------------
// 🧠 Providers pour les Repositories (Implémentations concrètes)
// -----------------------------------------------------------------------------

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  print('authRepositoryProvider - Création de AuthRepositoryImpl.');
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final userDao = ref.watch(userDaoProvider);
  final isarService = ref.watch(isarServiceProvider);
  return AuthRepositoryImpl(
    remoteDataSource: remoteDataSource,
    userDao: userDao,
    isarService: isarService,
  );
});

final tontineRepositoryProvider = Provider<ITontineRepository>((ref) {
  print('tontineRepositoryProvider - Création de TontineRepositoryImpl.');
  final likelembaDao = ref.watch(likelembaDaoProvider);
  final userDao = ref.watch(userDaoProvider);
  final outboxDao = ref.watch(outboxDaoProvider);
  final transactionDao = ref.watch(transactionDaoProvider);
  final tontineRemoteDataSource = ref.watch(tontineRemoteDataSourceProvider);
  return TontineRepositoryImpl(
    likelembaDao: likelembaDao,
    userDao: userDao,
    outboxDao: outboxDao,
    transactionDao: transactionDao,
    tontineRemoteDataSource: tontineRemoteDataSource,
  );
});

final transactionRepositoryProvider = Provider<ITransactionRepository>((ref) {
  print('transactionRepositoryProvider - Création de TransactionRepositoryImpl.');
  final transactionDao = ref.watch(transactionDaoProvider);
  final userDao = ref.watch(userDaoProvider);
  final likelembaDao = ref.watch(likelembaDaoProvider);
  final outboxDao = ref.watch(outboxDaoProvider);
  return TransactionRepositoryImpl(
    transactionDao: transactionDao,
    userDao: userDao,
    likelembaDao: likelembaDao,
    outboxDao: outboxDao,
  );
});

final syncRepositoryProvider = Provider<ISyncRepository>((ref) {
  print('syncRepositoryProvider - Création de SyncRepositoryImpl.');
  final remoteDataSource = ref.watch(syncRemoteDataSourceProvider);
  final outboxDao = ref.watch(outboxDaoProvider);
  final transactionDao = ref.watch(transactionDaoProvider);
  final likelembaDao = ref.watch(likelembaDaoProvider);
  final userDao = ref.watch(userDaoProvider);
  return SyncRepositoryImpl(
    remoteDataSource: remoteDataSource,
    outboxDao: outboxDao,
    transactionDao: transactionDao,
    likelembaDao: likelembaDao,
    userDao: userDao,
  );
});
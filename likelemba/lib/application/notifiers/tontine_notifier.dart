// lib/application/notifiers/tontine_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likelemba/application/notifiers/auth_notifier.dart';
import 'package:likelemba/application/providers/repository_providers.dart';
import 'package:logger/logger.dart';
import '../../domain/entities/likelemba_group.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/tontine/calculate_cycle_projection_use_case.dart';
import '../../domain/usecases/tontine/process_member_exit_use_case.dart';
import '../../domain/usecases/tontine/get_queue_position_use_case.dart';
import '../providers/use_case_providers.dart';

/// État de la tontine
class TontineState {
  final List<LikelembaGroup> activeGroups;
  final LikelembaGroup? selectedGroup;
  final bool isLoading;
  final bool isCritical; // Fonds de réserve sous le seuil critique
  final String? errorMessage;
  final Map<String, FundProjection> projections;
  final List<LikelembaGroup> managedGroups; // <-- ajouté

  const TontineState({
    this.activeGroups = const [],
    this.selectedGroup,
    this.isLoading = false,
    this.isCritical = false,
    this.errorMessage,
    this.projections = const {},
    this.managedGroups = const [], // <-- ajouté
  });

  TontineState copyWith({
    List<LikelembaGroup>? activeGroups,
    LikelembaGroup? selectedGroup,
    bool? isLoading,
    bool? isCritical,
    String? errorMessage,
    Map<String, FundProjection>? projections,
    List<LikelembaGroup>? managedGroups, // <-- ajouté
  }) {
    return TontineState(
      activeGroups: activeGroups ?? this.activeGroups,
      selectedGroup: selectedGroup ?? this.selectedGroup,
      isLoading: isLoading ?? this.isLoading,
      isCritical: isCritical ?? this.isCritical,
      errorMessage: errorMessage ?? this.errorMessage,
      projections: projections ?? this.projections,
      managedGroups: managedGroups ?? this.managedGroups, // <-- ajouté
    );
  }
}

/// Projection du fonds de réserve pour un groupe
class FundProjection {
  final double currentFund;
  final double projectedFund30d;
  final double projectedFund90d;
  final RiskLevel riskLevel;

  const FundProjection({
    required this.currentFund,
    required this.projectedFund30d,
    required this.projectedFund90d,
    required this.riskLevel,
  });
}

enum RiskLevel { low, medium, high, critical }

/// 🌀 Notifier gérant l'état des groupes Likelemba et les calculs EDO.
class TontineNotifier extends AsyncNotifier<TontineState> {
  final Logger _logger = Logger();

  @override
  Future<TontineState> build() async {
    const method = 'TontineNotifier.build';
    _logger.i('$method - Initialisation.');

    final authState = await ref.watch(authNotifierProvider.future);
    final user = authState.currentUser;
    if (user == null) {
      _logger.w('$method - Aucun utilisateur connecté.');
      return const TontineState();
    }

    if (user.role == UserRole.admin) {
      _logger.i('$method - Admin (id=${user.id}), chargement depuis le serveur...');
      final remoteResult = await ref.read(tontineRepositoryProvider).getGroupsManagedBy(user.id);
      if (remoteResult.isRight()) {
        final groups = remoteResult.fold((l) => <LikelembaGroup>[], (r) => r);
        _logger.i('$method - ${groups.length} groupes reçus du serveur.');
        return TontineState(managedGroups: groups);
      }
      _logger.w('$method - Serveur indisponible, lecture Isar...');
      final localResult = await ref.read(tontineRepositoryProvider).getLocalGroupsManagedBy(user.id);
      final groups = localResult.fold((l) => <LikelembaGroup>[], (r) => r);
      _logger.i('$method - ${groups.length} groupes locaux.');
      return TontineState(managedGroups: groups);
    } else {
      _logger.i('$method - Membre (id=${user.id}), lecture des groupes actifs...');
      final result = await ref.read(tontineRepositoryProvider).watchUserGroups(user.id).first;
      return result.fold(
        (failure) {
          _logger.e('$method - Erreur stream: ${failure.message}');
          return const TontineState();
        },
        (groups) {
          _logger.i('$method - ${groups.length} groupe(s) actif(s).');
          return TontineState(
            activeGroups: groups,
            selectedGroup: groups.isNotEmpty ? groups.first : null,
          );
        },
      );
    }
  }

  /// Sélectionne un groupe et calcule sa projection EDO.
  // lib/application/notifiers/tontine_notifier.dart

Future<void> selectGroup(String groupId) async {
  state = const AsyncValue.loading();

  // Conversion String -> int pour le repository
  final int id = int.tryParse(groupId) ?? 0;
  final groupResult = await ref.read(tontineRepositoryProvider).getGroupById(id);

  groupResult.fold(
    (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
    (group) async {
      if (group == null) {
        state = AsyncValue.error('Groupe introuvable', StackTrace.current);
        return;
      }

      // Projection EDO (le use case accepte un String)
      final useCase = ref.read(calculateCycleProjectionUseCaseProvider);
      final projectionResult = await useCase.call(groupId);

      projectionResult.fold(
        (failure) => state = AsyncValue.data(TontineState(selectedGroup: group, isCritical: false)),
        (projection) {
          final isCritical = _evaluateRisk(group, projection);
          state = AsyncValue.data(TontineState(
            selectedGroup: group,
            isCritical: isCritical,
            projections: {
              groupId: FundProjection(
                currentFund: group.currentReserveFund,
                projectedFund30d: projection.isNotEmpty ? projection.last.fund : 0,
                projectedFund90d: projection.isNotEmpty ? projection.last.fund : 0,
                riskLevel: isCritical ? RiskLevel.critical : RiskLevel.low,
              ),
            },
          ));
        },
      );
    },
  );
}

  // lib/application/notifiers/tontine_notifier.dart
// Ajouter la méthode createGroup dans la classe TontineNotifier

  Future<void> createGroup({
    required String name,
    String? description,
    required double contributionAmount,
    required double securityFeeRate,
    required double penaltyRateInitial,
    required int cycleDurationDays,
  }) async {
    state = const AsyncValue.loading();
    _logger.i('TontineNotifier.createGroup - Début');

    // Récupérer l'ID admin depuis l'état d'authentification
    final authState = ref.read(authNotifierProvider).value;
    final adminUserId = authState?.currentUser?.id ?? 0;

    final useCase = ref.read(createGroupUseCaseProvider);
    final result = await useCase.call(
      name: name,
      description: description,
      contributionAmount: contributionAmount,
      securityFeeRate: securityFeeRate,
      penaltyRateInitial: penaltyRateInitial,
      cycleDurationDays: cycleDurationDays,
      adminUserId: adminUserId,
    );

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (group) {
        _logger.i('TontineNotifier.createGroup - Groupe créé avec succès');
        // Recharger la liste des groupes administrés
        loadManagedGroups();
        final currentGroups = state.value?.managedGroups ?? [];
        return AsyncValue.data(TontineState(
          managedGroups: [...currentGroups, group],
          selectedGroup: group,
        ));
      },
    );
  }

// Assurez-vous que TontineState possède un champ managedGroups et que le constructeur
// et copyWith le prennent en compte. Exemple :
// class TontineState {
//   final List<LikelembaGroup> managedGroups;
//   ...
// }

  /// Traite la sortie d'un membre.
  Future<void> processMemberExit(String userId) async {
    final group = state.value?.selectedGroup;
    if (group == null) return;

    state = const AsyncValue.loading();

    final useCase = ref.read(processMemberExitUseCaseProvider);
    final result = await useCase.call(group.id.toString(), userId);

    result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
      },
      (refundAmount) async {
        _logger.i('TontineNotifier.processMemberExit - Remboursement: $refundAmount');
        await selectGroup(group.id.toString());
      },
    );
  }

  /// Charge les groupes actifs d'un membre et sélectionne le premier.
  Future<void> loadMemberGroups(int userId) async {
    const method = 'loadMemberGroups';
    _logger.i('$method - Chargement des groupes pour membre $userId');
    try {
      final result = await ref
          .read(tontineRepositoryProvider)
          .watchUserGroups(userId)
          .first;

      result.fold(
        (failure) => _logger.e('$method - Erreur: ${failure.message}'),
        (groups) {
          _logger.i('$method - ${groups.length} groupe(s) trouvé(s)');
          state = AsyncValue.data(
            state.value?.copyWith(activeGroups: groups) ??
                TontineState(activeGroups: groups),
          );
          if (groups.isNotEmpty) {
            selectGroup(groups.first.id.toString());
          }
        },
      );
    } catch (e, stack) {
      _logger.e('$method - Exception: $e', error: e, stackTrace: stack);
    }
  }

  bool _evaluateRisk(LikelembaGroup group, List<dynamic> projection) {
    // Logique EDO : le fonds est critique s'il descend sous 20% de la cagnotte
    final threshold = group.netJackpot * 0.2;
    return group.currentReserveFund < threshold;
  }

  Future<void> lockGroup(int id) async {
    _logger.i('TontineNotifier.lockGroup - Verrouillage/déverrouillage groupe $id');
    final authState = ref.read(authNotifierProvider).value;
    final adminUserId = authState?.currentUser?.id ?? 0;

    final result = await ref
        .read(tontineRepositoryProvider)
        .lockGroupSettings(id, adminUserId);

    result.fold(
      (failure) {
        _logger.e('lockGroup - Erreur: ${failure.message}');
        state = AsyncValue.error(failure.message, StackTrace.current);
      },
      (_) async {
        _logger.i('lockGroup - Succès, rechargement du groupe $id');
        await selectGroup(id.toString());
      },
    );
  }

  // lib/application/notifiers/tontine_notifier.dart

Future<void> loadManagedGroups() async {
  const method = 'loadManagedGroups';
  _logger.i('$method - Début');

  try {
    final authState = ref.read(authNotifierProvider).value;
    final adminUserId = authState?.currentUser?.id;
    
    _logger.i('$method - adminUserId: $adminUserId');
    
    if (adminUserId == null) {
      _logger.w('$method - Aucun adminUserId trouvé');
      return;
    }

    _logger.i('$method - Appel au repository...');
    final result = await ref.read(tontineRepositoryProvider).getGroupsManagedBy(adminUserId);
    
    result.fold(
      (failure) {
        _logger.e('$method - Erreur: ${failure.message}');
      },
      (groups) {
        _logger.i('$method - ${groups.length} groupes récupérés');
        state = AsyncValue.data(
          state.value?.copyWith(managedGroups: groups) ?? TontineState(managedGroups: groups),
        );
      },
    );
  } catch (e, stack) {
    _logger.e('$method - Exception: $e', error: e, stackTrace: stack);
  }
}
}

final tontineNotifierProvider = AsyncNotifierProvider<TontineNotifier, TontineState>(TontineNotifier.new);

/// Charge les membres du groupe actuellement sélectionné depuis la base locale.
final groupMembersProvider = FutureProvider<List<User>>((ref) async {
  final group = ref.watch(tontineNotifierProvider).value?.selectedGroup;
  if (group == null || group.memberIds.isEmpty) return [];

  final userDao = ref.read(userDaoProvider);
  final users = <User>[];

  for (final memberId in group.memberIds) {
    final model = await userDao.getById(memberId);
    if (model != null) {
      users.add(User(
        id: model.id,
        name: model.name,
        phoneNumber: model.phoneNumber,
        role: UserRole.values[model.role.index],
        status: UserStatus.values[model.status.index],
        trustScore: model.trustScore,
        totalContribution: model.totalContribution,
        isBiometricEnabled: model.isBiometricEnabled,
      ));
    }
  }

  return users;
});

/// Membre avec sa vraie progression de cotisation (ratio versé / attendu).
class MemberWithProgress {
  final User member;
  final double contributionProgress;

  const MemberWithProgress({required this.member, required this.contributionProgress});
}

/// Charge les membres du groupe sélectionné avec leur vraie progression calculée
/// depuis les transactions validées dans Isar.
final groupMembersWithProgressProvider = FutureProvider<List<MemberWithProgress>>((ref) async {
  final group = ref.watch(tontineNotifierProvider).value?.selectedGroup;
  if (group == null || group.memberIds.isEmpty) return [];

  final userDao = ref.read(userDaoProvider);
  final transactionRepo = ref.read(transactionRepositoryProvider);

  // Cotisation attendue = montant journalier × jours écoulés (min 1 jour pour éviter ÷0)
  final elapsedDays = group.elapsedDays > 0 ? group.elapsedDays : 1;
  final expectedTotal = group.dailyContribution * elapsedDays;

  final List<MemberWithProgress> results = [];
  for (final memberId in group.memberIds) {
    final model = await userDao.getById(memberId);
    if (model == null) continue;

    final user = User(
      id: model.id,
      name: model.name,
      phoneNumber: model.phoneNumber,
      role: UserRole.values[model.role.index],
      status: UserStatus.values[model.status.index],
      trustScore: model.trustScore,
      totalContribution: model.totalContribution,
      isBiometricEnabled: model.isBiometricEnabled,
    );

    final contribResult = await transactionRepo.getUserTotalContribution(group.id, memberId);
    final totalPaid = contribResult.fold((l) => 0.0, (r) => r);
    final progress = (totalPaid / expectedTotal).clamp(0.0, 1.0);

    results.add(MemberWithProgress(member: user, contributionProgress: progress));
  }
  return results;
});
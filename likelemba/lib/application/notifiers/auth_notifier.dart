// lib/application/notifiers/auth_notifier.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likelemba/application/providers/repository_providers.dart';
import 'package:likelemba/core/error/failures.dart';
import 'package:likelemba/data/repositories/auth_repository_impl.dart';
import 'package:logger/logger.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/auth/login_use_case.dart';
import '../../domain/usecases/auth/register_biometric_use_case.dart';
import '../providers/use_case_providers.dart';

/// État d'authentification
class AuthState {
  final User? currentUser;
  final bool isLoading;
  final String? errorMessage;
  final bool isBiometricEnabled;

  const AuthState({
    this.currentUser,
    this.isLoading = false,
    this.errorMessage,
    this.isBiometricEnabled = false,
  });

  bool get isAuthenticated => currentUser != null;

  AuthState copyWith({
    User? currentUser,
    bool? isLoading,
    String? errorMessage,
    bool? isBiometricEnabled,
  }) {
    return AuthState(
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
    );
  }

  AuthState clearError() => copyWith(errorMessage: null);
}

/// 🔐 Notifier gérant l'état d'authentification et la session utilisateur.
class AuthNotifier extends AsyncNotifier<AuthState> {
  final Logger _logger = Logger();

  @override
  Future<AuthState> build() async {
    const method = 'AuthNotifier.build';
    _logger.i('$method - Initialisation de la session.');

    // Récupération de l'utilisateur courant depuis le repository
    final result = await ref.read(authRepositoryProvider).getCurrentUser();

    return result.fold(
      (failure) {
        _logger.e('$method - Échec récupération utilisateur: ${failure.message}');
        return const AuthState(currentUser: null);
      },
      (user) {
        _logger.i('$method - Utilisateur connecté: ${user?.name ?? "Aucun"}');
        return AuthState(currentUser: user, isBiometricEnabled: user?.isBiometricEnabled ?? false);
      },
    );
  }


  


  /// Demande un code OTP pour le numéro spécifié.
  Future<void> requestOtp(String phoneNumber) async {
    state = const AsyncValue.loading();
    final result = await ref.read(authRepositoryProvider).requestOtp(phoneNumber);
    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (_) => const AsyncValue.data(AuthState()),
    );
  }

  /// Vérifie l'OTP et connecte l'utilisateur.
  Future<void> verifyOtp(String phoneNumber, String code) async {
    state = const AsyncValue.loading();
    final useCase = ref.read(loginUseCaseProvider);
    final result = await useCase.call(phoneNumber, code);

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (user) => AsyncValue.data(AuthState(
        currentUser: user,
        isBiometricEnabled: user.isBiometricEnabled,
      )),
    );
  }

  /// Active ou désactive l'authentification biométrique.
  Future<void> toggleBiometrics(bool enabled) async {
    final useCase = ref.read(registerBiometricUseCaseProvider);
    final result = await useCase.call(enabled);

    result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
      },
      (_) {
        final current = state.value ?? const AuthState();
        state = AsyncValue.data(current.copyWith(isBiometricEnabled: enabled));
      },
    );
  }

  /// Déconnecte l'utilisateur.
  Future<void> logout() async {
    state = const AsyncValue.loading();
    final result = await ref.read(authRepositoryProvider).logout();

    state = result.fold(
      (failure) => AsyncValue.error(failure.message, StackTrace.current),
      (_) => const AsyncValue.data(AuthState(currentUser: null)),
    );
  }

// lib/application/notifiers/auth_notifier.dart

// lib/application/notifiers/auth_notifier.dart

Future<void> login({required String phone, required String pin}) async {
  const method = 'login';
  _logger.i('$method - Tentative de connexion pour $phone');

  state = const AsyncValue.loading();

  final useCase = ref.read(loginUseCaseProvider);
  final result = await useCase.call(phone, pin);

  state = result.fold(
    (failure) {
      _logger.e('$method - Échec: ${failure.message}');
      String userMessage;
      if (failure is ValidationFailure) {
        userMessage = failure.message;
      } else if (failure is ConnectionFailure) {
        userMessage = 'Pas de connexion internet. Vérifiez votre réseau.';
      } else if (failure is AuthenticationFailure) {
        userMessage = 'Téléphone ou code PIN incorrect.';
      } else {
        userMessage = 'Erreur lors de la connexion.';
      }
      return AsyncValue.error(userMessage, StackTrace.current);
    },
    (user) {
      _logger.i('$method - Connexion réussie pour ${user.name}');

      // ✅ Sauvegarder le token JWT dans le StateProvider
      final authRepo = ref.read(authRepositoryProvider);
      if (authRepo is AuthRepositoryImpl) {
        final token = authRepo.currentAccessToken;
        if (token != null) {
          ref.read(authTokenProvider.notifier).state = token;
          _logger.i('$method - Token JWT sauvegardé dans le provider');
        } else {
          _logger.w('$method - Aucun token disponible après connexion');
        }
      }

      return AsyncValue.data(AuthState(
        currentUser: user,
        isBiometricEnabled: user.isBiometricEnabled,
      ));
    },
  );
}

// Dans la classe AuthNotifier
Future<void> createAccount({
  required String name,
  required String phone,
  required String pin,
  required UserRole role,
}) async {
  const method = 'createAccount';
  _logger.i('$method - Début création compte pour $phone avec rôle ${role.name}');

  state = const AsyncValue.loading();

  final useCase = ref.read(registerUserUseCaseProvider);
  final result = await useCase.call(
    name: name,
    phoneNumber: phone,
    pin: pin,
    role: role,
  );

  state = result.fold(
    (failure) {
      _logger.e('$method - Échec: ${failure.message}');
      
      String userMessage;
      if (failure is ValidationFailure) {
        userMessage = failure.message;
      } else if (failure is ConnectionFailure) {
        userMessage = 'Pas de connexion internet. Vérifiez votre réseau.';
      } else if (failure is ServerFailure) {
        userMessage = 'Erreur serveur. Réessayez plus tard.';
      } else {
        userMessage = 'Erreur inattendue lors de la création du compte.';
      }
      
      return AsyncValue.error(userMessage, StackTrace.current);
    },
    (user) {
      _logger.i('$method - Compte créé avec succès pour ${user.name}');
      return AsyncValue.data(AuthState(
        currentUser: user,
        isBiometricEnabled: user.isBiometricEnabled,
      ));
    },
  );
}
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
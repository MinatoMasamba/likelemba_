// lib/presentation/features/auth/screens/check_role_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../../../application/notifiers/auth_notifier.dart';
import '../../../../domain/entities/user.dart';
import '../../tontine/screens/dashboard_screen.dart';
import '../../tontine/screens/admin_dashboard_screen.dart';
import 'login_screen.dart'; // ⬅️ Ajoutez cet import
import '../../../shared/widgets/loading_indicator.dart';

class CheckRoleScreen extends ConsumerStatefulWidget {
  const CheckRoleScreen({super.key});

  @override
  ConsumerState<CheckRoleScreen> createState() => _CheckRoleScreenState();
}

class _CheckRoleScreenState extends ConsumerState<CheckRoleScreen> {
  static const String tag = 'CheckRoleScreen';
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _logger.i('$tag.initState - Vérification du rôle utilisateur.');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: GlassLoadingIndicator(message: 'Vérification du profil...'),
        ),
      );
    }

    if (authState.hasError || authState.value?.currentUser == null) {
      _logger.w('$tag.build - Aucun utilisateur connecté, redirection vers login.');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()), // ⬅️ Navigation directe
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = authState.value!.currentUser!;
    _logger.i('$tag.build - Utilisateur ${user.name} avec rôle ${user.role.name}');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateBasedOnRole(user.role);
    });

    return const Scaffold(
      body: Center(
        child: GlassLoadingIndicator(message: 'Chargement de votre espace...'),
      ),
    );
  }

  void _navigateBasedOnRole(UserRole role) {
    const method = '_navigateBasedOnRole';
    _logger.i('$tag.$method - Navigation pour rôle: ${role.name}');

    switch (role) {
      case UserRole.admin:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
        break;
      case UserRole.member:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
        break;
    }
  }
}
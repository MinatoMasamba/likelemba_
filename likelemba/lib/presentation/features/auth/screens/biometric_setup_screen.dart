// lib/presentation/features/auth/screens/biometric_setup_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likelemba/presentation/features/auth/screens/check_role_screen.dart';
import 'package:logger/logger.dart';
import '../../../../application/notifiers/auth_notifier.dart';
import '../../../shared/animations/fade_slide_transition.dart';
import '../../../shared/widgets/liquid_glass_card.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/error_snackbar.dart';

/// Écran d'activation de la biométrie – Sécurité renforcée du Likelemba.
class BiometricSetupScreen extends ConsumerStatefulWidget {
  const BiometricSetupScreen({super.key});

  @override
  ConsumerState<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends ConsumerState<BiometricSetupScreen>
    with SingleTickerProviderStateMixin {
  static const String tag = 'BiometricSetupScreen';
  final Logger _logger = Logger();
  late AnimationController _rippleController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _logger.i('$tag.initState - Écran configuration biométrie.');
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  Future<void> _enableBiometrics() async {
    const method = '_enableBiometrics';
    setState(() => _isLoading = true);
    _logger.i('$tag.$method - Activation biométrie.');

    try {
      await ref.read(authNotifierProvider.notifier).toggleBiometrics(true);
      _logger.i('$tag.$method - Biométrie activée.');
      _navigateToDashboard();
    } catch (e, stack) {
      _logger.e('$tag.$method - Échec: $e', error: e, stackTrace: stack);
      setState(() => _isLoading = false);
      ErrorSnackbar.show(context, 'Impossible d\'activer la biométrie. Vous pourrez le faire plus tard.');
      _navigateToDashboard(); // Fallback
    }
  }

  void _skipBiometrics() {
    _logger.i('$tag._skipBiometrics - Utilisateur a ignoré la biométrie.');
    _navigateToDashboard();
  }

  void _navigateToDashboard() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const CheckRoleScreen()),
    );
    _logger.i('$tag._navigateToDashboard - Redirection dashboard.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A2540), Color(0xFF001220)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: StaggeredList(
                baseDelayMs: 200,
                delayIncrementMs: 100,
                children: [
                  AnimatedBuilder(
                    animation: _rippleController,
                    builder: (context, child) {
                      return Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF00C9A7).withOpacity(0.3),
                              blurRadius: 30 * _rippleController.value,
                              spreadRadius: 10 * _rippleController.value,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.fingerprint,
                          size: 80,
                          color: Color(0xFF00C9A7),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Sécurité renforcée',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Activez la biométrie pour protéger vos fonds.\n'
                    'Votre empreinte ou votre visage sera requis pour valider les retraits.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 32),
                  LiquidGlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        GlassButton(
                          label: 'Activer la biométrie',
                          icon: Icons.fingerprint,
                          isLoading: _isLoading,
                          impact: HapticImpact.heavy,
                          onPressed: _enableBiometrics,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _skipBiometrics,
                          child: const Text(
                            'Peut-être plus tard',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
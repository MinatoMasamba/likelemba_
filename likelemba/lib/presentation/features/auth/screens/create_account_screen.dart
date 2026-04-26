// lib/presentation/features/auth/screens/create_account_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likelemba/presentation/features/auth/screens/auth_text_field.dart';
import 'package:logger/logger.dart';
import '../../../../application/notifiers/auth_notifier.dart';
import '../../../../domain/entities/user.dart'; // Pour UserRole
import '../../../shared/animations/fade_slide_transition.dart';
import '../../../shared/widgets/liquid_glass_card.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/error_snackbar.dart';

import 'biometric_setup_screen.dart';

/// Écran de création de compte – Adhésion à la communauté Likelemba.
class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  static const String tag = 'CreateAccountScreen';
  final Logger _logger = Logger();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  
  bool _isLoading = false;
  UserRole _selectedRole = UserRole.member; // Par défaut Participant

  @override
  void initState() {
    super.initState();
    _logger.i('$tag.initState - Écran de création de compte initialisé.');
  }

  Future<void> _createAccount() async {
    const method = '_createAccount';
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();

    // Validations locales
    if (name.isEmpty) {
      ErrorSnackbar.show(context, 'Veuillez entrer votre nom.');
      return;
    }
    if (phone.length < 10) {
      ErrorSnackbar.show(context, 'Numéro de téléphone invalide. Format attendu: +243XXXXXXXXX');
      return;
    }
    if (pin.length < 4) {
      ErrorSnackbar.show(context, 'Le code PIN doit contenir au moins 4 chiffres.');
      return;
    }

    setState(() => _isLoading = true);
    _logger.i('$tag.$method - Création compte pour $name ($phone) avec rôle ${_selectedRole.name}');

    try {
      // Passage du rôle sélectionné
      await ref.read(authNotifierProvider.notifier).createAccount(
        name: name,
        phone: phone,
        pin: pin,
        role: _selectedRole,
      );
      
      // Vérifier l'état après l'appel
      final authState = ref.read(authNotifierProvider);
      if (authState.hasError) {
        setState(() => _isLoading = false);
        ErrorSnackbar.show(context, authState.error.toString());
        return;
      }
      
      _logger.i('$tag.$method - Compte créé avec succès.');
      _navigateToBiometricSetup();
    } catch (e, stack) {
      _logger.e('$tag.$method - Erreur: $e', error: e, stackTrace: stack);
      setState(() => _isLoading = false);
      ErrorSnackbar.show(context, 'Erreur lors de la création du compte: ${e.toString()}');
    }
  }

  void _navigateToBiometricSetup() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const BiometricSetupScreen()),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
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
                baseDelayMs: 100,
                delayIncrementMs: 80,
                children: [
                  const Icon(Icons.person_add, size: 50, color: Color(0xFF00C9A7)),
                  const SizedBox(height: 16),
                  const Text(
                    'Rejoignez la communauté',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 32),
                  LiquidGlassCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        AuthTextField(
                          controller: _nameController,
                          label: 'Nom complet',
                          prefix: const Icon(Icons.person, size: 20, color: Colors.white54),
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          controller: _phoneController,
                          label: 'Numéro de téléphone',
                          prefix: const Text('+243'),
                          keyboardType: TextInputType.phone,
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 16),
                        AuthTextField(
                          controller: _pinController,
                          label: 'Code PIN secret',
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: 16),
                        // Sélecteur de rôle
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Column(
                            children: [
                              RadioListTile<UserRole>(
                                title: const Text('Participant', style: TextStyle(color: Colors.white)),
                                subtitle: const Text('Rejoindre des groupes existants', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                value: UserRole.member,
                                groupValue: _selectedRole,
                                onChanged: _isLoading ? null : (value) => setState(() => _selectedRole = value!),
                                activeColor: const Color(0xFF00C9A7),
                              ),
                              RadioListTile<UserRole>(
                                title: const Text('Administrateur', style: TextStyle(color: Colors.white)),
                                subtitle: const Text('Créer et gérer des groupes', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                value: UserRole.admin,
                                groupValue: _selectedRole,
                                onChanged: _isLoading ? null : (value) => setState(() => _selectedRole = value!),
                                activeColor: const Color(0xFF00C9A7),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        GlassButton(
                          label: 'Créer mon compte',
                          icon: Icons.arrow_forward,
                          isLoading: _isLoading,
                          impact: HapticImpact.heavy,
                          onPressed: _createAccount,
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
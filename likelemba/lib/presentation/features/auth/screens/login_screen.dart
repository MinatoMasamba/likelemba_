// lib/presentation/features/auth/screens/login_screen.dart

import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../../../application/notifiers/auth_notifier.dart';
import '../../../shared/widgets/error_snackbar.dart';
import 'check_role_screen.dart';
import 'create_account_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const String tag = 'LoginScreen';
  final Logger _logger = Logger();

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();

    // Validation locale
    if (phone.isEmpty) {
      ErrorSnackbar.show(context, 'Veuillez entrer votre numéro de téléphone.');
      return;
    }
    if (pin.isEmpty) {
      ErrorSnackbar.show(context, 'Veuillez entrer votre code PIN.');
      return;
    }

    setState(() => _isLoading = true);
    _logger.i('$tag._handleLogin - Tentative de connexion pour $phone');

    try {
      // ✅ Appel au notifier qui déclenche tout le flux réseau
      await ref.read(authNotifierProvider.notifier).login(phone: phone, pin: pin);

      // Vérifier l'état après l'appel
      final authState = ref.read(authNotifierProvider);
      
      if (authState.hasError) {
        setState(() => _isLoading = false);
        ErrorSnackbar.show(context, authState.error.toString());
        return;
      }

      if (authState.value?.currentUser != null) {
        _logger.i('$tag._handleLogin - Connexion réussie');
        // Redirection vers CheckRoleScreen qui décidera du dashboard
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CheckRoleScreen()),
        );
      } else {
        setState(() => _isLoading = false);
        ErrorSnackbar.show(context, 'Échec de connexion. Vérifiez vos identifiants.');
      }
    } catch (e, stack) {
      _logger.e('$tag._handleLogin - Erreur: $e', error: e, stackTrace: stack);
      setState(() => _isLoading = false);
      ErrorSnackbar.show(context, 'Erreur lors de la connexion. Vérifiez votre réseau.');
    }
  }

  void _navigateToCreateAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateAccountScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A2980),
              Color(0xFF26D0CE),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Likelemba',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sécurité & Solidarité',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 40),

                // Carte Liquid Glass
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      padding: const EdgeInsets.all(32.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildGlassTextField(
                            controller: _phoneController,
                            hint: 'Téléphone',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 20),
                          _buildGlassTextField(
                            controller: _pinController,
                            hint: 'Code PIN',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            keyboardType: TextInputType.number,
                            enabled: !_isLoading,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: _isLoading ? null : (value) {
                                        setState(() => _rememberMe = value!);
                                      },
                                      side: BorderSide(color: Colors.white.withOpacity(0.5)),
                                      fillColor: WidgetStateProperty.all(Colors.white.withOpacity(0.2)),
                                      checkColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Se souvenir',
                                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.2),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: Colors.white.withOpacity(0.5)),
                                ),
                              ),
                              onPressed: _isLoading ? null : _handleLogin,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text('Se Connecter',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(height: 20),
                          RichText(
                            text: TextSpan(
                              text: "Pas de compte ? ",
                              style: TextStyle(color: Colors.white.withOpacity(0.7)),
                              children: [
                                TextSpan(
                                  text: "Inscrivez-vous",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = _isLoading ? null : _navigateToCreateAccount,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Column(
                  children: [
                    IconButton(
                      onPressed: _isLoading ? null : () {},
                      icon: const Icon(Icons.fingerprint, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: _isLoading ? null : () {},
                      child: Text(
                        'Politique de confidentialité & Conditions',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: keyboardType,
        enabled: enabled,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
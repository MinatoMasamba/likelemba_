// lib/presentation/features/tontine/screens/join_group_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likelemba/core/app_colors.dart';
import 'package:likelemba/core/theme/text_styles.dart';
import 'package:likelemba/presentation/shared/widgets/glass_button.dart';
import 'package:likelemba/presentation/shared/widgets/liquid_glass_card.dart';
import 'package:likelemba/presentation/shared/widgets/error_snackbar.dart';
import 'package:logger/logger.dart';

import '../../../../application/notifiers/auth_notifier.dart';
import '../../../../application/notifiers/tontine_notifier.dart';
import '../../../../application/providers/repository_providers.dart';
import '../../../../data/remote/tontine_remote_data_source.dart';

/// Écran permettant à un membre de rejoindre un groupe via son code d'invitation.
class JoinGroupScreen extends ConsumerStatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  static const String tag = 'JoinGroupScreen';
  final Logger _logger = Logger();
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();
    _logger.i('$tag._handleJoin - Code: ${_codeController.text.trim()}');

    try {
      final code = _codeController.text.trim().toUpperCase();
      final dataSource = ref.read(tontineRemoteDataSourceProvider);

      // Appel API pour rejoindre le groupe via le code d'invitation
      await dataSource.joinGroupByInviteCode(code);

      // Recharger les groupes du membre
      final authState = ref.read(authNotifierProvider).value;
      final userId = authState?.currentUser?.id;
      if (userId != null) {
        await ref.read(tontineNotifierProvider.notifier).loadMemberGroups(userId);
      }

      if (!mounted) return;
      HapticFeedback.heavyImpact();
      _showSuccessDialog(code);
    } catch (e, stack) {
      _logger.e('$tag._handleJoin - Erreur: $e', error: e, stackTrace: stack);
      if (mounted) {
        ErrorSnackbar.show(
          context,
          e.toString().contains('ValidationException')
              ? 'Code invalide ou groupe introuvable.'
              : 'Impossible de rejoindre le groupe. Vérifiez votre connexion.',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String code) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: LiquidGlassCard(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded,
                  size: 60, color: AppColors.solvencyGreen),
              const SizedBox(height: 16),
              Text(
                'Bienvenue dans le groupe !',
                style: AppTextStyles.sectionTitle(isDark: true),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Vous avez rejoint un Likelemba avec le code $code.',
                style: AppTextStyles.bodyMedium(isDark: true),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              GlassButton(
                label: 'Voir mon groupe',
                icon: Icons.groups_rounded,
                impact: HapticImpact.medium,
                onPressed: () {
                  Navigator.pop(context); // ferme le dialog
                  Navigator.pop(context); // retourne au dashboard
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Rejoindre un Likelemba',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // ── Illustration ──────────────────────────────────────
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accentTeal.withOpacity(0.15),
                        border: Border.all(
                          color: AppColors.accentTeal.withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.group_add_rounded,
                        size: 50,
                        color: AppColors.accentTeal,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Titre explicatif ──────────────────────────────────
                  Text(
                    'Entrez votre code d\'invitation',
                    style: AppTextStyles.sectionTitle(isDark: true),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Demandez le code à l\'administrateur de votre groupe Likelemba.',
                    style: AppTextStyles.bodyMedium(isDark: true),
                  ),

                  const SizedBox(height: 32),

                  // ── Champ code ────────────────────────────────────────
                  LiquidGlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Code d\'invitation',
                          style: AppTextStyles.inputLabel(isDark: true),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _codeController,
                          textCapitalization: TextCapitalization.characters,
                          keyboardType: TextInputType.text,
                          maxLength: 12,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: 'ABC-1234',
                            hintStyle: TextStyle(
                              color: Colors.white.withOpacity(0.3),
                              letterSpacing: 4,
                              fontSize: 22,
                            ),
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: AppColors.accentTeal.withOpacity(0.3),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: AppColors.accentTeal,
                                width: 2,
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppColors.riskRed),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.05),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Veuillez entrer le code d\'invitation.';
                            }
                            if (value.trim().length < 4) {
                              return 'Le code doit contenir au moins 4 caractères.';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Bouton rejoindre ──────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: GlassButton(
                      label: _isLoading ? 'Connexion au groupe...' : 'REJOINDRE LE GROUPE',
                      icon: _isLoading ? null : Icons.groups_rounded,
                      isLoading: _isLoading,
                      impact: HapticImpact.heavy,
                      onPressed: _isLoading ? () {} : _handleJoin,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Info ──────────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.solidarityGold.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.solidarityGold.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.solidarityGold, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'En rejoignant ce groupe, vous acceptez de cotiser '
                            'régulièrement selon les paramètres définis par '
                            'l\'administrateur.',
                            style: TextStyle(
                              color: AppColors.solidarityGold.withOpacity(0.9),
                              fontSize: 12,
                            ),
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

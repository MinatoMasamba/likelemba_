// lib/presentation/features/tontine/screens/create_tontine_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likelemba/core/app_colors.dart';
import 'package:logger/logger.dart';
import '../../../../application/notifiers/tontine_notifier.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../shared/widgets/liquid_glass_card.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/error_snackbar.dart';

/// Écran de création d'une nouvelle tontine (Likelemba).
class CreateTontineScreen extends ConsumerStatefulWidget {
  const CreateTontineScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateTontineScreen> createState() => _CreateTontineScreenState();
}

class _CreateTontineScreenState extends ConsumerState<CreateTontineScreen> {
  static const String tag = 'CreateTontineScreen';
  final Logger _logger = Logger();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contributionController = TextEditingController(text: '5000');
  final _securityFeeRateController = TextEditingController(text: '0.05');
  final _penaltyController = TextEditingController(text: '0.20');
  final _cycleDaysController = TextEditingController(text: '30');
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    _logger.i('$tag._submit - Création de tontine');
    try {
      await ref.read(tontineNotifierProvider.notifier).createGroup(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        contributionAmount: double.parse(_contributionController.text),
        securityFeeRate: double.parse(_securityFeeRateController.text),
        penaltyRateInitial: double.parse(_penaltyController.text),
        cycleDurationDays: int.parse(_cycleDaysController.text),
      );
      Navigator.pop(context, true);
    } catch (e, stack) {
      _logger.e('$tag._submit - Erreur: $e', error: e, stackTrace: stack);
      ErrorSnackbar.show(context, 'Erreur lors de la création de la tontine.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Nouvelle Tontine'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        // Fond avec dégradé "Liquid Glass"
        decoration: const BoxDecoration(
          gradient: AppColors.adminDashboardGradient, // utilisation du gradient défini dans AppColors
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: LiquidGlassCard(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Créer un nouveau groupe',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.textOnDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Nom du groupe
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: AppColors.textOnDark),
                      decoration: InputDecoration(
                        labelText: 'Nom du groupe',
                        labelStyle: const TextStyle(color: AppColors.textSecondaryOnGlass),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.glassStroke),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.accentTeal, width: 2),
                        ),
                        filled: true,
                        fillColor: AppColors.glassCardFill,
                      ),
                      validator: (v) => v!.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 16),
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(color: AppColors.textOnDark),
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: const TextStyle(color: AppColors.textSecondaryOnGlass),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.glassStroke),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.accentTeal, width: 2),
                        ),
                        filled: true,
                        fillColor: AppColors.glassCardFill,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Cotisation quotidienne
                    TextFormField(
                      controller: _contributionController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.textOnDark),
                      decoration: InputDecoration(
                        labelText: 'Cotisation quotidienne (FC)',
                        labelStyle: const TextStyle(color: AppColors.textSecondaryOnGlass),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.glassStroke),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.accentTeal, width: 2),
                        ),
                        filled: true,
                        fillColor: AppColors.glassCardFill,
                      ),
                      validator: (v) => v!.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: 16),
                    // Taux de sécurité
                    TextFormField(
                      controller: _securityFeeRateController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textOnDark),
                      decoration: InputDecoration(
                        labelText: 'Taux de prélèvement sécurité (ex: 0.05)',
                        labelStyle: const TextStyle(color: AppColors.textSecondaryOnGlass),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.glassStroke),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.accentTeal, width: 2),
                        ),
                        filled: true,
                        fillColor: AppColors.glassCardFill,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Pénalité initiale
                    TextFormField(
                      controller: _penaltyController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: AppColors.textOnDark),
                      decoration: InputDecoration(
                        labelText: 'Pénalité initiale (ex: 0.20)',
                        labelStyle: const TextStyle(color: AppColors.textSecondaryOnGlass),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.glassStroke),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.accentTeal, width: 2),
                        ),
                        filled: true,
                        fillColor: AppColors.glassCardFill,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Durée du cycle
                    TextFormField(
                      controller: _cycleDaysController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.textOnDark),
                      decoration: InputDecoration(
                        labelText: 'Durée du cycle (jours)',
                        labelStyle: const TextStyle(color: AppColors.textSecondaryOnGlass),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.glassStroke),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: AppColors.accentTeal, width: 2),
                        ),
                        filled: true,
                        fillColor: AppColors.glassCardFill,
                      ),
                    ),
                    const SizedBox(height: 32),
                    GlassButton(
                      label: 'Créer la tontine',
                      icon: Icons.check,
                      isLoading: _isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
// lib/presentation/features/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likelemba/core/app_colors.dart';
import 'package:likelemba/core/theme/text_styles.dart';
import 'package:likelemba/domain/entities/user.dart';
import 'package:likelemba/presentation/shared/widgets/glass_button.dart';
import 'package:likelemba/presentation/shared/widgets/liquid_glass_card.dart';
import 'package:likelemba/presentation/shared/widgets/error_snackbar.dart';
import 'package:logger/logger.dart';

import '../../../application/notifiers/auth_notifier.dart';
import '../auth/screens/login_screen.dart';

/// Écran des paramètres et du profil utilisateur.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const String tag = 'SettingsScreen';
  final Logger _logger = Logger();
  bool _isLoggingOut = false;
  bool _isTogglingBiometrics = false;
  bool _isTogglingNotifications = false;

  Future<void> _handleToggleBiometrics(bool enabled) async {
    _logger.i('$tag._handleToggleBiometrics - Biométrie: $enabled');
    setState(() => _isTogglingBiometrics = true);
    HapticFeedback.lightImpact();
    await ref.read(authNotifierProvider.notifier).toggleBiometrics(enabled);
    if (!mounted) return;
    setState(() => _isTogglingBiometrics = false);
    final error = ref.read(authNotifierProvider).hasError;
    if (error && mounted) {
      ErrorSnackbar.show(context, 'Impossible de modifier la biométrie.');
    }
  }

  Future<void> _handleToggleNotifications(bool enabled) async {
    _logger.i('$tag._handleToggleNotifications - Notifications: $enabled');
    setState(() => _isTogglingNotifications = true);
    HapticFeedback.lightImpact();
    await ref.read(authNotifierProvider.notifier).toggleNotifications(enabled);
    if (!mounted) return;
    setState(() => _isTogglingNotifications = false);
    final error = ref.read(authNotifierProvider).hasError;
    if (error && mounted) {
      ErrorSnackbar.show(context, 'Impossible de modifier les notifications.');
    }
  }

  Future<void> _handleLogout() async {
    _logger.i('$tag._handleLogout - Déconnexion demandée.');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.primaryDeepBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Se déconnecter ?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Vous serez redirigé vers l\'écran de connexion.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Déconnexion', style: TextStyle(color: AppColors.riskRed)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoggingOut = true);
    HapticFeedback.mediumImpact();
    await ref.read(authNotifierProvider.notifier).logout();
    if (!mounted) return;
    setState(() => _isLoggingOut = false);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider).value;
    final user = authState?.currentUser;

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
          'Paramètres',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A2540), Color(0xFF001220), Color(0xFF003366)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // ── Carte profil ──────────────────────────────────────
                if (user != null) _buildProfileCard(user),
                if (user == null)
                  LiquidGlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text('Chargement...', style: AppTextStyles.bodyMedium(isDark: true)),
                    ),
                  ),

                const SizedBox(height: 24),

                // ── Section : Compte ──────────────────────────────────
                _sectionTitle('Compte'),
                const SizedBox(height: 12),
                LiquidGlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.lock_outline,
                        label: 'Changer de PIN',
                        onTap: () => _showChangePinDialog(context),
                      ),
                      const Divider(color: Colors.white10, height: 1, indent: 56),
                      _SettingsTile(
                        icon: Icons.fingerprint,
                        label: 'Authentification biométrique',
                        trailing: Switch(
                          value: authState?.isBiometricEnabled ?? false,
                          onChanged: _isTogglingBiometrics ? null : _handleToggleBiometrics,
                          activeColor: AppColors.accentTeal,
                        ),
                        onTap: null,
                      ),
                      const Divider(color: Colors.white10, height: 1, indent: 56),
                      _SettingsTile(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                        trailing: Switch(
                          value: authState?.notificationsEnabled ?? true,
                          onChanged: _isTogglingNotifications ? null : _handleToggleNotifications,
                          activeColor: AppColors.accentTeal,
                        ),
                        onTap: null,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Section : Informations ────────────────────────────
                _sectionTitle('Informations'),
                const SizedBox(height: 12),
                LiquidGlassCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.info_outline,
                        label: 'À propos de Likelemba',
                        onTap: () => _showAboutDialog(context),
                      ),
                      const Divider(color: Colors.white10, height: 1, indent: 56),
                      _SettingsTile(
                        icon: Icons.policy_outlined,
                        label: 'Conditions d\'utilisation',
                        onTap: () => _showTermsDialog(context),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Bouton déconnexion ────────────────────────────────
                GlassButton(
                  label: _isLoggingOut ? 'Déconnexion...' : 'Se déconnecter',
                  icon: _isLoggingOut ? null : Icons.logout_rounded,
                  isPrimary: false,
                  isLoading: _isLoggingOut,
                  impact: HapticImpact.medium,
                  onPressed: _handleLogout,
                ),

                const SizedBox(height: 40),

                // Version
                Center(
                  child: Text(
                    'Likelemba v1.0.0  ·  La solidarité renforcée par la science',
                    style: const TextStyle(color: Colors.white24, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(User user) {
    final initials = user.name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
    final roleLabel = user.role == UserRole.admin ? 'Administrateur' : 'Membre';
    final roleColor = user.role == UserRole.admin ? AppColors.solidarityGold : AppColors.accentTeal;
    final trustColor = user.trustScore >= 80
        ? AppColors.solvencyGreen
        : user.trustScore >= 50
            ? AppColors.warningAmber
            : AppColors.riskRed;

    return LiquidGlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 32,
            backgroundColor: AppColors.accentTeal.withOpacity(0.15),
            child: Text(
              initials,
              style: const TextStyle(
                color: AppColors.accentTeal,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: AppTextStyles.sectionTitle(isDark: true)),
                const SizedBox(height: 4),
                Text(user.phoneNumber, style: AppTextStyles.bodySmall(isDark: true)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    // Badge rôle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: roleColor.withOpacity(0.4)),
                      ),
                      child: Text(roleLabel,
                          style: TextStyle(color: roleColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    // Score de confiance
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: trustColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: trustColor.withOpacity(0.4)),
                      ),
                      child: Text('Score: ${user.trustScore}/100',
                          style: TextStyle(color: trustColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        color: Colors.white38,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.primaryDeepBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Likelemba', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"La solidarité renforcée par la science"',
              style: TextStyle(color: AppColors.accentTeal, fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 12),
            Text(
              'Likelemba numérise et sécurise les tontines traditionnelles '
              'grâce à une modélisation mathématique avancée (EDO) pour la '
              'gestion des risques financiers collectifs.',
              style: TextStyle(color: Colors.white70, height: 1.5),
            ),
            SizedBox(height: 12),
            Text('Version : 1.0.0', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer', style: TextStyle(color: AppColors.accentTeal)),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.primaryDeepBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Conditions d\'utilisation',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Document provisoire — sera remplacé par le texte légal définitif.',
                style: TextStyle(color: AppColors.warningAmber, fontStyle: FontStyle.italic, fontSize: 12),
              ),
              SizedBox(height: 12),
              Text(_termsOfUseText, style: TextStyle(color: Colors.white70, height: 1.5)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer', style: TextStyle(color: AppColors.accentTeal)),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangePinDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (_) => const _ChangePinDialog(),
    );
  }
}

const String _termsOfUseText =
    '1. Objet\n'
    'Likelemba est une application de gestion numérique de tontines '
    '(« Makelembas ») permettant à un groupe de participants de cotiser '
    'et de recevoir une cagnotte à tour de rôle.\n\n'
    '2. Responsabilité des participants\n'
    'Chaque participant s\'engage à verser ses cotisations aux échéances '
    'convenues avec son groupe. Les retards peuvent entraîner des '
    'pénalités calculées automatiquement par l\'application.\n\n'
    '3. Rôle de l\'administrateur\n'
    'L\'administrateur d\'un groupe est responsable de la validation des '
    'dépôts et de la gestion du fonds de réserve. Likelemba fournit des '
    'outils d\'aide à la décision (modèle EDO) mais ne garantit pas la '
    'solvabilité des groupes créés par les utilisateurs.\n\n'
    '4. Données personnelles\n'
    'Les données (numéro de téléphone, historique de cotisations) sont '
    'utilisées uniquement pour le fonctionnement du service et ne sont '
    'pas partagées avec des tiers à des fins commerciales.\n\n'
    '5. Limitation de responsabilité\n'
    'Likelemba est un outil de facilitation et ne se substitue pas aux '
    'accords pris entre les membres d\'un groupe. En cas de litige, les '
    'parties sont invitées à se référer aux règles définies au sein de '
    'leur Makelemba.';

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.white54, size: 22),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
            trailing ?? const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Dialogue de changement de PIN avec validation locale puis appel serveur.
class _ChangePinDialog extends ConsumerStatefulWidget {
  const _ChangePinDialog();

  @override
  ConsumerState<_ChangePinDialog> createState() => _ChangePinDialogState();
}

class _ChangePinDialogState extends ConsumerState<_ChangePinDialog> {
  static const String tag = '_ChangePinDialog';
  final Logger _logger = Logger();
  final _oldPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _oldPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final result = await ref.read(authNotifierProvider.notifier).changePin(
          oldPin: _oldPinController.text.trim(),
          newPin: _newPinController.text.trim(),
          confirmPin: _confirmPinController.text.trim(),
        );

    if (!mounted) return;

    result.fold(
      (failure) {
        _logger.w('$tag._handleSubmit - Échec: ${failure.message}');
        setState(() {
          _isSubmitting = false;
          _errorText = failure.message;
        });
      },
      (_) {
        _logger.i('$tag._handleSubmit - PIN changé avec succès.');
        Navigator.pop(context);
        ErrorSnackbar.show(context, 'PIN changé avec succès.');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.primaryDeepBlue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Changer de PIN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pinField(controller: _oldPinController, label: 'PIN actuel'),
          const SizedBox(height: 12),
          _pinField(controller: _newPinController, label: 'Nouveau PIN'),
          const SizedBox(height: 12),
          _pinField(controller: _confirmPinController, label: 'Confirmer le nouveau PIN'),
          if (_errorText != null) ...[
            const SizedBox(height: 12),
            Text(_errorText!, style: const TextStyle(color: AppColors.riskRed, fontSize: 13)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Annuler', style: TextStyle(color: Colors.white54)),
        ),
        TextButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentTeal),
                )
              : const Text('Confirmer', style: TextStyle(color: AppColors.accentTeal)),
        ),
      ],
    );
  }

  Widget _pinField({required TextEditingController controller, required String label}) {
    return TextField(
      controller: controller,
      obscureText: true,
      keyboardType: TextInputType.number,
      maxLength: 6,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        counterText: '',
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.accentTeal)),
      ),
    );
  }
}

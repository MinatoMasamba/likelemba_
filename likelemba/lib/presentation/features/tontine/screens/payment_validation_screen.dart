// lib/presentation/features/transactions/screens/payment_validation_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likelemba/core/app_colors.dart';
import 'package:logger/logger.dart';
import '../../../../application/providers/repository_providers.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../data/remote/tontine_remote_data_source.dart';
import '../../../shared/widgets/glass_button.dart';
import '../../../shared/widgets/liquid_glass_card.dart';
import '../../../shared/widgets/error_snackbar.dart';

/// Écran de confirmation de paiement administratif.
/// Affiche les détails du dépôt d'un membre pour validation par l'admin.
class PaymentValidationScreen extends ConsumerStatefulWidget {
  final int groupId;
  final int userId;

  const PaymentValidationScreen({
    Key? key,
    required this.groupId,
    required this.userId,
  }) : super(key: key);

  @override
  ConsumerState<PaymentValidationScreen> createState() =>
      _PaymentValidationScreenState();
}

class _PaymentValidationScreenState extends ConsumerState<PaymentValidationScreen> {
  static const String tag = 'PaymentValidationScreen';
  final Logger _logger = Logger();
  bool _isLoading = true;
  bool _isValidating = false;
  MemberValidationInfo? _memberInfo;

  @override
  void initState() {
    super.initState();
    _loadValidationData();
  }

  Future<void> _loadValidationData() async {
    try {
      final dataSource = ref.read(tontineRemoteDataSourceProvider);
      final info = await dataSource.getMemberValidationInfo(
        widget.groupId,
        widget.userId,
      );
      if (mounted) {
        setState(() {
          _memberInfo = info;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      _logger.e('$tag._loadValidationData - Erreur: $e', error: e, stackTrace: stack);
      if (mounted) {
        ErrorSnackbar.show(context, 'Impossible de charger les données de validation.');
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleValidate() async {
    if (_memberInfo == null) return;
    setState(() => _isValidating = true);
    _logger.i('$tag._handleValidate - Validation du dépôt de ${_memberInfo!.userName}');
    HapticFeedback.mediumImpact();

    try {
      // TODO: Remplacer par l'appel au use case de validation
      // await ref.read(validatePaymentUseCaseProvider).call(_memberInfo!.userId, ...);
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;
      _logger.i('$tag._handleValidate - Dépôt validé avec succès');
      _showSuccessDialog();
    } catch (e, stack) {
      _logger.e('$tag._handleValidate - Erreur: $e', error: e, stackTrace: stack);
      if (mounted) ErrorSnackbar.show(context, 'Erreur lors de la validation.');
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SuccessDialog(),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text('Validation du Dépôt', style: AppTextStyles.appBarTitle(isDark: isDark)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.adminDashboardGradient),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_memberInfo == null) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text('Validation du Dépôt', style: AppTextStyles.appBarTitle(isDark: isDark)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.adminDashboardGradient),
          child: Center(
            child: Text('Aucune donnée disponible.',
                style: AppTextStyles.bodyLarge(isDark: isDark)),
          ),
        ),
      );
    }

    final info = _memberInfo!;
    final double cotisation = info.amountToValidate - info.debtAmount - info.penaltyAmount;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Validation du Dépôt', style: AppTextStyles.appBarTitle(isDark: isDark)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : AppColors.primaryDeepBlue,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.adminDashboardGradient),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  child: Column(
                    children: [
                      // Carte héros
                      _PaymentHeroCard(
                        userName: info.userName,
                        amount: info.amountToValidate,
                        date: _formatDate(info.date),
                        avatarInitials: info.avatarInitials,
                      ),
                      const SizedBox(height: 24),
                      // Répartition
                      LiquidGlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Répartition des fonds',
                                style: AppTextStyles.sectionTitle(isDark: isDark)),
                            const SizedBox(height: 16),
                            _buildDetailRow(context, Icons.savings_outlined,
                                'Cotisation du cycle', cotisation, AppColors.solvencyGreen),
                            const Divider(color: Colors.white10, height: 24),
                            _buildDetailRow(context, Icons.money_off, 'Dette épongée',
                                info.debtAmount, AppColors.riskRed,
                                isNegative: true, neutralText: 'Aucune dette'),
                            const Divider(color: Colors.white10, height: 24),
                            _buildDetailRow(context, Icons.timer_off, 'Pénalité de retard',
                                info.penaltyAmount, AppColors.warningAmber,
                                isNegative: true, neutralText: 'Aucune pénalité'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Contexte
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDeepBlue.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.accentTeal.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(info.groupName, style: AppTextStyles.cardTitle(isDark: isDark)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.repeat, size: 16,
                                    color: isDark ? Colors.white54 : Colors.black54),
                                const SizedBox(width: 8),
                                Text(info.cycleInfo,
                                    style: AppTextStyles.bodySmall(isDark: isDark)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.admin_panel_settings,
                                    size: 16, color: AppColors.accentTeal),
                                const SizedBox(width: 8),
                                Text('Encaissé par ${info.adminName}',
                                    style: AppTextStyles.bodySmall(isDark: isDark)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Bouton validation
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryDeepBlue.withOpacity(0.0),
                      AppColors.primaryDeepBlue.withOpacity(0.95),
                    ],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: GlassButton(
                  label: _isValidating ? 'Validation...' : 'Confirmer la Réception',
                  icon: _isValidating ? null : Icons.check_circle_outline,
                  isLoading: _isValidating,
                  impact: HapticImpact.heavy,
                  onPressed: _isValidating ? null : _handleValidate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    double value,
    Color color, {
    bool isNegative = false,
    String neutralText = '',
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool hasValue = value > 0;

    return Row(
      children: [
        Icon(icon, size: 20, color: hasValue ? color : Colors.white38),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: AppTextStyles.bodyMedium(isDark: isDark))),
        if (hasValue)
          Text(
            '${isNegative ? "-" : "+"} ${value.toStringAsFixed(0)} FC',
            style: AppTextStyles.bodyMedium(isDark: isDark).copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          Text(neutralText,
              style: AppTextStyles.bodyMedium(isDark: isDark)
                  .copyWith(color: Colors.white38, decoration: TextDecoration.lineThrough)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_monthName(date.month)} ${date.year}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _monthName(int month) {
    const months = [
      '', 'Janv', 'Févr', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Sept', 'Oct', 'Nov', 'Déc'
    ];
    return months[month];
  }
}

/// Petite carte héros pour l'affichage du montant
class _PaymentHeroCard extends StatelessWidget {
  final String userName;
  final double amount;
  final String date;
  final String avatarInitials;

  const _PaymentHeroCard({
    Key? key,
    required this.userName,
    required this.amount,
    required this.date,
    required this.avatarInitials,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String formattedAmount = amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.glassCardFill : Colors.white.withOpacity(0.8),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.0),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.02),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.accentTeal.withOpacity(0.2),
                  child: Text(avatarInitials,
                      style: TextStyle(color: AppColors.accentTeal,
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(height: 12),
                Text(userName, style: AppTextStyles.cardTitle(isDark: isDark)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(formattedAmount,
                        style: AppTextStyles.moneyLarge(isDark: isDark)),
                    const SizedBox(width: 8),
                    Text("FC",
                        style: AppTextStyles.moneyLarge(isDark: isDark)
                            .copyWith(fontSize: 24)),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.black12,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: 14,
                          color: isDark ? AppColors.textSecondaryOnGlass : Colors.black54),
                      const SizedBox(width: 6),
                      Text(date, style: AppTextStyles.bodySmall(isDark: isDark)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dialogue de succès affiché après validation
class _SuccessDialog extends StatelessWidget {
  const _SuccessDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.primaryDeepBlue.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.solvencyGreen.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 64, color: AppColors.solvencyGreen),
            const SizedBox(height: 16),
            Text('Dépôt validé avec succès !',
                style: AppTextStyles.cardTitle(isDark: true), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
// lib/presentation/shared/widgets/money_display.dart

import 'package:flutter/material.dart';
import '../../../core/utils/money_formatter.dart';

/// 💰 Affichage animé d'un montant monétaire avec effet de défilement.
class MoneyDisplay extends StatelessWidget {
  final double amount;
  final AppCurrency currency;
  final TextStyle? style;
  final Duration animationDuration;
  final Curve animationCurve;

  const MoneyDisplay({
    super.key,
    required this.amount,
    this.currency = AppCurrency.cdf,
    this.style,
    this.animationDuration = const Duration(milliseconds: 800),
    this.animationCurve = Curves.easeOutExpo,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ??
        const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: Color(0xFFFFB800),
          letterSpacing: -1.0,
        );

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: amount),
      duration: animationDuration,
      curve: animationCurve,
      builder: (context, value, child) {
        return Text(
          MoneyFormatter.format(value, currency),
          style: baseStyle.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
      },
    );
  }
}
// lib/presentation/shared/widgets/error_snackbar.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 🚨 Snackbar d'erreur accessible avec double vibration et icône.
class ErrorSnackbar {
  static void show(BuildContext context, String message, {VoidCallback? onRetry}) {
    // Double vibration pour attirer l'attention
    HapticFeedback.vibrate();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.vibrate();
    });

    final snackBar = SnackBar(
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE63946).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFE63946),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Attention',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              child: const Text('Réessayer'),
            ),
        ],
      ),
      backgroundColor: const Color(0xFFE63946).withOpacity(0.8),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white10, width: 1),
      ),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      duration: const Duration(seconds: 5),
      action: onRetry == null
          ? SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            )
          : null,
    );

    // Appliquer un BackdropFilter pour l'effet verre (nécessite un overlay)
    // Pour un Snackbar simple, on utilise directement le backgroundColor avec opacité.

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackBar);
  }
}
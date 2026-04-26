// lib/application/providers/isar_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../data/local/isar_service.dart';

/// 🗄️ Provider racine pour le service de base de données Isar.
///
/// Ce provider expose l'instance unique d'[IsarService] à toute l'application.
/// L'initialisation effective d'Isar doit être effectuée dans le `main.dart`
/// avant le `runApp()`.
final isarServiceProvider = Provider<IsarService>((ref) {
  const method = 'isarServiceProvider';
  print('$method - Tentative d\'accès à IsarService.');

  // ⚠️ Ce provider ne doit être utilisé qu'APRÈS l'initialisation.
  // L'instance réelle est injectée via `overrideWithValue` dans le main.dart.
  throw UnimplementedError(
    'IsarService doit être initialisé dans main.dart et overridé. '
    'Utilisez ProviderScope(overrides: [isarServiceProvider.overrideWithValue(isar)])',
  );
});

/// Logger partagé pour les providers (optionnel).
final loggerProvider = Provider<Logger>((ref) {
  print('loggerProvider - Création du Logger.');
  return Logger();
});
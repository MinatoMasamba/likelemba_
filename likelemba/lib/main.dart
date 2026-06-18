// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:likelemba/application/providers/isar_provider.dart';
import 'package:likelemba/data/local/isar_service.dart';
import 'package:likelemba/presentation/features/auth/screens/check_role_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialisation de la base de données Isar (une seule fois)
  final isarService = IsarService();
  await isarService.init();
  print('main - IsarService initialisé avec succès.');

  // 2. Lancement de l'application avec ProviderScope
  runApp(
    ProviderScope(
      overrides: [
        isarServiceProvider.overrideWithValue(isarService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Likelemba Sécurisé',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00C9A7), // Accent Teal du design
        ),
        useMaterial3: true,
      ),
      // ✅ Point d'entrée qui vérifie le rôle et redirige
      home: const CheckRoleScreen(),
    );
  }
}
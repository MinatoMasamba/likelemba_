// lib/data/local/isar_service.dart

import 'dart:async';
import 'dart:io';

import 'package:isar/isar.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/error/app_exception.dart';
import 'models/user_model.dart';
import 'models/likelemba_model.dart';
import 'models/transaction_model.dart';
import 'models/outbox_model.dart';



/// 💾 Service de persistance locale pour le projet Likelemba Sécurisé.
///
/// Ce service encapsule toute la logique d'initialisation et d'accès à la base
/// de données Isar. Il garantit qu'une seule instance de la base est ouverte
/// (pattern Singleton) et fournit des méthodes utilitaires pour les opérations
/// transactionnelles.
///
/// **Offline-First :** Toutes les données métier sont stockées localement
/// avant synchronisation éventuelle avec le serveur.
class IsarService {
  static const String tag = 'IsarService';
  static final Logger _logger = Logger();

  Isar? _isar;
  bool _isInitialized = false;

  /// Indique si le service a été correctement initialisé.
  bool get isInitialized => _isInitialized;

  /// Accès à l'instance Isar active.
  /// Lance une [StateError] si la base n'est pas encore initialisée.
  Isar get instance {
    if (!_isInitialized || _isar == null) {
      _logger.e('$tag.instance - Tentative d\'accès avant initialisation.');
      throw StateError(
        'IsarService n\'est pas initialisé. Appelez init() d\'abord.',
      );
    }
    return _isar!;
  }

  /// Initialise la base de données Isar.
  ///
  /// Cette méthode doit être appelée une seule fois au démarrage de l'application,
  /// idéalement avant le `runApp()` dans `main.dart`.
  ///
  /// Lance une [CacheException] en cas d'échec d'ouverture de la base.
  Future<void> init() async {
    const method = 'init';
    if (_isInitialized) {
      _logger.w('$tag.$method - Service déjà initialisé, opération ignorée.');
      return;
    }

    _logger.i('$tag.$method - Début de l\'initialisation d\'Isar.');

    try {
      // Récupération du répertoire de stockage privé de l'application
      final dir = await getApplicationDocumentsDirectory();
      _logger.d('$tag.$method - Répertoire de stockage : ${dir.path}');

      // Vérification si une instance Isar existe déjà (évite les ouvertures multiples)
      if (Isar.instanceNames.isNotEmpty) {
        _logger.w('$tag.$method - Une instance Isar est déjà ouverte. Fermeture préventive.');
        await Isar.getInstance(Isar.instanceNames.first)?.close();
      }

      // Ouverture de la base avec tous les schémas nécessaires
      _isar = await Isar.open(
        [
          UserModelSchema,
          LikelembaModelSchema,
          TransactionModelSchema,
          OutboxModelSchema,
        ],
        directory: dir.path,
        // Activation de l'inspecteur en mode debug pour faciliter le développement
        inspector: true,
        // Schéma de version (à incrémenter lors de migrations futures)
        maxSizeMiB: 256, // Limite de taille (optionnelle)
      );

      _isInitialized = true;
      _logger.i('$tag.$method - ✅ Isar initialisé avec succès. '
          'Schémas : User, Likelemba, Transaction, Outbox.');
    } on IsarError catch (e, stack) {
      _logger.e('$tag.$method - ❌ Erreur Isar : ${e.message}', error: e, stackTrace: stack);
      throw CacheException('Échec d\'ouverture de la base de données : ${e.message}', stack);
    } catch (e, stack) {
      _logger.e('$tag.$method - ❌ Erreur inattendue : $e', error: e, stackTrace: stack);
      throw CacheException('Erreur inattendue lors de l\'initialisation d\'Isar', stack);
    }
  }

  /// Ferme proprement la base de données.
  ///
  /// À appeler lorsque l'application est mise en arrière-plan ou fermée.
  Future<void> close() async {
    const method = 'close';
    _logger.i('$tag.$method - Fermeture d\'Isar.');
    await _isar?.close();
    _isar = null;
    _isInitialized = false;
  }

  /// Exécute une transaction d'écriture atomique.
  ///
  /// La [callback] reçoit l'instance Isar en argument et peut effectuer
  /// plusieurs opérations d'écriture. Si une exception est levée, toutes
  /// les modifications sont annulées (rollback).
  ///
  /// Retourne le résultat de la [callback].
  ///
  /// Lance une [WriteCacheException] en cas d'échec.
  Future<T> writeTxn<T>(Future<T> Function(Isar isar) callback) async {
    const method = 'writeTxn';
    try {
      _logger.d('$tag.$method - Début transaction écriture.');
      final result = await instance.writeTxn(() => callback(instance));
      _logger.d('$tag.$method - Transaction validée.');
      return result;
    } on IsarError catch (e, stack) {
      _logger.e('$tag.$method - ❌ Erreur Isar : ${e.message}', error: e, stackTrace: stack);
      throw WriteCacheException('Échec de la transaction : ${e.message}', stack);
    } catch (e, stack) {
      _logger.e('$tag.$method - ❌ Erreur inattendue : $e', error: e, stackTrace: stack);
      throw WriteCacheException('Erreur inattendue lors de la transaction', stack);
    }
  }

  /// Exécute une transaction de lecture seule.
  ///
  /// À utiliser pour les requêtes qui ne modifient pas la base.
  Future<T> readTxn<T>(Future<T> Function(Isar isar) callback) async {
    const method = 'readTxn';
    try {
      _logger.d('$tag.$method - Début transaction lecture.');
      final result = await instance.txn(() => callback(instance));
      _logger.d('$tag.$method - Transaction lecture terminée.');
      return result;
    } on IsarError catch (e, stack) {
      _logger.e('$tag.$method - ❌ Erreur Isar : ${e.message}', error: e, stackTrace: stack);
      throw ReadCacheException('Échec de la lecture : ${e.message}', stack);
    } catch (e, stack) {
      _logger.e('$tag.$method - ❌ Erreur inattendue : $e', error: e, stackTrace: stack);
      throw ReadCacheException('Erreur inattendue lors de la lecture', stack);
    }
  }

  /// Supprime toutes les données de la base (⚠️ opération destructive).
  ///
  /// Utile pour la réinitialisation de l'application ou les tests.
  /// À protéger par une confirmation utilisateur.
  Future<void> clearAllData() async {
    const method = 'clearAllData';
    _logger.w('$tag.$method - ⚠️ Suppression de toutes les données !');
    await writeTxn((isar) async {
      await isar.userModels.clear();
      await isar.likelembaModels.clear();
      await isar.transactionModels.clear();
      await isar.outboxModels.clear();
    });
    _logger.i('$tag.$method - Base de données vidée.');
  }

  /// Vérifie si la base de données est accessible et fonctionnelle.
  Future<bool> healthCheck() async {
    const method = 'healthCheck';
    try {
      // Tente une simple lecture pour vérifier l'état
      await readTxn((isar) async {
        await isar.userModels.count();
      });
      _logger.d('$tag.$method - ✅ Base de données saine.');
      return true;
    } catch (e) {
      _logger.e('$tag.$method - ❌ Échec du health check : $e');
      return false;
    }
  }
}
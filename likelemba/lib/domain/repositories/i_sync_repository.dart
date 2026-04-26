// lib/domain/repositories/i_sync_repository.dart

import 'package:dartz/dartz.dart';

import '../../core/error/failures.dart';
import '../../data/remote/sync_remote_data_source.dart'; // Import pour PushResult, SyncDelta

/// 🔄 Interface du repository de synchronisation (Contrat domaine).
///
/// Définit les opérations de synchronisation entre la base locale (Offline-First)
/// et le serveur distant. L'implémentation concrète se trouve dans la couche `data`.
abstract class ISyncRepository {
  /// Pousse les actions en attente de l'Outbox vers le serveur.
  ///
  /// Récupère les messages locaux non synchronisés, les envoie par lots au serveur,
  /// et retourne un [PushResult] indiquant les IDs synchronisés, les échecs et les conflits.
  Future<Either<Failure, PushResult>> pushPendingActions();

  /// Récupère les mises à jour survenues depuis une date donnée pour une liste de groupes.
  ///
  /// [lastSync] : Date de la dernière synchronisation réussie.
  /// [groupIds] : Liste des identifiants des groupes auxquels l'utilisateur participe.
  /// Retourne un [SyncDelta] contenant les transactions, membres et groupes mis à jour.
  Future<Either<Failure, SyncDelta>> pullRemoteUpdates(DateTime lastSync, List<int> groupIds);

  /// Résout les conflits éventuels entre les données locales et les données serveur.
  ///
  /// Applique une stratégie de résolution (ex: priorité au serveur ou à la donnée la plus récente).
  Future<Either<Failure, void>> resolveConflicts();
}
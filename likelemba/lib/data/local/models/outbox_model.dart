// lib/data/local/models/outbox_model.dart

import 'package:isar/isar.dart';

part 'outbox_model.g.dart';
/// 📤 Modèle de file d'attente pour les opérations hors-ligne (Outbox Pattern).
///
/// Lorsque l'utilisateur effectue une action sans connexion internet,
/// celle-ci est enregistrée dans cette table. Le `SyncNotifier` se charge
/// de la transmettre au serveur dès que le réseau est rétabli.
@Collection()
class OutboxModel {
  /// Identifiant unique du message.
  Id id = Isar.autoIncrement;

  /// Type d'action à synchroniser (ex: "SUBMIT_PAYMENT", "EXIT_GROUP").
  late String actionType;

  /// Données de l'action au format JSON string.
  late String payload;

  /// Date de création du message.
  @Index()
  late DateTime createdAt;

  /// Nombre de tentatives d'envoi déjà effectuées.
  int retryCount = 0;

  /// Date de la dernière tentative d'envoi.
  DateTime? lastAttemptAt;

  /// Priorité du message (plus élevé = traité en premier).
  @Index()
  int priority = 0;

  /// Statut actuel du message.
  @enumerated
  OutboxStatus status = OutboxStatus.pending;

  /// Message d'erreur en cas d'échec.
  String? lastError;
}

/// Statuts d'un message dans l'Outbox.
enum OutboxStatus {
  pending,   // En attente d'envoi
  processing,// En cours d'envoi (verrouillé)
  failed,    // Échec après plusieurs tentatives
  synced,    // Synchronisé avec succès
}
from django.db import models
from core.models import BaseModel
from apps.users.models import User


class SyncBatch(BaseModel):
    """
    Un lot de synchronisation envoyé par un client mobile.
    """
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sync_batches')
    device_id = models.CharField(max_length=255)
    batch_id = models.CharField(max_length=100, unique=True)  # UUID généré côté client
    status = models.CharField(
        max_length=20,
        choices=[
            ('pending', 'En attente'),
            ('processing', 'En cours'),
            ('completed', 'Terminé'),
            ('failed', 'Échoué')
        ],
        default='pending'
    )
    operations_count = models.PositiveIntegerField(default=0)
    success_count = models.PositiveIntegerField(default=0)
    failure_count = models.PositiveIntegerField(default=0)
    error_details = models.JSONField(default=dict, blank=True)
    processed_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'sync_batches'
        verbose_name = "Lot de synchronisation"
        verbose_name_plural = "Lots de synchronisation"


class SyncOperation(BaseModel):
    """
    Une opération individuelle dans un lot de synchronisation.
    """
    OPERATION_TYPES = [
        ('create', 'Création'),
        ('update', 'Mise à jour'),
        ('delete', 'Suppression'),
    ]

    batch = models.ForeignKey(SyncBatch, on_delete=models.CASCADE, related_name='operations')
    local_id = models.CharField(max_length=100)  # ID local sur le mobile
    server_id = models.UUIDField(null=True, blank=True)  # ID attribué par le serveur
    entity_type = models.CharField(max_length=50)  # ex: 'contribution', 'membership'
    operation_type = models.CharField(max_length=10, choices=OPERATION_TYPES)
    data = models.JSONField()  # Les données sérialisées
    status = models.CharField(
        max_length=20,
        choices=[
            ('pending', 'En attente'),
            ('success', 'Réussi'),
            ('failed', 'Échoué')
        ],
        default='pending'
    )
    error_message = models.TextField(blank=True)
    retry_count = models.PositiveIntegerField(default=0)

    class Meta:
        db_table = 'sync_operations'
        verbose_name = "Opération de synchronisation"
        verbose_name_plural = "Opérations de synchronisation"
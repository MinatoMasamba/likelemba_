"""
Moteur de synchronisation pour traiter les lots envoyés par les clients mobiles.
"""
import logging
from django.db import transaction
from django.db.models import ForeignKey
from django.utils import timezone
from apps.sync.models import SyncBatch, SyncOperation
from apps.transactions.models import Contribution
from apps.tontines.models import Membership, LikelembaGroup
from core.exceptions import ValidationError

logger = logging.getLogger(__name__)


class SyncEngine:
    """Traite un lot de synchronisation reçu du client."""

    ENTITY_MAPPING = {
        'contribution': Contribution,
        'membership': Membership,
        'group': LikelembaGroup,
    }

    @classmethod
    def process_batch(cls, batch: SyncBatch):
        """Traite toutes les opérations d'un lot."""
        batch.status = 'processing'
        batch.save(update_fields=['status'])

        success = 0
        failure = 0
        errors = {}

        for op in batch.operations.filter(status='pending').order_by('created_at'):
            try:
                with transaction.atomic():
                    cls._process_operation(op)
                    op.status = 'success'
                    success += 1
            except Exception as e:
                logger.error(f"Sync operation failed: {op.id} - {e}")
                op.status = 'failed'
                op.error_message = str(e)
                op.retry_count += 1
                failure += 1
                errors[str(op.id)] = str(e)
            op.save()

        batch.success_count = success
        batch.failure_count = failure
        batch.error_details = errors
        batch.status = 'completed' if failure == 0 else 'failed'
        batch.processed_at = timezone.now()
        batch.save()

        return batch

    @classmethod
    def _process_operation(cls, op: SyncOperation):
        """Traite une opération individuelle selon son type."""
        model_class = cls.ENTITY_MAPPING.get(op.entity_type)
        if not model_class:
            raise ValidationError(f"Type d'entité inconnu: {op.entity_type}")

        if op.operation_type == 'create':
            instance = cls._create_instance(model_class, op.data)
            op.server_id = instance.id
        elif op.operation_type == 'update':
            instance = cls._update_instance(model_class, op.data)
            op.server_id = instance.id
        elif op.operation_type == 'delete':
            cls._delete_instance(model_class, op.data)
        else:
            raise ValidationError(f"Type d'opération inconnu: {op.operation_type}")

    @classmethod
    def _resolve_relations(cls, model_class, data):
        """
        Convertit les champs de relation (ex: `cycle`, `membership`) envoyés comme
        simples identifiants texte en `<champ>_id` (ex: `cycle_id`).

        Sans cette étape, `Model.objects.create(cycle=<uuid>)` échoue : Django exige
        une instance du modèle lié pour le nom de champ nu, alors que le client mobile
        n'envoie que l'identifiant. `<champ>_id` accepte directement la clé brute.
        """
        resolved = dict(data)
        for field in model_class._meta.get_fields():
            if isinstance(field, ForeignKey) and field.name in resolved:
                resolved[field.attname] = resolved.pop(field.name)
        return resolved

    @classmethod
    def _create_instance(cls, model_class, data):
        """Crée une nouvelle instance."""
        # Nettoyer les données (retirer les champs locaux)
        data.pop('local_id', None)
        data.pop('is_synced', None)
        data = cls._resolve_relations(model_class, data)
        instance = model_class.objects.create(**data)
        return instance

    @classmethod
    def _update_instance(cls, model_class, data):
        """Met à jour une instance existante."""
        instance_id = data.pop('id', None)
        if not instance_id:
            raise ValidationError("ID manquant pour la mise à jour.")
        instance = model_class.objects.get(id=instance_id)
        data = cls._resolve_relations(model_class, data)
        for key, value in data.items():
            setattr(instance, key, value)
        instance.save()
        return instance

    @classmethod
    def _delete_instance(cls, model_class, data):
        """Supprime une instance."""
        instance_id = data.get('id')
        if not instance_id:
            raise ValidationError("ID manquant pour la suppression.")
        model_class.objects.filter(id=instance_id).delete()
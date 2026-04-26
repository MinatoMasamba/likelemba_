# tasks/sync_tasks.py
from celery import shared_task
from apps.sync.models import SyncBatch
from apps.sync.sync_engine import SyncEngine
import logging

logger = logging.getLogger(__name__)


@shared_task
def process_sync_batch_async(batch_id):
    """
    Traite un lot de synchronisation de manière asynchrone.
    """
    try:
        batch = SyncBatch.objects.get(id=batch_id)
        SyncEngine.process_batch(batch)
        logger.info(f"Sync batch {batch.batch_id} processed successfully.")
    except Exception as e:
        logger.error(f"Sync batch {batch_id} failed: {e}")
        raise
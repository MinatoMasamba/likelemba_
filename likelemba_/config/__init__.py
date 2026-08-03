# Assure que l'app Celery est créée dès le démarrage de Django,
# pour que @shared_task trouve toujours une app configurée.
from .celery import app as celery_app

__all__ = ('celery_app',)

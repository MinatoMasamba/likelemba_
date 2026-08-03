import os
from celery import Celery

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings.base')

app = Celery('likelemba')
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()

# `tasks/` est un paquet indépendant à la racine du dépôt (pas une app Django),
# donc autodiscover_tasks() — qui ne scanne que INSTALLED_APPS — ne le voit pas.
# On l'enregistre explicitement pour que le worker connaisse process_sync_batch_async.
app.conf.imports = list(app.conf.imports or []) + ['tasks.sync_tasks']
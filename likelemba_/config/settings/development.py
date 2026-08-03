"""
Configuration de développement.
Hérite de la base et desserre les contraintes utiles en local uniquement.
"""
from .base import *  # noqa: F401,F403

DEBUG = True

# Emails et erreurs affichés en console plutôt qu'envoyés réellement.
EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'

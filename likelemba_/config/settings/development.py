"""
Configuration de développement.
Hérite de la base et desserre les contraintes utiles en local uniquement.
"""
from .base import *  # noqa: F401,F403

DEBUG = True

# EMAIL_BACKEND vient de base.py (lu depuis .env) : si aucun SMTP n'est
# configuré, il retombe sur la console ; s'il l'est, les emails partent
# réellement même en développement, pour pouvoir tester le flux de bout en
# bout (connexion, réinitialisation de mot de passe).

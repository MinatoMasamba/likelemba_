"""
Configuration de production.
Hérite de la base et impose un environnement explicitement configuré :
aucune valeur par défaut permissive n'est fournie ici.
"""
from .base import *  # noqa: F401,F403
from decouple import config

DEBUG = False

# Pas de valeur par défaut : le déploiement doit fournir explicitement les hôtes autorisés.
ALLOWED_HOSTS = config(
    'ALLOWED_HOSTS',
    cast=lambda v: [s.strip() for s in v.split(',') if s.strip()]
)

# Durcissement HTTP/cookies.
SECURE_SSL_REDIRECT = config('SECURE_SSL_REDIRECT', default=True, cast=bool)
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_CONTENT_TYPE_NOSNIFF = True
SECURE_BROWSER_XSS_FILTER = True
SECURE_HSTS_SECONDS = config('SECURE_HSTS_SECONDS', default=60 * 60 * 24 * 7, cast=int)
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True
X_FRAME_OPTIONS = 'DENY'

# En production, les origines CORS doivent être listées explicitement (pas de wildcard).
CORS_ALLOW_ALL_ORIGINS = False

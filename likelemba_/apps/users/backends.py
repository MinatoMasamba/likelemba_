"""
Backend d'authentification par email, utilisé par le tableau de bord (session).
L'API REST (JWT) continue d'authentifier par numéro de téléphone via
ModelBackend + USERNAME_FIELD ; ce backend ne s'active que lorsqu'un
paramètre `username` explicite est fourni (formulaire email), donc il ne
peut pas interférer avec ce flux.
"""
from django.contrib.auth import get_user_model
from django.contrib.auth.backends import ModelBackend

User = get_user_model()


class EmailBackend(ModelBackend):
    def authenticate(self, request, username=None, password=None, **kwargs):
        if not username or not password:
            return None
        try:
            user = User.objects.get(email__iexact=username)
        except (User.DoesNotExist, User.MultipleObjectsReturned):
            return None
        if user.check_password(password) and self.user_can_authenticate(user):
            return user
        return None

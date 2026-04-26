"""
Permissions personnalisées pour le projet.
"""
from rest_framework import permissions


class IsOwnerOrAdmin(permissions.BasePermission):
    """
    Permission qui autorise l'accès si l'utilisateur est le propriétaire
    de l'objet ou un administrateur.
    """

    def has_object_permission(self, request, view, obj):
        # Les administrateurs ont tous les droits
        if request.user and request.user.is_staff:
            return True

        # Vérifier si l'objet a un attribut 'user' ou 'owner'
        owner = getattr(obj, 'user', None) or getattr(obj, 'owner', None)
        return owner == request.user


class IsGroupMember(permissions.BasePermission):
    """
    Permission pour les membres d'un groupe de tontine.
    """

    def has_object_permission(self, request, view, obj):
        if not request.user.is_authenticated:
            return False

        # Si l'objet est un Membership
        if hasattr(obj, 'user'):
            return obj.user == request.user

        # Si l'objet est un LikelembaGroup, vérifier l'appartenance
        if hasattr(obj, 'members'):
            return obj.members.filter(user=request.user, is_active=True).exists()

        # Sinon, essayer de trouver un attribut group
        group = getattr(obj, 'group', None) or getattr(obj, 'cycle', None) and getattr(obj.cycle, 'group', None)
        if group:
            return group.members.filter(user=request.user, is_active=True).exists()

        return False


class IsGroupAdmin(permissions.BasePermission):
    """
    Permission pour les administrateurs d'un groupe de tontine.
    """

    def has_object_permission(self, request, view, obj):
        if not request.user.is_authenticated:
            return False

        # Les superusers passent
        if request.user.is_superuser:
            return True

        # Récupérer le groupe
        group = None
        if hasattr(obj, 'group'):
            group = obj.group
        elif hasattr(obj, 'cycle'):
            group = obj.cycle.group
        elif hasattr(obj, 'members'):  # C'est peut-être le groupe lui-même
            group = obj

        if group:
            return group.members.filter(
                user=request.user,
                role='admin',
                is_active=True
            ).exists()

        return False


class ReadOnly(permissions.BasePermission):
    """Permission lecture seule."""
    def has_permission(self, request, view):
        return request.method in permissions.SAFE_METHODS

    def has_object_permission(self, request, view, obj):
        return request.method in permissions.SAFE_METHODS
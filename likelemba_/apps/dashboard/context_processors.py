from apps.tontines.models import Membership


def nav(request):
    """
    Injecte `has_admin_access` dans le contexte de tous les templates : vrai si
    l'utilisateur connecté administre au moins un groupe (Membership.role
    'admin'), ce qui détermine si la barre de navigation basse de l'app
    affiche le jeu d'onglets membre ou administrateur.
    """
    user = getattr(request, 'user', None)
    if not user or not user.is_authenticated:
        return {}
    has_admin_access = Membership.objects.filter(user=user, role='admin', is_active=True).exists()
    return {'has_admin_access': has_admin_access}

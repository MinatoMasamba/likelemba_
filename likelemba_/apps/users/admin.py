# apps/users/admin.py

from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from django.utils.translation import gettext_lazy as _

from .models import User, UserProfile, UserDevice


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    """
    Interface d'administration pour le modèle User personnalisé.
    """
    # Champs affichés dans la liste des utilisateurs
    list_display = (
        'phone_number',
        'full_name',
        'email',
        'account_type',
        'is_active',
        'phone_verified',
        'date_joined',
        'account_type',
    )
    list_filter = (
        'is_active',
        'is_staff',
        'is_superuser',
        'account_type',
        'phone_verified',
        'date_joined',
    )
    search_fields = ('phone_number', 'full_name', 'email')
    ordering = ('-date_joined',)
    
    # Regroupement des champs dans le formulaire de détail
    fieldsets = (
        (None, {
            'fields': ('phone_number', 'password')
        }),
        (_('Informations personnelles'), {
            'fields': ('full_name', 'email', 'account_type')
        }),
        (_('Permissions'), {
            'fields': (
                'is_active',
                'is_staff',
                'is_superuser',
                'groups',
                'user_permissions',
            )
        }),
        (_('Dates importantes'), {
            'fields': ('date_joined', 'last_login')
        }),
        (_('Vérifications'), {
            'fields': ('phone_verified', 'email_verified')
        }),
        (_('Biométrie'), {
            'fields': ('biometric_public_key', 'biometric_enabled')
        }),
        (_('Métadonnées'), {
            'fields': ('last_login_ip', 'last_login_device')
        }),
    )
    # Champs pour la création d'un nouvel utilisateur (formulaire d'ajout)
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': (
                'phone_number',
                'full_name',
                'email',
                'password1',
                'password2',
                'account_type',
                'is_active',
                'is_staff',
            ),
        }),
    )
    # Utiliser le champ phone_number comme identifiant principal
    readonly_fields = ('date_joined', 'last_login')


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = (
        'user',
        'risk_score',
        'language',
        'notification_enabled',
        'total_contributions',
        'total_received',
        'successful_cycles',
        'default_count',
    )
    list_filter = ('language', 'notification_enabled')
    search_fields = ('user__phone_number', 'user__full_name')
    raw_id_fields = ('user',)


@admin.register(UserDevice)
class UserDeviceAdmin(admin.ModelAdmin):
    list_display = ('user', 'device_id', 'device_type', 'last_active', 'app_version')
    list_filter = ('device_type', 'last_active')
    search_fields = ('user__phone_number', 'device_id')
    readonly_fields = ('last_active',)
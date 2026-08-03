# apps/tontines/admin.py

from django.contrib import admin
from django.utils.translation import gettext_lazy as _

from .models import (
    LikelembaGroup,
    Cycle,
    Membership,
    QueuePosition,
    JoinRequest,
)


# ----------------------------------------------------------------------
# Inlines (permettent d'afficher/modifier des relations directement
# depuis le formulaire parent)
# ----------------------------------------------------------------------

class MembershipInline(admin.TabularInline):
    model = Membership
    extra = 0
    fields = ('user', 'role', 'is_active', 'joined_at', 'left_at')
    readonly_fields = ('joined_at',)


class QueuePositionInline(admin.TabularInline):
    model = QueuePosition
    extra = 0
    fields = ('membership', 'position', 'is_current', 'received_at')
    readonly_fields = ('received_at',)


class JoinRequestInline(admin.TabularInline):
    model = JoinRequest
    extra = 0
    fields = ('user', 'status', 'created_at')
    readonly_fields = ('created_at',)


# ----------------------------------------------------------------------
# Administrateur pour le groupe (likelemba)
# ----------------------------------------------------------------------

@admin.register(LikelembaGroup)
class LikelembaGroupAdmin(admin.ModelAdmin):
    list_display = (
        'name',
        'created_by',
        'is_active',
        'is_locked',
        'number_of_members',
        'reserve_amount_display',
        'started_at',
        'created_at',
    )
    list_filter = (
        'is_active',
        'is_locked',
        'created_at',
    )
    search_fields = ('name', 'created_by__phone_number', 'created_by__full_name')
    readonly_fields = (
        'invite_code',
        'invite_link',
        'number_of_members',
        'reserve_amount',
        'created_at',
        'updated_at',
        'elapsed_days',
        'is_cycle_completed',
    )
    fieldsets = (
        (_('Identité'), {
            'fields': ('name', 'description', 'created_by', 'invite_code', 'invite_link')
        }),
        (_('Paramètres financiers'), {
            'fields': (
                'contribution_amount',
                'security_levy',
                'penalty_rate_initial',
                'cycle_duration_days',
                'distribution_interval_days',
                'regeneration_target_days',
            )
        }),
        (_('Fonds et état du cycle'), {
            'fields': (
                'reserve_amount',
                'current_beneficiary_index',
                'started_at',
                'ended_at',
                'is_active',
            )
        }),
        (_('Verrouillage'), {
            'fields': ('is_locked', 'locked_at')
        }),
        (_('Dates'), {
            'fields': ('created_at', 'updated_at')
        }),
        (_('Statistiques calculées'), {
            'fields': ('number_of_members', 'elapsed_days', 'is_cycle_completed'),
            'classes': ('collapse',),
        }),
    )

    inlines = [MembershipInline, JoinRequestInline]

    def reserve_amount_display(self, obj):
        return f"{obj.reserve_amount:,.2f} FC"
    reserve_amount_display.short_description = _("Fonds de réserve")

    def invite_link(self, obj):
        """Affiche le lien d'invitation complet (pour copier)."""
        from django.conf import settings
        base = getattr(settings, 'BASE_URL', 'http://localhost:8000')
        return f"{base}/api/v1/tontines/groups/join-by-code/?code={obj.invite_code}"
    invite_link.short_description = _("Lien d'invitation")

    # Actions personnalisées
    actions = ['lock_groups', 'unlock_groups']

    @admin.action(description=_("Verrouiller les cycles sélectionnés"))
    def lock_groups(self, request, queryset):
        from django.utils import timezone
        queryset.update(is_locked=True, locked_at=timezone.now())
        self.message_user(request, _("Les cycles ont été verrouillés."))

    @admin.action(description=_("Déverrouiller les cycles sélectionnés"))
    def unlock_groups(self, request, queryset):
        queryset.update(is_locked=False, locked_at=None)
        self.message_user(request, _("Les cycles ont été déverrouillés."))


# ----------------------------------------------------------------------
# Cycle
# ----------------------------------------------------------------------

@admin.register(Cycle)
class CycleAdmin(admin.ModelAdmin):
    list_display = (
        'group',
        'sequence_number',
        'is_active',
        'is_completed',
        'start_date',
        'end_date',
    )
    list_filter = ('is_active', 'is_completed')
    search_fields = ('group__name',)
    inlines = [QueuePositionInline]
    readonly_fields = ('created_at', 'updated_at')


# ----------------------------------------------------------------------
# Membership
# ----------------------------------------------------------------------

@admin.register(Membership)
class MembershipAdmin(admin.ModelAdmin):
    list_display = (
        'user',
        'group',
        'role',
        'is_active',
        'joined_at',
        'queue_position',
        'has_received_payout',
        'debt_count',
    )
    list_filter = ('role', 'is_active', 'has_received_payout')
    search_fields = (
        'user__phone_number',
        'user__full_name',
        'group__name',
    )
    readonly_fields = ('joined_at', 'left_at', 'total_contributed', 'total_received')

    fieldsets = (
        (None, {
            'fields': ('user', 'group', 'role', 'is_active')
        }),
        (_('Dates'), {
            'fields': ('joined_at', 'left_at')
        }),
        (_('Statistiques'), {
            'fields': (
                'total_contributed',
                'total_received',
                'debt_count',
                'has_received_payout',
            )
        }),
    )


# ----------------------------------------------------------------------
# QueuePosition
# ----------------------------------------------------------------------

@admin.register(QueuePosition)
class QueuePositionAdmin(admin.ModelAdmin):
    list_display = (
        'cycle',
        'membership',
        'position',
        'is_current',
        'received_at',
    )
    list_filter = ('is_current',)
    search_fields = (
        'membership__user__phone_number',
        'membership__user__full_name',
        'cycle__group__name',
    )
    readonly_fields = ('received_at', 'created_at')


# ----------------------------------------------------------------------
# JoinRequest
# ----------------------------------------------------------------------

@admin.register(JoinRequest)
class JoinRequestAdmin(admin.ModelAdmin):
    list_display = (
        'user',
        'group',
        'status',
        'created_at',
        'processed_by',
        'processed_at',
    )
    list_filter = ('status', 'created_at')
    search_fields = (
        'user__phone_number',
        'user__full_name',
        'group__name',
    )
    readonly_fields = ('created_at', 'updated_at', 'processed_at')
    fieldsets = (
        (None, {
            'fields': ('user', 'group', 'message', 'status')
        }),
        (_('Traitement'), {
            'fields': ('processed_by', 'processed_at', 'response_message')
        }),
        (_('Dates'), {
            'fields': ('created_at', 'updated_at')
        }),
    )

    actions = ['approve_requests', 'reject_requests']

    @admin.action(description=_("Approuver les demandes sélectionnées"))
    def approve_requests(self, request, queryset):
        from django.utils import timezone
        for req in queryset.filter(status='pending'):
            # Crée un membership si pas déjà membre
            if not req.group.members.filter(user=req.user, is_active=True).exists():
                # Rôle toujours 'member' : le rôle ne peut pas être auto-déclaré
                # par le demandeur (risque d'élévation de privilège).
                Membership.objects.create(
                    user=req.user,
                    group=req.group,
                    role='member',
                    joined_at=timezone.now()
                )
            req.status = 'accepted'
            req.processed_by = request.user
            req.processed_at = timezone.now()
            req.save()
        self.message_user(request, _("Demandes approuvées et membres ajoutés."))

    @admin.action(description=_("Refuser les demandes sélectionnées"))
    def reject_requests(self, request, queryset):
        from django.utils import timezone
        for req in queryset.filter(status='pending'):
            req.status = 'rejected'
            req.processed_by = request.user
            req.processed_at = timezone.now()
            req.save()
        self.message_user(request, _("Demandes refusées."))
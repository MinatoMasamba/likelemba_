"""
Modèles pour la gestion des groupes Likelemba, cycles et adhésions.
"""
from decimal import Decimal
import secrets
from django.db import models
from django.core.validators import MinValueValidator, MaxValueValidator
from django.utils import timezone
from core.models import BaseModel
from apps.users.models import User


class LikelembaGroup(BaseModel):
    """
    Groupe de tontine Likelemba.
    Contient les paramètres globaux, le fonds de réserve,
    et les variables nécessaires au moteur EDO et à l'application Flutter.
    """

    # --------------------------------------------------------------------------
    # Identité
    # --------------------------------------------------------------------------
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True)

    # --------------------------------------------------------------------------
    # Paramètres financiers (EDO)
    # --------------------------------------------------------------------------
    contribution_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('500'))],
        help_text="Montant de la cotisation journalière par membre (S)"
    )
    security_levy = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0'))],
        help_text="Prélèvement de sécurité par cotisation (a), en valeur absolue"
    )
    penalty_rate_initial = models.FloatField(
        validators=[MinValueValidator(0.0), MaxValueValidator(1.0)],
        default=0.15,
        help_text="Taux de pénalité initial (alpha_0)"
    )
    cycle_duration_days = models.PositiveIntegerField(
        help_text="Durée totale d'un cycle en jours (T)"
    )
    distribution_interval_days = models.PositiveIntegerField(
        default=3,
        help_text="Intervalle entre les distributions de cagnotte (k)"
    )
    regeneration_target_days = models.PositiveIntegerField(
        default=3,
        help_text="Délai cible de régénération du fonds (ΔTmax)"
    )

    # --------------------------------------------------------------------------
    # Fonds de réserve
    # --------------------------------------------------------------------------
    reserve_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=0,
        help_text="Montant actuel du fonds de réserve – F(t)"
    )

    # --------------------------------------------------------------------------
    # État du cycle
    # --------------------------------------------------------------------------
    is_active = models.BooleanField(default=True)
    created_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        null=True,
        related_name='created_groups'
    )
    started_at = models.DateTimeField(
        null=True,
        blank=True,
        help_text="Date de début du cycle (cycleStartDate)"
    )
    ended_at = models.DateTimeField(null=True, blank=True)

    current_beneficiary_index = models.PositiveIntegerField(
        default=0,
        help_text="Index du bénéficiaire actuel dans la file d'attente"
    )

    # --------------------------------------------------------------------------
    # Verrouillage (immuabilité du cycle)
    # --------------------------------------------------------------------------
    is_locked = models.BooleanField(
        default=False,
        help_text="Verrouillage des paramètres après démarrage"
    )
    locked_at = models.DateTimeField(null=True, blank=True)

    # --------------------------------------------------------------------------
    # Invitation
    # --------------------------------------------------------------------------
    invite_code = models.CharField(
        max_length=12,
        unique=True,
        blank=True,
        help_text="Code unique pour les invitations"
    )

    class Meta:
        db_table = 'likelemba_groups'
        verbose_name = "Groupe Likelemba"
        verbose_name_plural = "Groupes Likelemba"

    # --------------------------------------------------------------------------
    # Propriétés calculées (pour Flutter et logique métier)
    # --------------------------------------------------------------------------
    @property
    def number_of_members(self):
        return self.members.filter(is_active=True).count()

    @property
    def contribution_net(self):
        """Part nette allant à la cagnotte après prélèvement."""
        return self.contribution_amount - self.security_levy

    @property
    def security_fee_rate(self) -> float:
        """Taux de prélèvement de sécurité (a / S), format décimal."""
        if self.contribution_amount and self.contribution_amount > 0:
            return float(self.security_levy / self.contribution_amount)
        return 0.0

    @property
    def elapsed_days(self):
        """Jours écoulés depuis le début du cycle (comme Flutter)."""
        if self.started_at:
            return (timezone.now().date() - self.started_at.date()).days
        return 0

    @property
    def is_cycle_completed(self):
        """Indique si le cycle est terminé (comme Flutter)."""
        return self.elapsed_days >= self.cycle_duration_days

    def calculate_gross_jackpot(self):
        """Cagnotte théorique avant prélèvement (Flutter: grossJackpot)."""
        n = self.number_of_members
        if n <= 1:
            return Decimal('0')
        return (n - 1) * self.contribution_amount

    def calculate_net_jackpot(self):
        """Cagnotte nette après prélèvement (Flutter: netJackpot)."""
        rate = Decimal(str(self.security_fee_rate))
        return self.calculate_gross_jackpot() * (Decimal('1') - rate)

    # --------------------------------------------------------------------------
    # Méthodes utilitaires
    # --------------------------------------------------------------------------
    def save(self, *args, **kwargs):
        if not self.invite_code:
            self.invite_code = self.generate_unique_invite_code()
        super().save(*args, **kwargs)

    def generate_unique_invite_code(self):
        """Génère un code aléatoire de 8 caractères (lettres et chiffres) unique."""
        while True:
            code = secrets.token_urlsafe(6)[:8].upper()
            if not LikelembaGroup.objects.filter(invite_code=code).exists():
                return code

    def __str__(self):
        return f"{self.name} ({'Actif' if self.is_active else 'Inactif'})"


class Cycle(BaseModel):
    """
    Un cycle complet de tontine.
    """
    group = models.ForeignKey(
        LikelembaGroup,
        on_delete=models.CASCADE,
        related_name='cycles'
    )
    sequence_number = models.PositiveIntegerField(help_text="Numéro d'ordre du cycle")
    start_date = models.DateTimeField(default=timezone.now)
    end_date = models.DateTimeField(null=True, blank=True)

    # État
    is_completed = models.BooleanField(default=False)
    is_active = models.BooleanField(default=True)

    # Cumul du cycle
    total_contributions_collected = models.DecimalField(
        max_digits=14, decimal_places=2, default=0
    )
    total_refunds_paid = models.DecimalField(
        max_digits=14, decimal_places=2, default=0
    )

    class Meta:
        db_table = 'cycles'
        verbose_name = "Cycle"
        verbose_name_plural = "Cycles"
        unique_together = ['group', 'sequence_number']
        ordering = ['-sequence_number']

    def __str__(self):
        return f"{self.group.name} - Cycle {self.sequence_number}"


class Membership(BaseModel):
    """
    Adhésion d'un utilisateur à un groupe.
    """
    ROLE_CHOICES = [
        ('member', 'Membre'),
        ('admin', 'Administrateur'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='memberships')
    group = models.ForeignKey(LikelembaGroup, on_delete=models.CASCADE, related_name='members')
    role = models.CharField(max_length=10, choices=ROLE_CHOICES, default='member')
    joined_at = models.DateTimeField(default=timezone.now)
    left_at = models.DateTimeField(null=True, blank=True)
    is_active = models.BooleanField(default=True)

    # Position dans la file d'attente pour le cycle courant
    queue_position = models.PositiveIntegerField(null=True, blank=True)

    # Statistiques individuelles dans ce groupe
    total_contributed = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    total_received = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    debt_count = models.PositiveIntegerField(default=0, help_text="Nombre de cotisations manquées")
    has_received_payout = models.BooleanField(default=False)

    class Meta:
        db_table = 'memberships'
        verbose_name = "Adhésion"
        verbose_name_plural = "Adhésions"
        unique_together = ['user', 'group']

    def __str__(self):
        return f"{self.user.full_name} - {self.group.name} ({self.role})"


class QueuePosition(BaseModel):
    """
    File d'attente explicite pour un cycle donné.
    """
    cycle = models.ForeignKey(Cycle, on_delete=models.CASCADE, related_name='queue')
    membership = models.ForeignKey(Membership, on_delete=models.CASCADE, related_name='queue_entries')
    position = models.PositiveIntegerField()
    is_current = models.BooleanField(default=False)
    received_at = models.DateTimeField(null=True, blank=True)

    class Meta:
        db_table = 'queue_positions'
        verbose_name = "Position dans la file"
        verbose_name_plural = "Positions dans la file"
        unique_together = ['cycle', 'membership']
        ordering = ['position']

    def __str__(self):
        return f"Cycle {self.cycle.sequence_number} - Pos {self.position}: {self.membership.user.full_name}"


class JoinRequest(BaseModel):
    """
    Demande d'adhésion à un groupe Likelemba.
    """
    STATUS_CHOICES = [
        ('pending', 'En attente'),
        ('accepted', 'Acceptée'),
        ('rejected', 'Refusée'),
        ('cancelled', 'Annulée'),
    ]

    user = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='join_requests'
    )
    group = models.ForeignKey(
        LikelembaGroup,
        on_delete=models.CASCADE,
        related_name='join_requests'
    )
    message = models.TextField(
        blank=True,
        help_text="Message optionnel du demandeur"
    )
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='pending'
    )
    processed_by = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='processed_join_requests'
    )
    processed_at = models.DateTimeField(null=True, blank=True)
    response_message = models.TextField(
        blank=True,
        help_text="Message de réponse de l'administrateur"
    )

    class Meta:
        db_table = 'join_requests'
        verbose_name = "Demande d'adhésion"
        verbose_name_plural = "Demandes d'adhésion"
        unique_together = ['user', 'group']  # Un utilisateur ne peut avoir qu'une demande active par groupe
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.user.phone_number} → {self.group.name} ({self.status})"
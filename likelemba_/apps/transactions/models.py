from decimal import Decimal
from django.db import models
from django.core.validators import MinValueValidator
from core.models import BaseModel
from apps.tontines.models import Cycle, Membership
from apps.users.models import User


class Transaction(BaseModel):
    """
    Classe abstraite pour toutes les transactions financières.
    """
    TRANSACTION_TYPES = [
        ('contribution', 'Cotisation'),
        ('refund', 'Remboursement'),
        ('payout', 'Cagnotte'),
    ]

    cycle = models.ForeignKey(Cycle, on_delete=models.CASCADE, related_name='%(class)ss')
    membership = models.ForeignKey(Membership, on_delete=models.CASCADE, related_name='%(class)ss')
    amount = models.DecimalField(max_digits=12, decimal_places=2, validators=[MinValueValidator(Decimal('0'))])
    transaction_type = models.CharField(max_length=20, choices=TRANSACTION_TYPES)
    status = models.CharField(
        max_length=20,
        choices=[('pending', 'En attente'), ('validated', 'Validée'), ('rejected', 'Rejetée')],
        default='pending'
    )
    validated_by = models.ForeignKey(User, null=True, blank=True, on_delete=models.SET_NULL)
    validated_at = models.DateTimeField(null=True, blank=True)
    proof_image = models.ImageField(upload_to='proofs/%Y/%m/', blank=True, null=True)
    notes = models.TextField(blank=True)

    # Pour la synchronisation offline
    is_synced = models.BooleanField(default=True)
    local_id = models.CharField(max_length=100, blank=True, null=True, unique=True)

    class Meta:
        abstract = True
        ordering = ['-created_at']


class Contribution(Transaction):
    """
    Cotisation versée par un membre.
    """
    due_date = models.DateField(null=True, blank=True)
    is_late = models.BooleanField(default=False)

    class Meta:
        db_table = 'contributions'
        verbose_name = "Cotisation"
        verbose_name_plural = "Cotisations"

    def save(self, *args, **kwargs):
        self.transaction_type = 'contribution'
        super().save(*args, **kwargs)


class Refund(Transaction):
    """
    Remboursement versé à un membre qui quitte.
    """
    days_participated = models.PositiveIntegerField()
    penalty_rate_applied = models.FloatField()
    processed_at = models.DateTimeField()

    class Meta:
        db_table = 'refunds'
        verbose_name = "Remboursement"
        verbose_name_plural = "Remboursements"

    def save(self, *args, **kwargs):
        self.transaction_type = 'refund'
        super().save(*args, **kwargs)


class Payout(Transaction):
    """
    Versement de la cagnotte à un membre.
    """
    payout_date = models.DateTimeField()
    cycle_position = models.PositiveIntegerField(help_text="Position dans le cycle")

    class Meta:
        db_table = 'payouts'
        verbose_name = "Cagnotte"
        verbose_name_plural = "Cagnottes"

    def save(self, *args, **kwargs):
        self.transaction_type = 'payout'
        super().save(*args, **kwargs)
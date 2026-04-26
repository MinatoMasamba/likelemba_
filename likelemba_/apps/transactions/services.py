from decimal import Decimal
from django.db import transaction
from django.utils import timezone
from core.exceptions import BusinessLogicError, InsufficientFundsError
from apps.tontines.models import Cycle, Membership, QueuePosition
from .models import Contribution, Refund, Payout


class TransactionService:
    """Service de gestion des transactions financières."""

    @staticmethod
    def submit_contribution(membership, amount, due_date=None, proof=None):
        """Enregistre une cotisation d'un membre."""
        if not membership.is_active:
            raise BusinessLogicError("Ce membre n'est plus actif dans le groupe.")

        group = membership.group
        active_cycle = group.cycles.filter(is_active=True, is_completed=False).first()
        if not active_cycle:
            raise BusinessLogicError("Aucun cycle actif.")

        if amount != group.contribution_amount:
            raise BusinessLogicError(f"Le montant doit être exactement {group.contribution_amount}.")

        with transaction.atomic():
            contribution = Contribution.objects.create(
                cycle=active_cycle,
                membership=membership,
                amount=amount,
                due_date=due_date,
                proof_image=proof,
                status='pending'
            )

            # Mise à jour du total cotisé par le membre
            membership.total_contributed += amount
            membership.save(update_fields=['total_contributed'])

            # Mise à jour du cycle
            active_cycle.total_contributions_collected += amount
            active_cycle.save(update_fields=['total_contributions_collected'])

            # Alimentation du fonds de réserve
            group.reserve_amount += group.security_levy
            group.save(update_fields=['reserve_amount'])

            # Réduire le compteur de dettes si applicable
            if membership.debt_count > 0:
                membership.debt_count -= 1
                membership.save(update_fields=['debt_count'])

            return contribution

    @staticmethod
    def validate_contribution(contribution_id, validator_user):
        """Valide une cotisation (action de l'admin)."""
        contribution = Contribution.objects.select_for_update().get(id=contribution_id)
        if contribution.status != 'pending':
            raise BusinessLogicError("Cette cotisation a déjà été traitée.")

        contribution.status = 'validated'
        contribution.validated_by = validator_user
        contribution.validated_at = timezone.now()
        contribution.save()

        # Vérifier si le membre a rempli ses obligations pour la période
        # et éventuellement déclencher le paiement de la cagnotte si c'est son tour
        TransactionService._check_payout_eligibility(contribution.membership)

        return contribution

    @staticmethod
    def _check_payout_eligibility(membership):
        """Vérifie si le membre peut recevoir sa cagnotte."""
        active_cycle = membership.group.cycles.filter(is_active=True, is_completed=False).first()
        current_queue = QueuePosition.objects.filter(
            cycle=active_cycle,
            is_current=True
        ).first()

        if current_queue and current_queue.membership == membership:
            # C'est son tour, vérifier qu'il n'a pas de dettes
            if membership.debt_count == 0:
                TransactionService.process_payout(membership, active_cycle)

    @staticmethod
    def process_payout(membership, cycle):
        """Effectue le versement de la cagnotte."""
        group = membership.group
        total_payout = group.contribution_net * group.number_of_members

        with transaction.atomic():
            payout = Payout.objects.create(
                cycle=cycle,
                membership=membership,
                amount=total_payout,
                payout_date=timezone.now(),
                cycle_position=membership.queue_position,
                status='validated'
            )

            membership.total_received += total_payout
            membership.has_received_payout = True
            membership.save(update_fields=['total_received', 'has_received_payout'])

            # Marquer comme reçu dans la file
            QueuePosition.objects.filter(cycle=cycle, membership=membership).update(
                is_current=False,
                received_at=timezone.now()
            )

            # Passer au suivant
            next_position = QueuePosition.objects.filter(
                cycle=cycle,
                received_at__isnull=True
            ).order_by('position').first()

            if next_position:
                next_position.is_current = True
                next_position.save(update_fields=['is_current'])
            else:
                # Fin du cycle
                cycle.is_completed = True
                cycle.is_active = False
                cycle.end_date = timezone.now()
                cycle.save()
                group.is_active = False
                group.ended_at = timezone.now()
                group.save()

            return payout
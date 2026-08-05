"""
Services métier pour les calculs financiers du Likelemba.
"""
from decimal import Decimal
from datetime import timedelta
import logging
from django.utils import timezone
from django.db import transaction
from django.db.models import F
from core.exceptions import BusinessLogicError, InsufficientFundsError

logger = logging.getLogger(__name__)


class LikelembaCalculator:
    """Calculateur pour les opérations financières du Likelemba."""

    @staticmethod
    def calculate_refund(
        total_contributed: Decimal,
        days_participated: int,
        total_days: int,
        alpha_0: float
    ) -> Decimal:
        """
        Calcule le montant à rembourser à un membre qui quitte avant d'avoir reçu sa cagnotte.

        Formule: R(τ) = s·τ · [1 - α₀·(1 - τ/T)]
        où τ = days_participated, T = total_days, s·τ = total_contributed

        Args:
            total_contributed: Montant total cotisé par le membre (s·τ)
            days_participated: Nombre de jours de participation (τ)
            total_days: Durée totale du cycle (T)
            alpha_0: Taux de pénalité initial

        Returns:
            Montant à rembourser après pénalité
        """
        if days_participated == 0:
            return Decimal('0')

        # Tout est fait en Decimal : alpha_0 (float, ex. penalty_rate_initial) ne peut
        # pas être multiplié directement par un Decimal (TypeError), et le calcul
        # financier ne doit de toute façon pas transiter par des flottants binaires.
        alpha_0_dec = Decimal(str(alpha_0))
        ratio = Decimal(days_participated) / Decimal(total_days)
        alpha = alpha_0_dec * (1 - ratio)
        refund = total_contributed * (1 - alpha)
        return refund.quantize(Decimal('0.01'))

    @staticmethod
    def calculate_reserve_fund_projection(
        initial_reserve: Decimal,
        daily_inflow_per_member: Decimal,
        number_of_members: int,
        days: int,
        outflows: list = None
    ) -> list:
        """
        Calcule l'évolution du fonds de réserve sur une période donnée.

        Équation différentielle simplifiée: dF/dt = n·a - λ·R(t)
        Ici on utilise une simulation discrète.

        Args:
            initial_reserve: Montant initial du fonds
            daily_inflow_per_member: Prélèvement quotidien par membre (a)
            number_of_members: Nombre de membres actifs (n)
            days: Nombre de jours à simuler
            outflows: Liste de tuples (jour, montant) pour les départs prévus

        Returns:
            Liste des montants du fonds jour par jour
        """
        projection = []
        current = initial_reserve
        daily_inflow_total = daily_inflow_per_member * number_of_members

        outflows_dict = {}
        if outflows:
            outflows_dict = {day: amount for day, amount in outflows}

        for day in range(days + 1):
            if day > 0:
                current += daily_inflow_total
                if day in outflows_dict:
                    current -= outflows_dict[day]
            projection.append(float(current))

        return projection

    @staticmethod
    def calculate_recovery_time(
        deficit: Decimal,
        daily_inflow_total: Decimal
    ) -> float:
        """
        Calcule le temps nécessaire pour reconstituer un déficit.

        Args:
            deficit: Montant du déficit (positif si négatif)
            daily_inflow_total: Entrée quotidienne totale dans le fonds

        Returns:
            Temps en jours
        """
        if deficit <= 0:
            return 0.0
        return float(deficit / daily_inflow_total)


class MembershipService:
    """Service de gestion des adhésions et départs."""

    @staticmethod
    def process_member_exit(membership, exit_date=None):
        """
        Traite le départ d'un membre du groupe.
        Calcule le remboursement, met à jour le fonds et la file d'attente.
        """
        from apps.transactions.models import Refund, Contribution
        from apps.tontines.models import QueuePosition

        if not membership.is_active:
            raise BusinessLogicError("Ce membre a déjà quitté le groupe.")

        group = membership.group
        active_cycle = group.cycles.filter(is_active=True, is_completed=False).first()
        if not active_cycle:
            raise BusinessLogicError("Aucun cycle actif trouvé pour ce groupe.")

        exit_date = exit_date or timezone.now()
        days_participated = (exit_date.date() - active_cycle.start_date.date()).days

        # Déterminer si le membre a déjà reçu sa cagnotte
        has_received = membership.has_received_payout

        with transaction.atomic():
            if has_received:
                # Départ après réception : pas de remboursement
                refund_amount = Decimal('0')
            else:
                # Calcul du total cotisé depuis le début du cycle
                contributions = Contribution.objects.filter(
                    membership=membership,
                    cycle=active_cycle,
                    status='validated'
                )
                total_contributed = sum(c.amount for c in contributions)

                # Calcul du remboursement avec pénalité
                refund_amount = LikelembaCalculator.calculate_refund(
                    total_contributed=total_contributed,
                    days_participated=max(days_participated, 1),
                    total_days=group.cycle_duration_days,
                    alpha_0=group.penalty_rate_initial
                )

                # Vérifier que le fonds peut supporter le remboursement
                if refund_amount > group.reserve_amount:
                    raise InsufficientFundsError(
                        f"Fonds insuffisant. Disponible: {group.reserve_amount}, requis: {refund_amount}"
                    )

                # Créer l'enregistrement de remboursement
                Refund.objects.create(
                    cycle=active_cycle,
                    membership=membership,
                    amount=refund_amount,
                    days_participated=days_participated,
                    penalty_rate_applied=group.penalty_rate_initial * (1 - days_participated / group.cycle_duration_days),
                    status='completed',
                    processed_at=exit_date
                )

                # Mettre à jour le fonds de réserve
                group.reserve_amount -= refund_amount
                group.save(update_fields=['reserve_amount'])

            # Marquer le membre comme inactif
            membership.is_active = False
            membership.left_at = exit_date
            membership.save(update_fields=['is_active', 'left_at'])
            group.recompute_cycle_duration()

            # Retirer de la file d'attente
            QueuePosition.objects.filter(
                cycle=active_cycle,
                membership=membership
            ).delete()

            # Réorganiser les positions restantes
            remaining_positions = QueuePosition.objects.filter(
                cycle=active_cycle
            ).order_by('position')
            for idx, pos in enumerate(remaining_positions, start=1):
                pos.position = idx
                pos.save(update_fields=['position'])

            # Mettre à jour le nombre de membres dans le groupe (le remplacement sera géré séparément)
            logger.info(f"Membre {membership.user.phone_number} a quitté le groupe {group.name}. "
                       f"Remboursement: {refund_amount}")

            return refund_amount

    @staticmethod
    def replace_member(group, replacing_user, position_to_take=None):
        """
        Ajoute un nouveau membre pour remplacer un membre parti, ou réactive
        son ancienne adhésion s'il avait déjà fait partie de ce groupe (la
        contrainte d'unicité user+group interdit une deuxième ligne
        Membership pour le même couple).
        """
        from apps.tontines.models import Membership, Cycle, QueuePosition

        active_cycle = group.cycles.filter(is_active=True, is_completed=False).first()
        if not active_cycle:
            raise BusinessLogicError("Aucun cycle actif.")

        existing = Membership.objects.filter(user=replacing_user, group=group).first()
        if existing and existing.is_active:
            raise BusinessLogicError("Cet utilisateur est déjà membre de ce groupe.")

        with transaction.atomic():
            if existing:
                existing.role = 'member'
                existing.joined_at = timezone.now()
                existing.left_at = None
                existing.is_active = True
                existing.total_contributed = Decimal('0')
                existing.total_received = Decimal('0')
                existing.debt_count = 0
                existing.has_received_payout = False
                existing.save()
                membership = existing
            else:
                membership = Membership.objects.create(
                    user=replacing_user,
                    group=group,
                    role='member',
                    joined_at=timezone.now(),
                    is_active=True
                )
            group.recompute_cycle_duration()

            # Déterminer la position dans la file
            if position_to_take is not None:
                # Insérer à une position spécifique (par exemple celle d'un membre parti)
                QueuePosition.objects.filter(
                    cycle=active_cycle,
                    position__gte=position_to_take
                ).update(position=F('position') + 1)

                QueuePosition.objects.create(
                    cycle=active_cycle,
                    membership=membership,
                    position=position_to_take
                )
            else:
                # Ajouter en fin de file
                last_position = QueuePosition.objects.filter(cycle=active_cycle).count()
                QueuePosition.objects.create(
                    cycle=active_cycle,
                    membership=membership,
                    position=last_position + 1
                )

            logger.info(f"Nouveau membre {replacing_user.phone_number} ajouté au groupe {group.name}")
            return membership

    @staticmethod
    def move_member(membership, target_group):
        """
        Déplace un membre actif vers un autre groupe que le même administrateur
        gère : retire sa position dans la file du groupe source (en réindexant
        les positions restantes), l'ajoute en fin de file du groupe cible, et
        remet à zéro ses statistiques (elles sont propres à chaque groupe).
        """
        from apps.tontines.models import Membership, QueuePosition

        if not membership.is_active:
            raise BusinessLogicError("Ce membre n'est plus actif.")

        if Membership.objects.filter(user=membership.user, group=target_group).exclude(id=membership.id).exists():
            raise BusinessLogicError("Cet utilisateur est déjà membre du groupe cible.")

        target_cycle = target_group.cycles.filter(is_active=True, is_completed=False).first()
        if not target_cycle:
            raise BusinessLogicError("Le groupe cible n'a pas de cycle actif.")

        with transaction.atomic():
            source_group = membership.group
            source_cycle = source_group.cycles.filter(is_active=True, is_completed=False).first()
            if source_cycle:
                QueuePosition.objects.filter(cycle=source_cycle, membership=membership).delete()
                remaining = QueuePosition.objects.filter(cycle=source_cycle).order_by('position')
                for idx, pos in enumerate(remaining, start=1):
                    pos.position = idx
                    pos.save(update_fields=['position'])

            membership.group = target_group
            membership.total_contributed = Decimal('0')
            membership.total_received = Decimal('0')
            membership.debt_count = 0
            membership.has_received_payout = False
            membership.joined_at = timezone.now()
            membership.save()
            source_group.recompute_cycle_duration()
            target_group.recompute_cycle_duration()

            last_position = QueuePosition.objects.filter(cycle=target_cycle).count()
            QueuePosition.objects.create(cycle=target_cycle, membership=membership, position=last_position + 1)

            logger.info(f"Membre {membership.user.phone_number} déplacé vers le groupe {target_group.name}")
            return membership


class JoinRequestService:
    """
    Traitement des demandes d'adhésion. Extrait de JoinRequestViewSet pour être
    partagé entre l'API REST et le tableau de bord admin servi en HTML.
    """

    @staticmethod
    def accept(join_request, processed_by):
        from apps.tontines.models import Membership, QueuePosition

        if join_request.status != 'pending':
            raise BusinessLogicError(
                f"Cette demande a déjà été traitée (statut: {join_request.status})."
            )

        existing = Membership.objects.filter(user=join_request.user, group=join_request.group).first()
        if existing and existing.is_active:
            raise BusinessLogicError("Cet utilisateur est déjà membre de ce groupe.")

        with transaction.atomic():
            join_request.status = 'accepted'
            join_request.processed_by = processed_by
            join_request.processed_at = timezone.now()
            join_request.save(update_fields=['status', 'processed_by', 'processed_at'])

            # Rôle toujours 'member' : le rôle ne peut pas être auto-déclaré par le
            # demandeur (risque d'élévation de privilège).
            if existing:
                # Ancien membre parti : on réactive son adhésion plutôt que
                # d'en créer une nouvelle (contrainte d'unicité user+group).
                existing.role = 'member'
                existing.joined_at = timezone.now()
                existing.left_at = None
                existing.is_active = True
                existing.total_contributed = Decimal('0')
                existing.total_received = Decimal('0')
                existing.debt_count = 0
                existing.has_received_payout = False
                existing.save()
                membership = existing
            else:
                membership = Membership.objects.create(
                    user=join_request.user,
                    group=join_request.group,
                    role='member',
                    joined_at=timezone.now()
                )
            join_request.group.recompute_cycle_duration()

            active_cycle = join_request.group.cycles.filter(is_active=True, is_completed=False).first()
            if active_cycle:
                last_pos = QueuePosition.objects.filter(cycle=active_cycle).count()
                QueuePosition.objects.create(cycle=active_cycle, membership=membership, position=last_pos + 1)

        return membership

    @staticmethod
    def reject(join_request, processed_by, response_message=''):
        if join_request.status != 'pending':
            raise BusinessLogicError(
                f"Cette demande a déjà été traitée (statut: {join_request.status})."
            )

        join_request.status = 'rejected'
        join_request.processed_by = processed_by
        join_request.processed_at = timezone.now()
        join_request.response_message = response_message
        join_request.save(update_fields=['status', 'processed_by', 'processed_at', 'response_message'])
        return join_request


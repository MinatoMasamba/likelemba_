"""
Services pour les projections financières et l'analyse de risque.
"""
from decimal import Decimal
from django.db.models import Sum
from django.utils import timezone
from apps.tontines.services import LikelembaCalculator


class ProjectionService:
    """Service de projection du fonds de réserve avec EDO."""

    @staticmethod
    def solve_edo(
        n: int,
        a: Decimal,
        alpha_0: float,
        T: int,
        initial_reserve: Decimal = Decimal('0'),
        lambda_rate: float = 0.0,
        s: Decimal = None
    ) -> dict:
        """
        Résout numériquement l'équation différentielle du fonds de réserve.

        dF/dt = n·a - λ·R(t)
        où R(t) = s·t·[1 - α₀·(1 - t/T)]

        Retourne les valeurs de t et F(t).
        """
        t_values = list(range(T + 1))
        F_values = []
        current_F = float(initial_reserve)

        for t in t_values:
            if t > 0:
                daily_inflow = float(n * a)
                if lambda_rate > 0 and s is not None:
                    # Calcul du remboursement théorique si un départ avait lieu à cet instant
                    R = LikelembaCalculator.calculate_refund(
                        total_contributed=s * Decimal(t),
                        days_participated=int(t),
                        total_days=T,
                        alpha_0=alpha_0
                    )
                    # Le terme de sortie est λ·R(t)
                    outflow = lambda_rate * float(R)
                else:
                    outflow = 0
                current_F += daily_inflow - outflow
            F_values.append(current_F)

        return {
            't': t_values,
            'F': F_values
        }

    @staticmethod
    def simulate_exits(
        group,
        exit_scenarios: list,
        days: int = None
    ) -> list:
        """
        Simule plusieurs scénarios de départs pour évaluer la robustesse du fonds.
        """
        if days is None:
            days = group.cycle_duration_days

        results = []
        base_projection = ProjectionService.solve_edo(
            n=group.number_of_members,
            a=group.security_levy,
            alpha_0=group.penalty_rate_initial,
            T=days,
            initial_reserve=group.reserve_amount,
            s=group.contribution_amount
        )

        for scenario in exit_scenarios:
            # scenario: liste de (jour, nombre_de_départs)
            projection = base_projection['F'].copy()
            for exit_day, count in scenario:
                if exit_day < days:
                    # Calculer l'impact
                    impact = count * float(LikelembaCalculator.calculate_refund(
                        total_contributed=group.contribution_amount * exit_day,
                        days_participated=exit_day,
                        total_days=days,
                        alpha_0=group.penalty_rate_initial
                    ))
                    # Appliquer l'impact à partir du jour du départ
                    for i in range(exit_day, len(projection)):
                        projection[i] -= impact
            results.append({
                'scenario': scenario,
                'projection': projection,
                'final_value': projection[-1],
                'min_value': min(projection),
                'is_solvent': all(v >= 0 for v in projection)
            })

        return results


class RiskService:
    """
    Scores de risque dérivés des données réelles déjà enregistrées (dettes,
    incidents passés). Ce ne sont pas des sorties d'un modèle d'apprentissage
    automatique — le champ `UserProfile.risk_score` prévu pour ça n'est
    alimenté par aucune logique dans ce projet — mais des heuristiques
    simples et explicables, suffisantes pour signaler les cas à surveiller.
    """

    @staticmethod
    def member_risk_score(membership) -> int:
        """
        Score de risque individuel (0 = fiable, 100 = très risqué), à partir
        des dettes dans CE groupe et de l'historique global de l'utilisateur.
        """
        profile = getattr(membership.user, 'profile', None)
        successful_cycles = profile.successful_cycles if profile else 0
        default_count = profile.default_count if profile else 0
        score = 15 + membership.debt_count * 18 + default_count * 15 - successful_cycles * 6
        return max(5, min(95, round(score)))

    @staticmethod
    def group_risk_score(group) -> int:
        """
        Score de fiabilité du groupe (0 = à risque, 100 = sain), pénalisé par
        le nombre de membres endettés et par le retard du bénéficiaire actuel
        de la file par rapport à son tour théorique.
        """
        debt_count = group.members.filter(is_active=True, debt_count__gt=0).count()

        overdue_days = 0
        active_cycle = group.cycles.filter(is_active=True, is_completed=False).first()
        if active_cycle:
            current = active_cycle.queue.filter(is_current=True).first()
            if current:
                expected_day = current.position * group.distribution_interval_days
                overdue_days = max(0, group.elapsed_days - expected_day)

        score = 100 - debt_count * 22 - overdue_days * 8
        return max(0, min(100, score))


class GroupHistoryService:
    """
    Reconstitue l'évolution *observée* d'un groupe (argent et membres) à partir
    des mouvements réels enregistrés, par opposition à ProjectionService qui
    calcule une trajectoire *théorique* à partir des paramètres de l'EDO.
    """

    @staticmethod
    def money_summary(group) -> dict:
        """Total cumulé, depuis le début du groupe, de chaque type de flux."""
        from apps.transactions.models import Contribution, Payout, Refund

        total_contributed = Contribution.objects.filter(
            membership__group=group, status='validated'
        ).aggregate(total=Sum('amount'))['total'] or Decimal('0')

        total_paid_out = Payout.objects.filter(
            membership__group=group
        ).aggregate(total=Sum('amount'))['total'] or Decimal('0')

        total_refunded = Refund.objects.filter(
            membership__group=group
        ).aggregate(total=Sum('amount'))['total'] or Decimal('0')

        return {
            'reserve_amount': group.reserve_amount,
            'total_contributed': total_contributed,
            'total_paid_out': total_paid_out,
            'total_refunded': total_refunded,
        }

    @staticmethod
    def reserve_timeline(group) -> list:
        """
        Série chronologique du fonds de réserve reconstituée à partir des
        mouvements réels : chaque cotisation validée ajoute `security_levy`
        au fonds, chaque remboursement en soustrait son montant. C'est
        l'évolution effectivement survenue, pas une projection.
        """
        from apps.transactions.models import Contribution, Refund

        events = []
        for c in Contribution.objects.filter(
            membership__group=group, status='validated'
        ).exclude(validated_at__isnull=True):
            events.append((c.validated_at, group.security_levy))

        for r in Refund.objects.filter(membership__group=group).exclude(processed_at__isnull=True):
            events.append((r.processed_at, -r.amount))

        events.sort(key=lambda e: e[0])

        timeline = []
        running = Decimal('0')
        for ts, delta in events:
            running += delta
            timeline.append({'date': ts, 'amount': running})
        return timeline

    @staticmethod
    def member_timeline(group) -> list:
        """Chronologie des arrivées et départs de membres, la plus récente en tête."""
        events = []
        for membership in group.members.select_related('user').all():
            events.append({
                'date': membership.joined_at,
                'type': 'arrivee',
                'membership': membership,
            })
            if membership.left_at:
                events.append({
                    'date': membership.left_at,
                    'type': 'depart',
                    'membership': membership,
                })
        events.sort(key=lambda e: e['date'], reverse=True)
        return events
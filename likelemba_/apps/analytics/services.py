"""
Services pour les projections financières et l'analyse de risque.
"""
import numpy as np
from decimal import Decimal
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
        t_values = np.linspace(0, T, num=T+1)
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
            't': t_values.tolist(),
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
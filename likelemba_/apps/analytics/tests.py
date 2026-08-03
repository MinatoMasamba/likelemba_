"""
Tests du solveur EDO (projection du fonds de réserve).
"""
from decimal import Decimal

from django.test import SimpleTestCase

from .services import ProjectionService


class SolveEdoTests(SimpleTestCase):

    def test_nominal_growth_without_departures(self):
        result = ProjectionService.solve_edo(
            n=19, a=Decimal('175'), alpha_0=0.15, T=5,
            initial_reserve=Decimal('1000')
        )
        # dF/dt = n·a = 3325/jour, sans sortie (lambda_rate=0)
        self.assertEqual(len(result['F']), 6)
        self.assertEqual(result['F'][0], 1000.0)
        for day in range(1, 6):
            self.assertAlmostEqual(result['F'][day], 1000.0 + 3325.0 * day)

    def test_departure_rate_reduces_the_fund_without_raising(self):
        """
        Régression : avec lambda_rate > 0, solve_edo() appelle en interne
        LikelembaCalculator.calculate_refund(), qui mélangeait auparavant
        Decimal et float (TypeError à chaque appel).
        """
        with_departures = ProjectionService.solve_edo(
            n=19, a=Decimal('175'), alpha_0=0.15, T=10,
            initial_reserve=Decimal('1000'),
            lambda_rate=0.2,
            s=Decimal('5000')
        )
        nominal = ProjectionService.solve_edo(
            n=19, a=Decimal('175'), alpha_0=0.15, T=10,
            initial_reserve=Decimal('1000')
        )

        self.assertEqual(len(with_departures['F']), 11)
        self.assertLess(with_departures['F'][-1], nominal['F'][-1])

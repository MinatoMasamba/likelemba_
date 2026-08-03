"""
Tests du moteur financier Likelemba (pénalité dégressive, projection du fonds,
et régressions sur des bugs identifiés en revue de code).
"""
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.test import SimpleTestCase, TestCase
from rest_framework import status
from rest_framework.test import APIClient

from .models import Cycle, LikelembaGroup, Membership, QueuePosition
from .services import LikelembaCalculator, MembershipService

User = get_user_model()


class CalculateRefundTests(SimpleTestCase):
    """R(τ) = s·τ · [1 - α₀·(1 - τ/T)]"""

    def test_no_participation_returns_zero(self):
        self.assertEqual(
            LikelembaCalculator.calculate_refund(Decimal('60000'), 0, 57, 0.15),
            Decimal('0')
        )

    def test_matches_worked_example_from_edo_docs(self):
        # "Modélisation EDO du Likelemba Sécurisé" : τ=12, T=57, s·τ=60000, α0=0.15
        # -> pénalité ≈ 11.84 %. Le document arrondit la pénalité avant de multiplier
        # (d'où son résultat de 52 896 FC) ; ce test suit le calcul exact et non
        # arrondi de l'implémentation, qui sert de référence de non-régression.
        refund = LikelembaCalculator.calculate_refund(
            total_contributed=Decimal('60000'),
            days_participated=12,
            total_days=57,
            alpha_0=0.15
        )
        self.assertEqual(refund, Decimal('52894.74'))

    def test_no_penalty_at_end_of_cycle(self):
        # τ = T => α(τ) = 0 => remboursement intégral
        refund = LikelembaCalculator.calculate_refund(
            total_contributed=Decimal('100000'),
            days_participated=57,
            total_days=57,
            alpha_0=0.25
        )
        self.assertEqual(refund, Decimal('100000.00'))

    def test_near_maximum_penalty_on_day_one(self):
        # alpha ≈ 0.20 * (1 - 1/1000) = 0.1998 -> refund ≈ 1000 * 0.8002 = 800.20
        refund = LikelembaCalculator.calculate_refund(
            total_contributed=Decimal('1000'),
            days_participated=1,
            total_days=1000,
            alpha_0=0.20
        )
        self.assertEqual(refund, Decimal('800.20'))

    def test_accepts_float_alpha_0_like_the_model_field(self):
        """
        Régression : `penalty_rate_initial` est un FloatField côté modèle.
        `calculate_refund` mélangeait auparavant Decimal et float dans une
        multiplication, ce qui levait TypeError à chaque appel réel.
        """
        alpha_0_from_model = 0.15  # type(float), comme LikelembaGroup.penalty_rate_initial
        try:
            LikelembaCalculator.calculate_refund(Decimal('5000'), 3, 30, alpha_0_from_model)
        except TypeError:
            self.fail("calculate_refund lève TypeError avec un alpha_0 float (Decimal * float)")


class CalculateReserveFundProjectionTests(SimpleTestCase):

    def test_linear_growth_without_outflows(self):
        projection = LikelembaCalculator.calculate_reserve_fund_projection(
            initial_reserve=Decimal('0'),
            daily_inflow_per_member=Decimal('175'),
            number_of_members=19,
            days=5
        )
        # dF/dt = n·a = 19*175 = 3325/jour
        self.assertEqual(len(projection), 6)  # jours 0..5 inclus
        self.assertEqual(projection[0], 0.0)
        for day in range(1, 6):
            self.assertAlmostEqual(projection[day], 3325.0 * day)

    def test_outflow_reduces_fund_from_its_day_onward(self):
        projection = LikelembaCalculator.calculate_reserve_fund_projection(
            initial_reserve=Decimal('1000'),
            daily_inflow_per_member=Decimal('100'),
            number_of_members=1,
            days=4,
            outflows=[(2, Decimal('50'))]
        )
        self.assertEqual(projection, [1000.0, 1100.0, 1150.0, 1250.0, 1350.0])


class CalculateRecoveryTimeTests(SimpleTestCase):

    def test_no_deficit_means_no_recovery_time(self):
        self.assertEqual(
            LikelembaCalculator.calculate_recovery_time(Decimal('0'), Decimal('500')),
            0.0
        )

    def test_positive_deficit(self):
        recovery = LikelembaCalculator.calculate_recovery_time(Decimal('1000'), Decimal('250'))
        self.assertEqual(recovery, 4.0)


class ReplaceMemberAtPositionRegressionTests(TestCase):
    """
    Régression sur le bug #3 de l'audit : un mauvais import (`from apps.users
    import models` au lieu de `django.db.models`) faisait planter tout
    remplacement de membre à une position précise de la file d'attente.
    """

    def setUp(self):
        self.admin_user = User.objects.create_user(
            phone_number='+243900000001', password='pass1234', full_name='Admin Test'
        )
        self.group = LikelembaGroup.objects.create(
            name='Groupe Test',
            contribution_amount=Decimal('5000'),
            security_levy=Decimal('175'),
            cycle_duration_days=57,
            created_by=self.admin_user,
        )
        self.cycle = Cycle.objects.create(group=self.group, sequence_number=1)

        self.member1 = Membership.objects.create(user=self.admin_user, group=self.group, role='admin')
        QueuePosition.objects.create(cycle=self.cycle, membership=self.member1, position=1)

        other_user = User.objects.create_user(
            phone_number='+243900000002', password='pass1234', full_name='Membre 2'
        )
        self.member2 = Membership.objects.create(user=other_user, group=self.group, role='member')
        QueuePosition.objects.create(cycle=self.cycle, membership=self.member2, position=2)

        self.replacing_user = User.objects.create_user(
            phone_number='+243900000003', password='pass1234', full_name='Remplaçant'
        )

    def test_replace_member_at_specific_position_shifts_queue(self):
        membership = MembershipService.replace_member(
            group=self.group,
            replacing_user=self.replacing_user,
            position_to_take=1
        )

        positions = list(
            QueuePosition.objects.filter(cycle=self.cycle)
            .order_by('position')
            .values_list('position', flat=True)
        )
        self.assertEqual(positions, [1, 2, 3])

        new_position = QueuePosition.objects.get(cycle=self.cycle, membership=membership)
        self.assertEqual(new_position.position, 1)

        shifted = QueuePosition.objects.get(cycle=self.cycle, membership=self.member1)
        self.assertEqual(shifted.position, 2)


class GroupCreationRegressionTests(TestCase):
    """
    Régression sur le bug #1 (import `timezone` erroné, qui faisait planter la
    création de groupe) et sur le rôle attribué au créateur du groupe, qui doit
    être 'admin' pour pouvoir administrer son propre groupe par la suite.
    """

    def setUp(self):
        self.user = User.objects.create_user(
            phone_number='+243900000010', password='pass1234', full_name='Créateur'
        )
        self.client = APIClient()
        self.client.force_authenticate(user=self.user)

    def test_creating_a_group_creates_an_admin_membership(self):
        response = self.client.post('/api/v1/tontines/groups/', {
            'name': 'Mon Groupe',
            'contribution_amount': '5000',
            'security_levy': '175',
            'cycle_duration_days': 57,
        }, format='json')

        self.assertEqual(response.status_code, status.HTTP_201_CREATED, response.data)
        group = LikelembaGroup.objects.get(name='Mon Groupe')
        membership = Membership.objects.get(user=self.user, group=group)
        self.assertEqual(membership.role, 'admin')


class JoinRequestAcceptRegressionTests(TestCase):
    """
    Régression sur le bug #5 : `join_request.user.profile.preferred_role`
    référençait un champ inexistant sur UserProfile et faisait planter toute
    acceptation de demande d'adhésion.
    """

    def setUp(self):
        self.admin_user = User.objects.create_user(
            phone_number='+243900000020', password='pass1234', full_name='Admin'
        )
        self.group = LikelembaGroup.objects.create(
            name='Groupe Adhésion',
            contribution_amount=Decimal('5000'),
            security_levy=Decimal('175'),
            cycle_duration_days=57,
            created_by=self.admin_user,
        )
        Membership.objects.create(user=self.admin_user, group=self.group, role='admin')

        self.applicant = User.objects.create_user(
            phone_number='+243900000021', password='pass1234', full_name='Candidat'
        )
        from .models import JoinRequest
        self.join_request = JoinRequest.objects.create(user=self.applicant, group=self.group)

        self.client = APIClient()
        self.client.force_authenticate(user=self.admin_user)

    def test_accepting_a_join_request_creates_a_member_role_membership(self):
        response = self.client.patch(f'/api/v1/tontines/join-requests/{self.join_request.id}/accept/')

        self.assertEqual(response.status_code, status.HTTP_200_OK, response.data)
        membership = Membership.objects.get(user=self.applicant, group=self.group)
        self.assertEqual(membership.role, 'member')

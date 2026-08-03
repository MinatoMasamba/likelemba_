"""
Tests du tableau de bord HTML : rendu des pages et actions admin de base.
"""
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.urls import reverse

from apps.tontines.models import Cycle, JoinRequest, LikelembaGroup, Membership

User = get_user_model()


class LoginPageTests(TestCase):

    def test_login_page_renders(self):
        response = self.client.get(reverse('dashboard:login'))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Numéro de téléphone")

    def test_group_list_requires_login(self):
        response = self.client.get(reverse('dashboard:group_list'))
        self.assertEqual(response.status_code, 302)
        self.assertIn(reverse('dashboard:login'), response.url)


class GroupDetailDashboardTests(TestCase):

    def setUp(self):
        self.admin_user = User.objects.create_user(
            phone_number='+243911000001', password='pass1234', full_name='Admin Dashboard'
        )
        self.group = LikelembaGroup.objects.create(
            name='Groupe Dashboard',
            contribution_amount=Decimal('5000'),
            security_levy=Decimal('175'),
            cycle_duration_days=57,
            created_by=self.admin_user,
        )
        Cycle.objects.create(group=self.group, sequence_number=1)
        Membership.objects.create(user=self.admin_user, group=self.group, role='admin')

        self.member_user = User.objects.create_user(
            phone_number='+243911000002', password='pass1234', full_name='Membre Simple'
        )
        Membership.objects.create(user=self.member_user, group=self.group, role='member')

        self.applicant = User.objects.create_user(
            phone_number='+243911000003', password='pass1234', full_name='Candidat Dashboard'
        )
        self.join_request = JoinRequest.objects.create(user=self.applicant, group=self.group)

    def test_admin_sees_administration_section(self):
        self.client.login(username='+243911000001', password='pass1234')
        response = self.client.get(reverse('dashboard:group_detail', kwargs={'group_id': self.group.id}))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "Administration")
        self.assertContains(response, "Candidat Dashboard")

    def test_regular_member_does_not_see_administration_section(self):
        self.client.login(username='+243911000002', password='pass1234')
        response = self.client.get(reverse('dashboard:group_detail', kwargs={'group_id': self.group.id}))
        self.assertEqual(response.status_code, 200)
        self.assertNotContains(response, "Administration")

    def test_admin_can_accept_join_request(self):
        self.client.login(username='+243911000001', password='pass1234')
        response = self.client.post(
            reverse('dashboard:join_request_accept', kwargs={'pk': self.join_request.id})
        )
        self.assertRedirects(response, reverse('dashboard:group_detail', kwargs={'group_id': self.group.id}))
        self.assertTrue(Membership.objects.filter(user=self.applicant, group=self.group).exists())

    def test_non_admin_cannot_accept_join_request(self):
        self.client.login(username='+243911000002', password='pass1234')
        self.client.post(reverse('dashboard:join_request_accept', kwargs={'pk': self.join_request.id}))
        self.assertFalse(Membership.objects.filter(user=self.applicant, group=self.group).exists())

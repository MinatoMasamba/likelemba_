from decimal import Decimal

from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from apps.tontines.models import Cycle, LikelembaGroup, Membership, QueuePosition
from apps.transactions.models import Contribution, Payout, Refund
from apps.users.models import User, UserProfile


class Command(BaseCommand):
    help = "Crée 15 tontines de démonstration avec membres, paiements et scénarios métier."

    GROUPS = [
        ("Bakolo ya Mbongo", "nominal", 5000, 500, 10, 18, 3, 125000),
        ("Famille Kinshasa", "pending", 3500, 350, 12, 9, 3, 76000),
        ("Epargne Bureau", "eligible", 7000, 700, 8, 6, 3, 98000),
        ("Mamas Solidaires", "late_debt", 4500, 450, 14, 22, 7, 146000),
        ("Jeunes Entrepreneurs", "early_exit", 6000, 600, 9, 11, 3, 84000),
        ("Matonge Express", "post_payout_exit", 4000, 400, 11, 27, 3, 112000),
        ("Kasa Vubu Pro", "replacement", 8000, 800, 10, 15, 5, 188000),
        ("Diaspora Lisanga", "critical", 10000, 1000, 15, 34, 7, 252000),
        ("Biso Na Biso", "new_member", 3000, 300, 7, 4, 3, 36000),
        ("Ndako Ya Bomoi", "completed_members", 5500, 550, 13, 31, 7, 198000),
        ("Lemba Sécurité", "no_replacement", 6500, 650, 10, 19, 5, 115000),
        ("Bandeko Reserve", "reserve_shock", 7500, 750, 12, 24, 6, 94000),
        ("Marché Central", "high_trust", 2500, 250, 16, 12, 3, 72000),
        ("Campus Tontine", "multiple_pending", 2000, 200, 18, 8, 3, 51000),
        ("Mama Mobokoli", "late_cycle", 9000, 900, 9, 25, 5, 166000),
    ]

    MEMBER_NAMES = [
        "Nadine Beya",
        "Jean-Pierre Kanku",
        "Grace Nsimba",
        "Alain Mutombo",
        "Carine Ilunga",
        "Patrick Mbuyi",
        "Sarah Lofombo",
        "Joel Makiese",
        "Chantal Moke",
        "David Tshibangu",
        "Esther Kalonji",
        "Moise Kabeya",
        "Linda Mbala",
        "Cedric Mpoyi",
        "Aline Kitenge",
        "Kevin Lukusa",
        "Mireille Mbungu",
        "Blaise Kabasele",
    ]

    def add_arguments(self, parser):
        parser.add_argument("--password", default="LikelembaTest123")

    @transaction.atomic
    def handle(self, *args, **options):
        admin = self._user(
            "+243810000001",
            "Admin Démo Likelemba",
            "admin.demo@likelemba.test",
            "admin",
            options["password"],
        )
        demo_member = self._user(
            "+243810000002",
            "Membre Démo Likelemba",
            "membre.demo@likelemba.test",
            "participant",
            options["password"],
        )
        self._profile(demo_member, 18, 234000, 116000, 4)
        self._profile(admin, 12, 0, 0, 7)

        seed_members = [
            self._user(
                f"+24382000{index:04d}",
                name,
                f"mock{index}@likelemba.test",
                "participant",
                options["password"],
            )
            for index, name in enumerate(self.MEMBER_NAMES, start=1)
        ]
        created = 0
        for index, spec in enumerate(self.GROUPS, start=1):
            all_members = list(User.objects.filter(is_active=True).order_by("id"))
            group = self._group(index, spec, admin)
            cycle = self._cycle(group)
            self._clear_group_transactions(group)
            self._memberships(group, cycle, admin, demo_member, all_members, spec)
            created += 1

        self.stdout.write(self.style.SUCCESS(
            f"{created} tontines mock prêtes. Connexion: membre.demo@likelemba.test / {options['password']}"
        ))

    def _user(self, phone, full_name, email, account_type, password):
        user, _created = User.objects.get_or_create(
            phone_number=phone,
            defaults={
                "full_name": full_name,
                "email": email,
                "account_type": account_type,
                "phone_verified": True,
                "email_verified": True,
            },
        )
        updates = {
            "full_name": full_name,
            "email": email,
            "account_type": account_type,
            "phone_verified": True,
            "email_verified": True,
        }
        for field, value in updates.items():
            setattr(user, field, value)
        user.set_password(password)
        user.save()
        return user

    def _profile(self, user, risk, contributed, received, cycles):
        profile, _created = UserProfile.objects.get_or_create(user=user)
        profile.risk_score = risk
        profile.total_contributions = Decimal(str(contributed))
        profile.total_received = Decimal(str(received))
        profile.successful_cycles = cycles
        profile.default_count = 0 if risk < 35 else 2
        profile.notification_enabled = True
        profile.language = "fr"
        profile.save()

    def _group(self, index, spec, admin):
        name, scenario, contribution, levy, members_count, elapsed_days, interval, reserve = spec
        invite_code = f"MOCK{index:04d}"
        group = LikelembaGroup.objects.filter(invite_code=invite_code).first()
        if group is None:
            group = LikelembaGroup(invite_code=invite_code)
        group.name = name
        group.description = f"Scénario test: {scenario.replace('_', ' ')}."
        group.contribution_amount = Decimal(str(contribution))
        group.security_levy = Decimal(str(levy))
        group.penalty_rate_initial = 0.25 if scenario in {"critical", "reserve_shock"} else 0.15
        group.cycle_duration_days = members_count * interval
        group.distribution_interval_days = interval
        group.regeneration_target_days = 3
        group.reserve_amount = Decimal(str(reserve))
        group.started_at = timezone.now() - timezone.timedelta(days=elapsed_days)
        group.is_active = True
        group.is_locked = True
        group.locked_at = group.started_at
        group.created_by = admin
        group.save()
        return group

    def _cycle(self, group):
        cycle, _created = Cycle.objects.get_or_create(
            group=group,
            sequence_number=1,
            defaults={"start_date": group.started_at or timezone.now()},
        )
        cycle.start_date = group.started_at or timezone.now()
        cycle.is_active = True
        cycle.is_completed = False
        cycle.total_contributions_collected = Decimal("0")
        cycle.total_refunds_paid = Decimal("0")
        cycle.save()
        return cycle

    def _clear_group_transactions(self, group):
        memberships = Membership.objects.filter(group=group)
        Contribution.objects.filter(membership__in=memberships).delete()
        Refund.objects.filter(membership__in=memberships).delete()
        Payout.objects.filter(membership__in=memberships).delete()
        QueuePosition.objects.filter(membership__in=memberships).delete()
        memberships.delete()

    def _memberships(self, group, cycle, admin, demo_member, reusable_members, spec):
        _name, scenario, contribution, _levy, members_count, elapsed_days, _interval, _reserve = spec
        users = [demo_member] + [user for user in reusable_members if user != demo_member]
        members_count = len(users)
        group.cycle_duration_days = members_count * group.distribution_interval_days
        group.save(update_fields=["cycle_duration_days"])
        current_position = min(max(1, elapsed_days // max(group.distribution_interval_days, 1) + 1), members_count)

        for position, user in enumerate(users, start=1):
            membership = Membership.objects.create(
                user=user,
                group=group,
                role="admin" if user == admin else "member",
                queue_position=position,
                total_contributed=Decimal(str(contribution * max(elapsed_days - (position % 3), 1))),
                total_received=Decimal("0"),
                debt_count=0,
                has_received_payout=False,
                joined_at=group.started_at + timezone.timedelta(days=position % 4),
            )
            if position < current_position:
                membership.has_received_payout = True
                membership.total_received = group.calculate_net_jackpot()
            if user == demo_member and scenario == "eligible":
                current_position = position
                membership.has_received_payout = False
            if scenario in {"late_debt", "critical"} and position in {3, 5, 7}:
                membership.debt_count = 2 if scenario == "critical" else 1
            membership.save()

            QueuePosition.objects.create(
                cycle=cycle,
                membership=membership,
                position=position,
                is_current=position == current_position,
                received_at=group.started_at + timezone.timedelta(days=position * group.distribution_interval_days)
                if membership.has_received_payout else None,
            )
            self._transactions(group, cycle, membership, position, scenario, elapsed_days)

        if scenario in {"early_exit", "replacement", "no_replacement", "reserve_shock"}:
            leaver = Membership.objects.filter(group=group, queue_position=members_count).first()
            if leaver:
                Refund.objects.create(
                    cycle=cycle,
                    membership=leaver,
                    amount=leaver.total_contributed * Decimal("0.85"),
                    status="validated",
                    validated_by=admin,
                    validated_at=timezone.now() - timezone.timedelta(days=1),
                    days_participated=max(group.elapsed_days, 1),
                    penalty_rate_applied=group.penalty_rate_initial,
                    processed_at=timezone.now() - timezone.timedelta(days=1),
                    notes=f"Scénario {scenario}: retrait anticipé avec pénalité dégressive.",
                )

        if scenario == "post_payout_exit":
            beneficiary = Membership.objects.filter(group=group, has_received_payout=True).first()
            if beneficiary:
                beneficiary.left_at = timezone.now() - timezone.timedelta(days=2)
                beneficiary.save(update_fields=["left_at"])

    def _transactions(self, group, cycle, membership, position, scenario, elapsed_days):
        contribution_amount = group.contribution_amount
        paid_days = min(elapsed_days, 8)
        for day in range(max(paid_days, 1)):
            status = "validated"
            is_late = False
            if scenario in {"pending", "multiple_pending"} and position in {1, 4, 8} and day == paid_days - 1:
                status = "pending"
            if scenario in {"late_debt", "critical"} and position in {3, 5, 7}:
                is_late = True
            Contribution.objects.create(
                cycle=cycle,
                membership=membership,
                amount=contribution_amount,
                status=status,
                validated_by=group.created_by if status == "validated" else None,
                validated_at=timezone.now() - timezone.timedelta(days=max(elapsed_days - day, 0))
                if status == "validated" else None,
                due_date=(group.started_at + timezone.timedelta(days=day)).date(),
                is_late=is_late,
                notes=f"Mock {scenario}",
            )
        if membership.has_received_payout:
            Payout.objects.create(
                cycle=cycle,
                membership=membership,
                amount=group.calculate_net_jackpot(),
                status="validated",
                validated_by=group.created_by,
                validated_at=timezone.now() - timezone.timedelta(days=2),
                payout_date=timezone.now() - timezone.timedelta(days=2),
                cycle_position=position,
                notes=f"Cagnotte validée pour scénario {scenario}.",
            )

"""
Vues du tableau de bord HTML : authentification par session Django, distincte
du JWT utilisé par l'API REST (/api/v1/...). Ce tableau réutilise directement
les services métier existants — aucune règle n'est dupliquée depuis l'API.
"""
from django.contrib import messages
from django.contrib.auth import login
from django.contrib.auth.decorators import login_required
from django.shortcuts import get_object_or_404, redirect, render
from django.views.decorators.http import require_POST

from apps.analytics.services import GroupHistoryService, ProjectionService
from apps.tontines.models import JoinRequest, LikelembaGroup, Membership, QueuePosition
from apps.tontines.services import JoinRequestService, MembershipService
from apps.transactions.models import Contribution
from apps.transactions.services import TransactionService
from apps.users.models import User
from core.exceptions import AppException

from .forms import MemberReplaceForm, SignupForm


def signup(request):
    if request.user.is_authenticated:
        return redirect('dashboard:group_list')

    if request.method == 'POST':
        form = SignupForm(request.POST)
        if form.is_valid():
            user = form.save()
            login(request, user, backend='apps.users.backends.EmailBackend')
            messages.success(request, "Compte créé avec succès. Bienvenue !")
            return redirect('dashboard:group_list')
    else:
        initial_role = 'admin' if request.GET.get('role') == 'admin' else 'participant'
        form = SignupForm(initial={'account_type': initial_role})

    return render(request, 'dashboard/signup.html', {'form': form})


def _get_membership_or_404(request, group_id):
    """
    Renvoie (groupe, adhésion, est_admin) pour l'utilisateur connecté.
    404 si l'utilisateur n'est pas membre actif du groupe (sauf superuser).
    """
    group = get_object_or_404(LikelembaGroup, id=group_id)
    if request.user.is_superuser:
        membership = Membership.objects.filter(group=group, user=request.user, is_active=True).first()
        return group, membership, True
    membership = get_object_or_404(Membership, group=group, user=request.user, is_active=True)
    return group, membership, membership.role == 'admin'


def _build_chart_points(timeline, current_amount, width=560, height=160, padding=12):
    """Construit les coordonnées d'une polyline SVG à partir de l'évolution du fonds."""
    values = [float(point['amount']) for point in timeline]
    if not values:
        values = [float(current_amount)]
    if len(values) == 1:
        values = [0.0, values[0]]

    min_v, max_v = min(values), max(values)
    span = (max_v - min_v) or 1.0
    n = len(values)
    step = (width - 2 * padding) / (n - 1) if n > 1 else 0

    coords = []
    for i, v in enumerate(values):
        x = padding + i * step
        y = height - padding - ((v - min_v) / span) * (height - 2 * padding)
        coords.append(f"{x:.1f},{y:.1f}")

    return {
        'points': ' '.join(coords),
        'width': width,
        'height': height,
        'min_value': min_v,
        'max_value': max_v,
    }


@login_required
def group_list(request):
    memberships = (
        Membership.objects.filter(user=request.user, is_active=True)
        .select_related('group')
        .order_by('-group__created_at')
    )
    return render(request, 'dashboard/group_list.html', {'memberships': memberships})


@login_required
def group_detail(request, group_id):
    group, membership, is_admin = _get_membership_or_404(request, group_id)

    active_cycle = group.cycles.filter(is_active=True, is_completed=False).first()

    money = GroupHistoryService.money_summary(group)
    reserve_timeline = GroupHistoryService.reserve_timeline(group)
    member_timeline = GroupHistoryService.member_timeline(group)[:15]
    chart_points = _build_chart_points(reserve_timeline, group.reserve_amount)

    # Projection théorique (EDO) sur la durée déjà écoulée, pour comparer à
    # l'évolution réellement observée du fonds.
    projection_final = None
    if active_cycle:
        days_elapsed = max(group.elapsed_days, 1)
        projection = ProjectionService.solve_edo(
            n=group.number_of_members or 1,
            a=group.security_levy,
            alpha_0=group.penalty_rate_initial,
            T=min(days_elapsed, group.cycle_duration_days),
        )
        projection_final = projection['F'][-1]

    members = list(group.members.select_related('user').all())
    active_members = [m for m in members if m.is_active]
    contributors = [m for m in active_members if not m.has_received_payout and m.debt_count == 0]
    future_commitments = [m for m in active_members if not m.has_received_payout]
    exited = [m for m in members if not m.is_active]
    new_additions = (
        [m for m in active_members if group.started_at and m.joined_at > group.started_at]
        if group.started_at else []
    )

    queue = []
    pending_contributions = []
    pending_join_requests = []
    if is_admin:
        if active_cycle:
            queue = (
                QueuePosition.objects.filter(cycle=active_cycle)
                .select_related('membership__user')
                .order_by('position')
            )
        pending_contributions = (
            Contribution.objects.filter(membership__group=group, status='pending')
            .select_related('membership__user')
            .order_by('created_at')
        )
        pending_join_requests = (
            JoinRequest.objects.filter(group=group, status='pending')
            .select_related('user')
            .order_by('-created_at')
        )

    return render(request, 'dashboard/group_detail.html', {
        'group': group,
        'membership': membership,
        'is_admin': is_admin,
        'active_cycle': active_cycle,
        'money': money,
        'reserve_timeline': list(reversed(reserve_timeline[-15:])),
        'member_timeline': member_timeline,
        'chart_points': chart_points,
        'projection_final': projection_final,
        'contributors': contributors,
        'future_commitments': future_commitments,
        'exited': exited,
        'new_additions': new_additions,
        'queue': queue,
        'pending_contributions': pending_contributions,
        'pending_join_requests': pending_join_requests,
        'replace_form': MemberReplaceForm(),
    })


@require_POST
@login_required
def member_exit(request, group_id, membership_id):
    group, _membership, is_admin = _get_membership_or_404(request, group_id)
    if not is_admin:
        messages.error(request, "Vous n'êtes pas administrateur de ce groupe.")
        return redirect('dashboard:group_detail', group_id=group.id)

    target = get_object_or_404(Membership, id=membership_id, group=group)
    try:
        refund = MembershipService.process_member_exit(target)
        messages.success(request, f"{target.user.full_name} retiré du groupe. Remboursement : {refund} FC.")
    except AppException as exc:
        messages.error(request, str(exc.detail))
    return redirect('dashboard:group_detail', group_id=group.id)


@require_POST
@login_required
def member_replace(request, group_id):
    group, _membership, is_admin = _get_membership_or_404(request, group_id)
    if not is_admin:
        messages.error(request, "Vous n'êtes pas administrateur de ce groupe.")
        return redirect('dashboard:group_detail', group_id=group.id)

    form = MemberReplaceForm(request.POST)
    if not form.is_valid():
        messages.error(request, "Formulaire de remplacement invalide : numéro de téléphone requis.")
        return redirect('dashboard:group_detail', group_id=group.id)

    replacing_user = User.objects.filter(phone_number=form.cleaned_data['phone_number']).first()
    if not replacing_user:
        messages.error(request, "Aucun utilisateur avec ce numéro de téléphone.")
        return redirect('dashboard:group_detail', group_id=group.id)

    try:
        MembershipService.replace_member(
            group=group,
            replacing_user=replacing_user,
            position_to_take=form.cleaned_data.get('position')
        )
        messages.success(request, f"{replacing_user.full_name} ajouté au groupe.")
    except AppException as exc:
        messages.error(request, str(exc.detail))
    return redirect('dashboard:group_detail', group_id=group.id)


@require_POST
@login_required
def contribution_validate(request, group_id, contribution_id):
    group, _membership, is_admin = _get_membership_or_404(request, group_id)
    if not is_admin:
        messages.error(request, "Vous n'êtes pas administrateur de ce groupe.")
        return redirect('dashboard:group_detail', group_id=group.id)

    try:
        TransactionService.validate_contribution(contribution_id, request.user)
        messages.success(request, "Cotisation validée.")
    except AppException as exc:
        messages.error(request, str(exc.detail))
    return redirect('dashboard:group_detail', group_id=group.id)


@require_POST
@login_required
def join_request_accept(request, pk):
    join_request = get_object_or_404(JoinRequest, id=pk)
    group, _membership, is_admin = _get_membership_or_404(request, join_request.group_id)
    if not is_admin:
        messages.error(request, "Vous n'êtes pas administrateur de ce groupe.")
        return redirect('dashboard:group_detail', group_id=group.id)

    try:
        JoinRequestService.accept(join_request, processed_by=request.user)
        messages.success(request, f"{join_request.user.full_name} accepté dans le groupe.")
    except AppException as exc:
        messages.error(request, str(exc.detail))
    return redirect('dashboard:group_detail', group_id=group.id)


@require_POST
@login_required
def join_request_reject(request, pk):
    join_request = get_object_or_404(JoinRequest, id=pk)
    group, _membership, is_admin = _get_membership_or_404(request, join_request.group_id)
    if not is_admin:
        messages.error(request, "Vous n'êtes pas administrateur de ce groupe.")
        return redirect('dashboard:group_detail', group_id=group.id)

    try:
        JoinRequestService.reject(join_request, processed_by=request.user)
        messages.info(request, "Demande refusée.")
    except AppException as exc:
        messages.error(request, str(exc.detail))
    return redirect('dashboard:group_detail', group_id=group.id)

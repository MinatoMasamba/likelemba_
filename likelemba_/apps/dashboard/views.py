"""
Vues du tableau de bord HTML : authentification par session Django, distincte
du JWT utilisé par l'API REST (/api/v1/...). Ce tableau réutilise directement
les services métier existants — aucune règle n'est dupliquée depuis l'API.
"""
import csv
from datetime import timedelta
from decimal import Decimal
from pathlib import Path

from django.contrib import messages
from django.contrib.auth import login
from django.contrib.auth.decorators import login_required
from django.http import HttpResponse
from django.shortcuts import get_object_or_404, redirect, render
from django.templatetags.static import static
from django.urls import reverse
from django.utils import timezone
from django.views.decorators.http import require_POST

from apps.analytics.services import GroupHistoryService, ProjectionService, RiskService
from apps.tontines.models import Cycle, JoinRequest, LikelembaGroup, Membership, QueuePosition
from apps.tontines.services import JoinRequestService, LikelembaCalculator, MembershipService
from apps.transactions.models import Contribution, Payout, Refund
from apps.transactions.services import TransactionService
from apps.users.models import User, UserProfile
from core.exceptions import AppException

from .forms import (
    AdminMoveMemberForm,
    GroupCreateForm,
    JoinByCodeForm,
    MemberReplaceForm,
    ProfileEditForm,
    SignupForm,
)

_LANDING_PAGE_PATH = (
    Path(__file__).resolve().parent / 'static' / 'dashboard' / 'landing' / 'landing.html'
)


def _redirect_url_after_auth(user):
    """
    Détermine où envoyer un utilisateur après connexion/inscription :
    - admin avec un groupe déjà administré -> son tableau de bord admin
    - admin sans groupe -> création de sa première tontine
    - participant -> espace membre
    """
    if user.account_type == 'admin':
        if _admin_group_ids(user):
            return 'dashboard:admin_dashboard'
        return 'dashboard:admin_group_create'
    return 'dashboard:group_list'


def landing(request):
    """
    Page d'accueil publique (prototype de design importé tel quel : voir
    static/dashboard/landing/). Servie en HTML brut, sans passer par le
    moteur de templates Django, car le fichier utilise sa propre syntaxe
    `{{ }}` interprétée côté client par support.js — le moteur Django la
    détruirait en tentant de la résoudre comme des variables de contexte.
    """
    if request.user.is_authenticated:
        return redirect(_redirect_url_after_auth(request.user))

    html = _LANDING_PAGE_PATH.read_text(encoding='utf-8')
    html = html.replace('__SUPPORT_JS_URL__', static('dashboard/landing/support.js'))
    html = html.replace('__IMAGE_SLOT_JS_URL__', static('dashboard/landing/image-slot.js'))
    html = html.replace('__LOGIN_URL__', reverse('dashboard:login'))
    html = html.replace('__SIGNUP_ADMIN_URL__', reverse('dashboard:signup') + '?role=admin')
    return HttpResponse(html)


def manifest(request):
    """Manifest PWA : condition requise (avec le service worker) pour que le
    navigateur propose l'installation de l'application via beforeinstallprompt."""
    return render(request, 'dashboard/manifest.webmanifest', content_type='application/manifest+json')


def service_worker(request):
    """
    Servi sous /dashboard/ (et non /static/) pour que son scope par défaut
    couvre toutes les pages du tableau de bord, sans header
    Service-Worker-Allowed supplémentaire.
    """
    return render(request, 'dashboard/sw.js', content_type='application/javascript')


def signup(request):
    if request.user.is_authenticated:
        return redirect(_redirect_url_after_auth(request.user))

    if request.method == 'POST':
        form = SignupForm(request.POST)
        if form.is_valid():
            user = form.save()
            login(request, user, backend='apps.users.backends.EmailBackend')
            messages.success(request, "Compte créé avec succès. Bienvenue !")
            return redirect(_redirect_url_after_auth(user))
    else:
        initial_role = 'admin' if request.GET.get('role') == 'admin' else 'participant'
        form = SignupForm(initial={'account_type': initial_role})

    return render(request, 'dashboard/signup.html', {'form': form})


@login_required
def post_login_redirect(request):
    """
    Cible de LOGIN_REDIRECT_URL : redirige vers l'espace admin ou membre
    selon le statut de l'utilisateur, au lieu d'envoyer tout le monde vers
    l'espace membre par défaut.
    """
    return redirect(_redirect_url_after_auth(request.user))


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


def _admin_group_ids(user):
    """Groupes que l'utilisateur administre (adhésion active avec role='admin')."""
    return Membership.objects.filter(user=user, role='admin', is_active=True).values_list('group_id', flat=True)


def _is_payout_eligible(membership):
    """
    Un membre peut recevoir sa cagnotte si c'est son tour dans la file du
    cycle actif, qu'il n'a pas de dette, et que le cycle n'est pas terminé.
    En pratique, le versement est déclenché automatiquement par
    TransactionService dès que sa dernière cotisation est validée — cet
    indicateur est purement informatif pour l'affichage.
    """
    if membership is None or membership.debt_count != 0 or membership.has_received_payout:
        return False
    group = membership.group
    if group.elapsed_days >= group.cycle_duration_days:
        return False
    active_cycle = group.cycles.filter(is_active=True, is_completed=False).first()
    if not active_cycle:
        return False
    current = QueuePosition.objects.filter(cycle=active_cycle, is_current=True).first()
    return bool(current and current.membership_id == membership.id)


def _progress_percent(group):
    if not group.cycle_duration_days:
        return 0
    return max(0, min(100, round(group.elapsed_days / group.cycle_duration_days * 100)))


def _risk_tier(score):
    """Palier de risque affiché sur les cartes de prédiction (seuils et
    libellés du prototype : Likelemba Mobile.dc.html, predictionView)."""
    if score >= 75:
        return {
            'key': 'low', 'label': 'Risque faible', 'chip_class': 'chip-done',
            'action': "Continuer normalement",
        }
    if score >= 45:
        return {
            'key': 'medium', 'label': 'Risque modéré', 'chip_class': 'chip-current',
            'action': "Surveiller les prochains paiements",
        }
    return {
        'key': 'high', 'label': 'Risque élevé', 'chip_class': 'chip-critical',
        'action': "Suspendre les nouvelles demandes",
    }


def _build_prediction_chart(group, width=300, height=130, padding=10, horizon_days=14):
    """
    Graphique combinant l'évolution observée du fonds (trait plein) et sa
    projection EDO à venir (trait pointillé), entourée d'une marge
    d'incertitude qui s'élargit avec l'horizon — la projection EDO donne une
    seule trajectoire théorique, pas un intervalle, donc la marge affichée
    est une bande symétrique croissante autour de cette trajectoire plutôt
    qu'un intervalle de confiance statistique.
    """
    timeline = GroupHistoryService.reserve_timeline(group)
    historical = [float(point['amount']) for point in timeline[-9:]]
    current_reserve = float(group.reserve_amount)
    if len(historical) < 2:
        historical = [0.0, current_reserve]
    elif historical[-1] != current_reserve:
        historical.append(current_reserve)

    active_cycle = group.cycles.filter(is_active=True, is_completed=False).first()
    remaining_days = max(group.cycle_duration_days - group.elapsed_days, 0) if active_cycle else 0
    horizon = max(min(remaining_days, horizon_days), 3)

    projection = ProjectionService.solve_edo(
        n=group.number_of_members or 1,
        a=group.security_levy,
        alpha_0=group.penalty_rate_initial,
        T=horizon,
        initial_reserve=group.reserve_amount,
    )
    forecast = projection['F']

    upper = [v * (1 + min(0.03 * i, 0.22)) for i, v in enumerate(forecast)]
    lower = [max(v * (1 - min(0.03 * i, 0.22)), 0.0) for i, v in enumerate(forecast)]

    all_values = historical + upper + lower
    min_v, max_v = min(all_values), max(all_values)
    span = (max_v - min_v) or 1.0

    h_n = len(historical)
    f_n = len(forecast)
    total_steps = (h_n - 1) + (f_n - 1) or 1
    step = (width - 2 * padding) / total_steps

    def xy(index, value):
        x = padding + index * step
        y = height - padding - ((value - min_v) / span) * (height - 2 * padding)
        return f"{x:.1f}", f"{y:.1f}"

    historical_points = []
    for i, v in enumerate(historical):
        x, y = xy(i, v)
        historical_points.append(f"{x},{y}")

    forecast_points, upper_points, lower_points = [], [], []
    for i, v in enumerate(forecast):
        idx = (h_n - 1) + i
        x, y = xy(idx, v)
        forecast_points.append(f"{x},{y}")
        _, uy = xy(idx, upper[i])
        upper_points.append(f"{x},{uy}")
        _, ly = xy(idx, lower[i])
        lower_points.append(f"{x},{ly}")

    band_points = upper_points + list(reversed(lower_points))

    return {
        'width': width,
        'height': height,
        'historical_points': ' '.join(historical_points),
        'forecast_points': ' '.join(forecast_points),
        'band_points': ' '.join(band_points),
    }


PREDICTION_CHECKPOINTS = {
    'day1': {'label': 'Jour 1'},
    'mid': {'label': 'Jour du milieu'},
    'last': {'label': 'Dernier jour'},
}


def _checkpoint_day(checkpoint_key, group):
    """
    Jour du cycle (0..cycle_duration_days) visé par le point de contrôle —
    un Likelemba se pense en jours de cycle, pas en mois civils.
    """
    total = max(group.cycle_duration_days, 1)
    if checkpoint_key == 'day1':
        return 1
    if checkpoint_key == 'mid':
        return max(total // 2, 1)
    return total  # 'last'


def _build_prediction_detail(group, checkpoint_key, sim_pct, exit_people=None):
    """
    Détail de prédiction d'un groupe sur l'axe naturel du Likelemba, le jour
    du cycle : historique observé (GroupHistoryService) du jour 0 à
    aujourd'hui, puis projection EDO au-delà jusqu'au point de contrôle visé
    (jour 1 / jour du milieu / dernier jour du cycle) si celui-ci n'est pas
    déjà passé. Reprend la structure de `predictionDetail` du prototype
    (Likelemba Mobile.dc.html), avec des données réelles plutôt que la
    série aléatoire du mock, sur un axe jours plutôt que mois calendaires.
    """
    target_day = _checkpoint_day(checkpoint_key, group)
    elapsed = max(group.elapsed_days, 0)
    hist_end_day = min(elapsed, target_day)

    timeline = GroupHistoryService.reserve_timeline(group)
    started_at = group.started_at or timezone.now()

    # Échantillonnage de l'historique réel, capé pour rester lisible même
    # sur un cycle long (au plus ~30 points tracés dans le graphique).
    stride = max((hist_end_day + 1) // 30, 1)
    hist_days = list(range(0, hist_end_day + 1, stride))
    if hist_days[-1] != hist_end_day:
        hist_days.append(hist_end_day)

    actual_values = []
    idx, running, n_events = 0, Decimal('0'), len(timeline)
    for day in hist_days:
        end = started_at + timedelta(days=day + 1) - timedelta(seconds=1)
        while idx < n_events and timeline[idx]['date'] <= end:
            running = timeline[idx]['amount']
            idx += 1
        actual_values.append(float(running))
    if hist_days[-1] == elapsed:
        actual_values[-1] = float(group.reserve_amount)

    if len(actual_values) >= 2 and actual_values[-2]:
        trend_pct = round((actual_values[-1] - actual_values[-2]) / actual_values[-2] * 1000) / 10
    else:
        trend_pct = 0.0

    active_cycle = group.cycles.filter(is_active=True, is_completed=False).first()
    forecast_horizon = target_day - hist_end_day
    forecast_days, forecast_values = [], []
    if active_cycle and forecast_horizon > 0:
        projection = ProjectionService.solve_edo(
            n=group.number_of_members or 1,
            a=group.security_levy,
            alpha_0=group.penalty_rate_initial,
            T=forecast_horizon,
            initial_reserve=group.reserve_amount,
        )
        raw = projection['F']  # raw[0] = réserve actuelle, raw[forecast_horizon] = au jour visé
        n_fore = min(forecast_horizon, 6)
        stride_f = max(forecast_horizon // n_fore, 1)
        offsets = list(range(stride_f, forecast_horizon, stride_f))[:n_fore]
        if not offsets or offsets[-1] != forecast_horizon:
            offsets.append(forecast_horizon)
        for off in offsets:
            forecast_days.append(hist_end_day + off)
            forecast_values.append(raw[off])

    sim_factor = 1 + (sim_pct / 100)
    forecast_values = [v * sim_factor for v in forecast_values]
    upper_values = [v * (1 + 0.04 + i * 0.025) for i, v in enumerate(forecast_values)]
    lower_values = [max(v * (1 - (0.03 + i * 0.018)), 0.0) for i, v in enumerate(forecast_values)]

    # Simulation de départs anticipés (« et si N personnes quittaient
    # aujourd'hui ? ») : réutilise ProjectionService.simulate_exits, qui
    # applique l'impact du remboursement dégressif de chacune sur la
    # trajectoire du fonds à partir d'aujourd'hui, et signale si le fonds
    # resterait solvable jusqu'au point de contrôle visé.
    exit_days, exit_values = [], []
    exit_summary = None
    if exit_people and exit_people > 0 and active_cycle:
        exit_result = ProjectionService.simulate_exits(
            group,
            exit_scenarios=[[(hist_end_day, exit_people)]],
            days=target_day,
        )[0]
        exit_projection = exit_result['projection']
        exit_days = [hist_end_day] + forecast_days
        exit_values = [exit_projection[min(d, len(exit_projection) - 1)] for d in exit_days]
        exit_summary = {
            'people': exit_people,
            'is_solvent': exit_result['is_solvent'],
            'min_value': exit_result['min_value'],
            'final_value': exit_result['final_value'],
        }

    width, height, padding = 300, 130, 10
    all_values = actual_values + upper_values + lower_values + exit_values
    min_v, max_v = min(all_values), max(all_values)
    span = (max_v - min_v) or 1.0
    day_span = max(target_day, 1)

    def xy(day, value):
        x = padding + (day / day_span) * (width - 2 * padding)
        y = height - padding - ((value - min_v) / span) * (height - 2 * padding)
        return f"{x:.1f}", f"{y:.1f}"

    hist_points = [f"{xy(d, v)[0]},{xy(d, v)[1]}" for d, v in zip(hist_days, actual_values)]

    forecast_points = [hist_points[-1]] if hist_points else []
    upper_points = [hist_points[-1]] if hist_points else []
    lower_points = [hist_points[-1]] if hist_points else []
    for d, v, u, l in zip(forecast_days, forecast_values, upper_values, lower_values):
        x, y = xy(d, v)
        forecast_points.append(f"{x},{y}")
        _, uy = xy(d, u)
        upper_points.append(f"{x},{uy}")
        _, ly = xy(d, l)
        lower_points.append(f"{x},{ly}")
    band_points = upper_points + list(reversed(lower_points))

    exit_points = [f"{xy(d, v)[0]},{xy(d, v)[1]}" for d, v in zip(exit_days, exit_values)]

    actual_rows = [
        {'label': "Aujourd'hui" if day == elapsed else f"Jour {day}", 'amount': actual_values[i]}
        for i, day in reversed(list(enumerate(hist_days)))
    ][:10]

    return {
        'checkpoint_key': checkpoint_key,
        'checkpoints': PREDICTION_CHECKPOINTS,
        'current_value': actual_values[-1],
        'trend_pct': trend_pct,
        'trend_up': trend_pct >= 0,
        'chart': {
            'width': width, 'height': height,
            'historical_points': ' '.join(hist_points),
            'forecast_points': ' '.join(forecast_points),
            'band_points': ' '.join(band_points),
            'exit_points': ' '.join(exit_points),
        },
        'probable': forecast_values[-1] if forecast_values else actual_values[-1],
        'maximum': upper_values[-1] if upper_values else actual_values[-1],
        'minimum': lower_values[-1] if lower_values else actual_values[-1],
        'actual_rows': actual_rows,
        'sim_pct': sim_pct,
        'exit_people': exit_people or 0,
        'exit_prev': max((exit_people or 0) - 1, 0),
        'exit_next': min((exit_people or 0) + 1, group.number_of_members),
        'exit_summary': exit_summary,
        'has_debtors': group.members.filter(is_active=True, debt_count__gt=0).exists(),
    }


def _export_prediction_csv(group, detail):
    response = HttpResponse(content_type='text/csv')
    response['Content-Disposition'] = f'attachment; filename="{group.invite_code}-prediction.csv"'
    writer = csv.writer(response)
    writer.writerow(['Jour', 'Montant (FC)'])
    for row in detail['actual_rows']:
        writer.writerow([row['label'], round(row['amount'])])
    writer.writerow([])
    writer.writerow(['Probable (FC)', round(detail['probable'])])
    writer.writerow(['Maximum (FC)', round(detail['maximum'])])
    writer.writerow(['Minimum (FC)', round(detail['minimum'])])
    return response


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


# ---------------------------------------------------------------------------
# Espace membre
# ---------------------------------------------------------------------------

@login_required
def group_list(request):
    memberships = (
        Membership.objects.filter(user=request.user, is_active=True)
        .select_related('group')
        .order_by('-group__created_at')
    )
    total_received = sum((m.total_received for m in memberships), Decimal('0'))
    pending_payments_count = Contribution.objects.filter(
        membership__in=memberships,
        status='pending',
    ).count()

    groups_view = []
    for membership in memberships:
        group = membership.group
        timeline = GroupHistoryService.reserve_timeline(group)
        groups_view.append({
            'membership': membership,
            'group': group,
            'chart_points': _build_chart_points(timeline, group.reserve_amount, width=300, height=130, padding=8),
            'eligible': _is_payout_eligible(membership),
            'progress_percent': _progress_percent(group),
            'early_withdrawal_amount': (
                LikelembaCalculator.calculate_refund(
                    total_contributed=membership.total_contributed,
                    days_participated=max(group.elapsed_days, 1),
                    total_days=max(group.cycle_duration_days, 1),
                    alpha_0=group.penalty_rate_initial,
                ) if not membership.has_received_payout else Decimal('0')
            ),
        })

    return render(request, 'dashboard/home.html', {
        'groups_view': groups_view,
        'total_received': total_received,
        'pending_payments_count': pending_payments_count,
    })


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
    my_queue_position = None
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
    elif membership and active_cycle:
        queue = (
            QueuePosition.objects.filter(cycle=active_cycle)
            .select_related('membership__user')
            .order_by('position')
        )
        my_qp = next((q for q in queue if q.membership_id == membership.id), None)
        my_queue_position = my_qp.position if my_qp else None

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
        'my_queue_position': my_queue_position,
        'is_eligible': _is_payout_eligible(membership) if membership else False,
        'net_jackpot': group.calculate_net_jackpot(),
        'progress_percent': _progress_percent(group),
        'pending_contributions': pending_contributions,
        'pending_join_requests': pending_join_requests,
        'replace_form': MemberReplaceForm(),
    })


@login_required
def contribute(request, group_id):
    group, membership, is_admin = _get_membership_or_404(request, group_id)
    if not membership:
        messages.error(request, "Vous n'êtes pas membre de ce groupe.")
        return redirect('dashboard:group_list')

    if request.method == 'POST':
        try:
            TransactionService.submit_contribution(membership, amount=group.contribution_amount)
            messages.success(request, "Cotisation envoyée, en attente de validation par l'administrateur.")
            return redirect('dashboard:group_detail', group_id=group.id)
        except AppException as exc:
            messages.error(request, str(exc.detail))

    return render(request, 'dashboard/contribute.html', {'group': group, 'membership': membership})


@require_POST
@login_required
def request_payout(request, group_id):
    group, membership, is_admin = _get_membership_or_404(request, group_id)
    if not membership:
        messages.error(request, "Vous n'êtes pas membre de ce groupe.")
        return redirect('dashboard:group_list')

    if not _is_payout_eligible(membership):
        messages.error(request, "Vous n'êtes pas encore éligible à la cagnotte : ce n'est pas votre tour, ou vous avez une dette en cours.")
        return redirect('dashboard:group_detail', group_id=group.id)

    active_cycle = group.cycles.filter(is_active=True, is_completed=False).first()
    try:
        payout = TransactionService.process_payout(membership, active_cycle)
        messages.success(request, f"Cagnotte versée : {payout.amount} FC.")
    except AppException as exc:
        messages.error(request, str(exc.detail))
    return redirect('dashboard:group_detail', group_id=group.id)


@login_required
def join_group(request):
    form = JoinByCodeForm(request.POST or None)
    if request.method == 'POST' and form.is_valid():
        code = form.cleaned_data['invite_code'].strip().upper()
        group = LikelembaGroup.objects.filter(invite_code=code).first()
        if not group:
            form.add_error('invite_code', "Aucun groupe ne correspond à ce code.")
        elif Membership.objects.filter(user=request.user, group=group, is_active=True).exists():
            form.add_error('invite_code', "Vous êtes déjà membre de ce groupe.")
        else:
            existing = JoinRequest.objects.filter(user=request.user, group=group).first()
            if existing and existing.status == 'pending':
                messages.info(request, f"Votre demande pour « {group.name} » est déjà en attente.")
                return redirect('dashboard:group_list')
            if existing:
                existing.status = 'pending'
                existing.processed_by = None
                existing.processed_at = None
                existing.response_message = ''
                existing.save()
            else:
                JoinRequest.objects.create(user=request.user, group=group)
            messages.success(request, f"Demande envoyée à « {group.name} ». Un administrateur doit encore l'accepter.")
            return redirect('dashboard:group_list')

    return render(request, 'dashboard/join.html', {'form': form})


@login_required
def history(request):
    membership_ids = list(Membership.objects.filter(user=request.user).values_list('id', flat=True))

    rows = []
    for c in Contribution.objects.filter(membership_id__in=membership_ids).select_related('membership__group'):
        rows.append({'date': c.created_at, 'type_label': "Cotisation", 'group': c.membership.group, 'amount': c.amount, 'status': c.status})
    for r in Refund.objects.filter(membership_id__in=membership_ids).select_related('membership__group'):
        rows.append({'date': r.created_at, 'type_label': "Remboursement", 'group': r.membership.group, 'amount': r.amount, 'status': r.status})
    for p in Payout.objects.filter(membership_id__in=membership_ids).select_related('membership__group'):
        rows.append({'date': p.created_at, 'type_label': "Cagnotte", 'group': p.membership.group, 'amount': p.amount, 'status': p.status})
    rows.sort(key=lambda r: r['date'], reverse=True)

    return render(request, 'dashboard/history.html', {'rows': rows})


@login_required
def requests_tab(request):
    memberships = (
        Membership.objects.filter(user=request.user, is_active=True)
        .select_related('group')
        .order_by('-group__created_at')
    )
    return render(request, 'dashboard/requests.html', {'memberships': memberships})


@login_required
def request_detail(request, group_id):
    group, membership, is_admin = _get_membership_or_404(request, group_id)
    if not membership:
        messages.error(request, "Vous n'êtes pas membre de ce groupe.")
        return redirect('dashboard:requests_tab')

    active_cycle = group.cycles.filter(is_active=True, is_completed=False).first()
    before_you = []
    my_position = None
    if active_cycle:
        my_qp = QueuePosition.objects.filter(cycle=active_cycle, membership=membership).first()
        if my_qp:
            my_position = my_qp.position
            before_you = (
                QueuePosition.objects.filter(
                    cycle=active_cycle, position__lt=my_qp.position, received_at__isnull=True,
                )
                .select_related('membership__user')
                .order_by('position')
            )

    return render(request, 'dashboard/request_detail.html', {
        'group': group,
        'membership': membership,
        'my_position': my_position,
        'before_you': before_you,
        'is_eligible': _is_payout_eligible(membership),
    })


@login_required
def prediction_list(request):
    memberships = Membership.objects.filter(user=request.user, is_active=True).select_related('group')
    cards = []
    for m in memberships:
        score = RiskService.group_risk_score(m.group)
        cards.append({
            'group': m.group,
            'score': score,
            'tier': _risk_tier(score),
            'chart': _build_prediction_chart(m.group),
        })
    return render(request, 'dashboard/prediction_list.html', {'cards': cards})


@login_required
def prediction_detail(request, group_id):
    group, membership, is_admin = _get_membership_or_404(request, group_id)

    checkpoint_key = request.GET.get('point', 'mid')
    if checkpoint_key not in PREDICTION_CHECKPOINTS:
        checkpoint_key = 'mid'
    try:
        sim_pct = int(request.GET.get('sim', 0))
    except ValueError:
        sim_pct = 0
    sim_pct = max(-30, min(30, sim_pct - sim_pct % 5))
    try:
        exit_people = max(0, min(int(request.GET.get('exit', 0)), group.number_of_members))
    except ValueError:
        exit_people = 0

    detail = _build_prediction_detail(group, checkpoint_key, sim_pct, exit_people or None)

    if request.GET.get('export') == 'csv':
        return _export_prediction_csv(group, detail)

    score = RiskService.group_risk_score(group)
    return render(request, 'dashboard/prediction_detail.html', {
        'group': group,
        'score': score,
        'tier': _risk_tier(score),
        'detail': detail,
        'show_simulate': request.GET.get('simulate') == '1',
        'show_edit_note': request.GET.get('edit') == '1',
        'sim_presets': [-30, -15, 0, 15, 30],
    })


@login_required
def profile(request):
    profile_obj, _created = UserProfile.objects.get_or_create(user=request.user)
    admin_group_ids = list(_admin_group_ids(request.user))
    admin_stats = None
    if admin_group_ids:
        groups = LikelembaGroup.objects.filter(id__in=admin_group_ids)
        admin_stats = {
            'groups_count': groups.count(),
            'total_reserve': sum((g.reserve_amount for g in groups), Decimal('0')),
            'pending_count': (
                Contribution.objects.filter(membership__group_id__in=admin_group_ids, status='pending').count()
                + JoinRequest.objects.filter(group_id__in=admin_group_ids, status='pending').count()
            ),
        }

    active_memberships = (
        Membership.objects.filter(user=request.user, is_active=True)
        .select_related('group')
        .order_by('-group__created_at')
    )
    early_withdrawal_view = [
        {
            'group': m.group,
            'amount': LikelembaCalculator.calculate_refund(
                total_contributed=m.total_contributed,
                days_participated=max(m.group.elapsed_days, 1),
                total_days=max(m.group.cycle_duration_days, 1),
                alpha_0=m.group.penalty_rate_initial,
            ) if not m.has_received_payout else Decimal('0'),
        }
        for m in active_memberships
    ]
    user_code = request.user.member_code

    return render(request, 'dashboard/profile.html', {
        'profile': profile_obj,
        'admin_stats': admin_stats,
        'reliability': round(100 - profile_obj.risk_score),
        'early_withdrawal_view': early_withdrawal_view,
        'user_code': user_code,
    })


@require_POST
@login_required
def profile_set_language(request):
    profile_obj, _created = UserProfile.objects.get_or_create(user=request.user)
    language = request.POST.get('language')
    if language in ('fr', 'ln'):
        profile_obj.language = language
        profile_obj.save(update_fields=['language'])
    return redirect('dashboard:profile')


@require_POST
@login_required
def profile_toggle_notifications(request):
    profile_obj, _created = UserProfile.objects.get_or_create(user=request.user)
    profile_obj.notification_enabled = not profile_obj.notification_enabled
    profile_obj.save(update_fields=['notification_enabled'])
    return redirect('dashboard:profile')


@login_required
def profile_edit(request):
    profile_obj, _created = UserProfile.objects.get_or_create(user=request.user)
    if request.method == 'POST':
        form = ProfileEditForm(request.POST, request.FILES, instance=request.user, profile=profile_obj)
        if form.is_valid():
            form.save()
            messages.success(request, "Profil mis à jour.")
            return redirect('dashboard:profile')
    else:
        form = ProfileEditForm(instance=request.user, profile=profile_obj)
    return render(request, 'dashboard/profile_edit.html', {'form': form})


# ---------------------------------------------------------------------------
# Actions (POST uniquement, pas de gabarit propre)
# ---------------------------------------------------------------------------

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
        messages.error(request, "Formulaire invalide : code membre requis.")
        return redirect('dashboard:group_detail', group_id=group.id)

    replacing_user = User.from_member_code(form.cleaned_data['member_code'])
    if not replacing_user:
        messages.error(request, "Aucun utilisateur avec ce code membre.")
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
def member_move(request, group_id, membership_id):
    group, _membership, is_admin = _get_membership_or_404(request, group_id)
    if not is_admin:
        messages.error(request, "Vous n'êtes pas administrateur de ce groupe.")
        return redirect('dashboard:group_detail', group_id=group.id)

    target = get_object_or_404(Membership, id=membership_id, group=group)
    other_groups = LikelembaGroup.objects.filter(id__in=_admin_group_ids(request.user)).exclude(id=group.id)
    form = AdminMoveMemberForm(request.POST, other_groups=other_groups)
    if not form.is_valid():
        messages.error(request, "Choisissez un groupe cible valide.")
        return redirect('dashboard:admin_member_detail', group_id=group.id, membership_id=target.id)

    try:
        target_group = form.cleaned_data['target_group']
        MembershipService.move_member(target, target_group)
        messages.success(request, f"{target.user.full_name} déplacé vers « {target_group.name} ».")
        return redirect('dashboard:group_detail', group_id=target_group.id)
    except AppException as exc:
        messages.error(request, str(exc.detail))
        return redirect('dashboard:admin_member_detail', group_id=group.id, membership_id=target.id)


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


# ---------------------------------------------------------------------------
# Espace administrateur (agrégé sur tous les groupes que l'utilisateur gère)
# ---------------------------------------------------------------------------

def _require_group_admin(request):
    """Renvoie la liste des groupes administrés, ou liste vide + message si aucun."""
    group_ids = list(_admin_group_ids(request.user))
    if not group_ids:
        messages.info(request, "Vous n'administrez encore aucun groupe.")
    return group_ids


@login_required
def admin_dashboard(request):
    group_ids = _require_group_admin(request)
    if not group_ids:
        return redirect('dashboard:group_list')

    groups = LikelembaGroup.objects.filter(id__in=group_ids)
    groups_view = []
    for group in groups:
        timeline = GroupHistoryService.reserve_timeline(group)
        groups_view.append({
            'group': group,
            'chart_points': _build_chart_points(timeline, group.reserve_amount, width=300, height=130, padding=8),
        })

    pending_contributions = (
        Contribution.objects.filter(membership__group_id__in=group_ids, status='pending')
        .select_related('membership__user', 'membership__group')
        .order_by('created_at')
    )
    pending_join_requests = (
        JoinRequest.objects.filter(group_id__in=group_ids, status='pending')
        .select_related('user', 'group')
        .order_by('-created_at')
    )

    return render(request, 'dashboard/admin_dashboard.html', {
        'groups_view': groups_view,
        'pending_contributions': pending_contributions,
        'pending_join_requests': pending_join_requests,
        'pending_count': pending_contributions.count() + pending_join_requests.count(),
    })


@login_required
def admin_groups(request):
    group_ids = _require_group_admin(request)
    if not group_ids:
        return redirect('dashboard:group_list')

    groups = LikelembaGroup.objects.filter(id__in=group_ids)
    late_members = (
        Membership.objects.filter(group_id__in=group_ids, is_active=True, debt_count__gt=0)
        .select_related('user', 'group')
    )
    return render(request, 'dashboard/admin_groups.html', {'groups': groups, 'late_members': late_members})


@login_required
def admin_group_create(request):
    form = GroupCreateForm(request.POST or None)
    if request.method == 'POST' and form.is_valid():
        group = form.save(commit=False)
        group.created_by = request.user
        group.started_at = timezone.now()
        # Prélèvement de sécurité fixé automatiquement à 10 % de la cotisation.
        group.security_levy = (group.contribution_amount * Decimal('0.10')).quantize(Decimal('0.01'))
        # Un seul membre (l'admin) à cet instant ; recalculé après sa création ci-dessous.
        group.cycle_duration_days = group.distribution_interval_days
        group.save()
        Membership.objects.create(user=request.user, group=group, role='admin')
        group.recompute_cycle_duration()
        Cycle.objects.create(group=group, sequence_number=1, start_date=timezone.now())
        messages.success(request, f"Groupe « {group.name} » créé. Code d'invitation : {group.invite_code}.")
        return redirect('dashboard:group_detail', group_id=group.id)

    return render(request, 'dashboard/admin_group_create.html', {'form': form})


@login_required
def admin_member_detail(request, group_id, membership_id):
    group, _membership, is_admin = _get_membership_or_404(request, group_id)
    if not is_admin:
        messages.error(request, "Vous n'êtes pas administrateur de ce groupe.")
        return redirect('dashboard:group_detail', group_id=group.id)

    target = get_object_or_404(Membership, id=membership_id, group=group)
    other_groups = LikelembaGroup.objects.filter(id__in=_admin_group_ids(request.user)).exclude(id=group.id)

    return render(request, 'dashboard/admin_member_detail.html', {
        'group': group,
        'target': target,
        'risk_score': RiskService.member_risk_score(target),
        'replace_form': MemberReplaceForm(),
        'move_form': AdminMoveMemberForm(other_groups=other_groups),
        'other_groups': other_groups,
    })


@login_required
def notifications(request):
    group_ids = _require_group_admin(request)
    if not group_ids:
        return redirect('dashboard:group_list')

    tab = request.GET.get('tab', 'paiements')

    pending_contributions = (
        Contribution.objects.filter(membership__group_id__in=group_ids, status='pending')
        .select_related('membership__user', 'membership__group')
        .order_by('created_at')
    )
    pending_join_requests = (
        JoinRequest.objects.filter(group_id__in=group_ids, status='pending')
        .select_related('user', 'group')
        .order_by('-created_at')
    )
    late_members = (
        Membership.objects.filter(group_id__in=group_ids, is_active=True, debt_count__gt=0)
        .select_related('user', 'group')
    )
    groups = LikelembaGroup.objects.filter(id__in=group_ids)
    risk_alerts = [
        {'group': g, 'score': RiskService.group_risk_score(g)}
        for g in groups
    ]
    risk_alerts = [alert for alert in risk_alerts if alert['score'] < 45]
    history_rows = (
        Contribution.objects.filter(membership__group_id__in=group_ids)
        .exclude(status='pending')
        .select_related('membership__user', 'membership__group')
        .order_by('-created_at')[:30]
    )

    return render(request, 'dashboard/notifications.html', {
        'tab': tab,
        'pending_contributions': pending_contributions,
        'pending_join_requests': pending_join_requests,
        'late_members': late_members,
        'risk_alerts': risk_alerts,
        'history_rows': history_rows,
        'pending_count': pending_contributions.count() + pending_join_requests.count(),
    })

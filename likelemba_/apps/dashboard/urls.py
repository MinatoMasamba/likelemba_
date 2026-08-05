from django.contrib.auth import views as auth_views
from django.urls import path, reverse_lazy

from . import views
from .forms import EmailAuthenticationForm

app_name = 'dashboard'

urlpatterns = [
    path(
        'login/',
        auth_views.LoginView.as_view(
            template_name='dashboard/login.html',
            authentication_form=EmailAuthenticationForm,
        ),
        name='login',
    ),
    path('signup/', views.signup, name='signup'),
    path('logout/', auth_views.LogoutView.as_view(), name='logout'),
    path('post-connexion/', views.post_login_redirect, name='post_login_redirect'),

    path(
        'mot-de-passe-oublie/',
        auth_views.PasswordResetView.as_view(
            template_name='dashboard/password_reset.html',
            email_template_name='dashboard/emails/password_reset_email.txt',
            html_email_template_name='dashboard/emails/password_reset_email.html',
            subject_template_name='dashboard/emails/password_reset_subject.txt',
            success_url=reverse_lazy('dashboard:password_reset_done'),
        ),
        name='password_reset',
    ),
    path(
        'mot-de-passe-oublie/envoye/',
        auth_views.PasswordResetDoneView.as_view(template_name='dashboard/password_reset_done.html'),
        name='password_reset_done',
    ),
    path(
        'reinitialiser/<uidb64>/<token>/',
        auth_views.PasswordResetConfirmView.as_view(
            template_name='dashboard/password_reset_confirm.html',
            success_url=reverse_lazy('dashboard:password_reset_complete'),
        ),
        name='password_reset_confirm',
    ),
    path(
        'reinitialiser/termine/',
        auth_views.PasswordResetCompleteView.as_view(template_name='dashboard/password_reset_complete.html'),
        name='password_reset_complete',
    ),
    path(
        'profil/mot-de-passe/',
        auth_views.PasswordChangeView.as_view(
            template_name='dashboard/password_change.html',
            success_url=reverse_lazy('dashboard:profile'),
        ),
        name='password_change',
    ),

    # --- Espace membre -----------------------------------------------------
    path('', views.group_list, name='group_list'),
    path('groups/<uuid:group_id>/', views.group_detail, name='group_detail'),
    path('groups/<uuid:group_id>/cotiser/', views.contribute, name='contribute'),
    path('groups/<uuid:group_id>/demander/', views.request_payout, name='request_payout'),
    path('groups/<uuid:group_id>/replace/', views.member_replace, name='member_replace'),
    path(
        'groups/<uuid:group_id>/members/<uuid:membership_id>/exit/',
        views.member_exit,
        name='member_exit',
    ),
    path(
        'groups/<uuid:group_id>/members/<uuid:membership_id>/deplacer/',
        views.member_move,
        name='member_move',
    ),
    path(
        'groups/<uuid:group_id>/contributions/<uuid:contribution_id>/validate/',
        views.contribution_validate,
        name='contribution_validate',
    ),
    path('join-requests/<uuid:pk>/accept/', views.join_request_accept, name='join_request_accept'),
    path('join-requests/<uuid:pk>/reject/', views.join_request_reject, name='join_request_reject'),

    path('rejoindre/', views.join_group, name='join_group'),
    path('historique/', views.history, name='history'),
    path('demandes/', views.requests_tab, name='requests_tab'),
    path('demandes/<uuid:group_id>/', views.request_detail, name='request_detail'),
    path('prediction/', views.prediction_list, name='prediction_list'),
    path('prediction/<uuid:group_id>/', views.prediction_detail, name='prediction_detail'),
    path('profil/', views.profile, name='profile'),
    path('profil/modifier/', views.profile_edit, name='profile_edit'),
    path('profil/langue/', views.profile_set_language, name='profile_set_language'),
    path('profil/notifications/', views.profile_toggle_notifications, name='profile_toggle_notifications'),

    # --- Espace administrateur ----------------------------------------------
    path('admin-tontines/', views.admin_dashboard, name='admin_dashboard'),
    path('admin-tontines/groupes/', views.admin_groups, name='admin_groups'),
    path('admin-tontines/groupes/nouveau/', views.admin_group_create, name='admin_group_create'),
    path(
        'admin-tontines/groupes/<uuid:group_id>/membres/<uuid:membership_id>/',
        views.admin_member_detail,
        name='admin_member_detail',
    ),
    path('admin-tontines/notifications/', views.notifications, name='notifications'),
]

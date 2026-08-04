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

    path('', views.group_list, name='group_list'),
    path('groups/<uuid:group_id>/', views.group_detail, name='group_detail'),
    path('groups/<uuid:group_id>/replace/', views.member_replace, name='member_replace'),
    path(
        'groups/<uuid:group_id>/members/<uuid:membership_id>/exit/',
        views.member_exit,
        name='member_exit',
    ),
    path(
        'groups/<uuid:group_id>/contributions/<uuid:contribution_id>/validate/',
        views.contribution_validate,
        name='contribution_validate',
    ),
    path('join-requests/<uuid:pk>/accept/', views.join_request_accept, name='join_request_accept'),
    path('join-requests/<uuid:pk>/reject/', views.join_request_reject, name='join_request_reject'),
]

from django.contrib.auth import views as auth_views
from django.urls import path

from . import views
from .forms import PhoneAuthenticationForm

app_name = 'dashboard'

urlpatterns = [
    path(
        'login/',
        auth_views.LoginView.as_view(
            template_name='dashboard/login.html',
            authentication_form=PhoneAuthenticationForm,
        ),
        name='login',
    ),
    path('logout/', auth_views.LogoutView.as_view(), name='logout'),

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

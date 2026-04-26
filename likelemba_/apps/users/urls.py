"""
Configuration des URLs pour l'application users.
"""
from django.urls import path
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    RegisterView,
    CustomTokenObtainPairView,
    ProfileView,
    ChangePasswordView,
    LogoutView,
    DeviceRegistrationView,
    PhoneVerificationRequestView,
    PhoneVerificationConfirmView,
    BiometricSetupView,
    BiometricDisableView
)

app_name = 'users'

urlpatterns = [
    # Authentification
    path('auth/register/', RegisterView.as_view(), name='register'),
    path('auth/token/', CustomTokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('auth/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),
    path('auth/logout/', LogoutView.as_view(), name='logout'),
    path('auth/change-password/', ChangePasswordView.as_view(), name='change_password'),

    # Profil
    path('profile/', ProfileView.as_view(), name='profile'),

    # Vérification téléphone
    path('verify/phone/request/', PhoneVerificationRequestView.as_view(), name='phone_verify_request'),
    path('verify/phone/confirm/', PhoneVerificationConfirmView.as_view(), name='phone_verify_confirm'),

    # Biométrie
    path('biometric/setup/', BiometricSetupView.as_view(), name='biometric_setup'),
    path('biometric/disable/', BiometricDisableView.as_view(), name='biometric_disable'),

    # Appareils (notifications push)
    path('devices/', DeviceRegistrationView.as_view(), name='device_register'),
]
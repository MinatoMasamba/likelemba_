"""
Vues pour l'authentification et la gestion des utilisateurs.
"""
import logging
import secrets

from rest_framework import generics, status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import get_user_model
from django.core.cache import cache
from django.utils.translation import gettext_lazy as _
from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi

from .models import UserProfile, UserDevice
from .serializers import (
    CustomTokenObtainPairSerializer,
    UserRegistrationSerializer,
    UserProfileSerializer,
    ChangePasswordSerializer,
    UserDeviceSerializer,
    PhoneVerificationSerializer,
    BiometricSetupSerializer
)
from core.permissions import IsOwnerOrAdmin

User = get_user_model()
logger = logging.getLogger(__name__)

PHONE_VERIFICATION_CACHE_KEY = 'phone_verify:{user_id}'
PHONE_VERIFICATION_TTL_SECONDS = 300  # 5 minutes


class RegisterView(generics.CreateAPIView):
    """
    Inscription d'un nouvel utilisateur.
    """
    queryset = User.objects.all()
    serializer_class = UserRegistrationSerializer
    permission_classes = [permissions.AllowAny]

    @swagger_auto_schema(
        operation_description="Inscription d'un nouvel utilisateur avec numéro de téléphone",
        responses={201: UserProfileSerializer, 400: "Données invalides"}
    )
    def post(self, request, *args, **kwargs):
        return super().post(request, *args, **kwargs)




class CustomTokenObtainPairView(TokenObtainPairView):
    """
    Connexion personnalisée qui retourne les tokens + les infos utilisateur.
    """
    serializer_class = CustomTokenObtainPairSerializer

    @swagger_auto_schema(
        operation_description="Obtenir un token JWT avec numéro de téléphone et mot de passe",
        responses={200: "Tokens JWT + user info", 401: "Identifiants invalides"}
    )
    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)
        if response.status_code == 200:
            phone_number = request.data.get('phone_number')
            try:
                user = User.objects.get(phone_number=phone_number)
                user.last_login_ip = request.META.get('REMOTE_ADDR')
                user.save(update_fields=['last_login_ip'])
            except User.DoesNotExist:
                pass
        return response


class ProfileView(generics.RetrieveUpdateAPIView):
    """
    Récupérer et mettre à jour le profil de l'utilisateur connecté.
    """
    serializer_class = UserProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user.profile

    @swagger_auto_schema(
        operation_description="Obtenir le profil de l'utilisateur connecté"
    )
    def get(self, request, *args, **kwargs):
        return super().get(request, *args, **kwargs)

    @swagger_auto_schema(
        operation_description="Mettre à jour le profil de l'utilisateur connecté"
    )
    def put(self, request, *args, **kwargs):
        return super().put(request, *args, **kwargs)

    @swagger_auto_schema(
        operation_description="Mise à jour partielle du profil"
    )
    def patch(self, request, *args, **kwargs):
        return super().patch(request, *args, **kwargs)


class ChangePasswordView(APIView):
    """
    Changer le mot de passe de l'utilisateur connecté.
    """
    permission_classes = [permissions.IsAuthenticated]

    @swagger_auto_schema(
        request_body=ChangePasswordSerializer,
        responses={200: "Mot de passe changé avec succès", 400: "Erreur de validation"}
    )
    def post(self, request):
        serializer = ChangePasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = request.user
        if not user.check_password(serializer.validated_data['old_password']):
            return Response(
                {"old_password": "Mot de passe actuel incorrect."},
                status=status.HTTP_400_BAD_REQUEST
            )

        user.set_password(serializer.validated_data['new_password'])
        user.save()
        return Response(
            {"detail": "Mot de passe changé avec succès."},
            status=status.HTTP_200_OK
        )


class LogoutView(APIView):
    """
    Déconnexion (blacklist du refresh token).
    """
    permission_classes = [permissions.AllowAny]

    @swagger_auto_schema(
        request_body=openapi.Schema(
            type=openapi.TYPE_OBJECT,
            properties={'refresh': openapi.Schema(type=openapi.TYPE_STRING)}
        ),
        responses={205: "Déconnexion réussie", 400: "Token invalide"}
    )
    def post(self, request):
        refresh_token = request.data.get('refresh')
        if not refresh_token:
            return Response(status=status.HTTP_205_RESET_CONTENT)
        try:
            token = RefreshToken(refresh_token)
            token.blacklist()
            return Response(status=status.HTTP_205_RESET_CONTENT)
        except Exception:
            return Response(status=status.HTTP_205_RESET_CONTENT)


class DeviceRegistrationView(generics.CreateAPIView):
    """
    Enregistrer un appareil pour les notifications push.
    """
    serializer_class = UserDeviceSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        # Mettre à jour ou créer
        device_id = serializer.validated_data.get('device_id')
        device, created = UserDevice.objects.update_or_create(
            user=self.request.user,
            device_id=device_id,
            defaults=serializer.validated_data
        )
        return device


class PhoneVerificationRequestView(APIView):
    """
    Demander un code de vérification par SMS.
    """
    permission_classes = [permissions.IsAuthenticated]

    @swagger_auto_schema(
        responses={202: "Code envoyé"}
    )
    def post(self, request):
        user = request.user
        code = f"{secrets.randbelow(1_000_000):06d}"
        cache.set(
            PHONE_VERIFICATION_CACHE_KEY.format(user_id=user.id),
            code,
            timeout=PHONE_VERIFICATION_TTL_SECONDS
        )
        self._send_sms(user.phone_number, code)
        return Response(
            {"detail": "Code de vérification envoyé."},
            status=status.HTTP_202_ACCEPTED
        )

    @staticmethod
    def _send_sms(phone_number, code):
        """
        Envoi du SMS de vérification.
        Aucun fournisseur SMS (Twilio ou autre) n'est câblé pour l'instant :
        le code est journalisé pour permettre le développement et les tests
        de bout en bout sans dépendance externe. À remplacer par un vrai
        envoi avant mise en production.
        """
        logger.info("Code de vérification pour %s : %s", phone_number, code)


class PhoneVerificationConfirmView(APIView):
    """
    Confirmer le code de vérification du téléphone.
    """
    permission_classes = [permissions.IsAuthenticated]

    @swagger_auto_schema(
        request_body=PhoneVerificationSerializer,
        responses={200: "Numéro vérifié", 400: "Code invalide"}
    )
    def post(self, request):
        serializer = PhoneVerificationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        code = serializer.validated_data['code']

        user = request.user
        cache_key = PHONE_VERIFICATION_CACHE_KEY.format(user_id=user.id)
        expected_code = cache.get(cache_key)

        if expected_code is not None and secrets.compare_digest(code, expected_code):
            cache.delete(cache_key)
            user.phone_verified = True
            user.save(update_fields=['phone_verified'])
            return Response({"detail": "Numéro vérifié avec succès."})
        return Response(
            {"code": "Code invalide ou expiré."},
            status=status.HTTP_400_BAD_REQUEST
        )


class BiometricSetupView(APIView):
    """
    Activer l'authentification biométrique.
    """
    permission_classes = [permissions.IsAuthenticated]

    @swagger_auto_schema(
        request_body=BiometricSetupSerializer,
        responses={200: "Biométrie activée"}
    )
    def post(self, request):
        serializer = BiometricSetupSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = request.user
        user.biometric_public_key = serializer.validated_data['public_key']
        user.biometric_enabled = True
        user.save(update_fields=['biometric_public_key', 'biometric_enabled'])

        return Response({"detail": "Authentification biométrique activée."})


class BiometricDisableView(APIView):
    """
    Désactiver l'authentification biométrique.
    """
    permission_classes = [permissions.IsAuthenticated]

    @swagger_auto_schema(
        responses={200: "Biométrie désactivée"}
    )
    def post(self, request):
        user = request.user
        user.biometric_public_key = ''
        user.biometric_enabled = False
        user.save(update_fields=['biometric_public_key', 'biometric_enabled'])
        return Response({"detail": "Authentification biométrique désactivée."})
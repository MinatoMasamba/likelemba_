"""
Vues pour l'authentification et la gestion des utilisateurs.
"""
from rest_framework import generics, status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import get_user_model
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
        # Implémentation réelle : envoi SMS via Twilio ou autre
        # Pour l'exemple, on simule
        user = request.user
        # Générer et stocker un code (dans le cache Redis)
        # send_sms(user.phone_number, code)
        return Response(
            {"detail": "Code de vérification envoyé."},
            status=status.HTTP_202_ACCEPTED
        )


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

        # Vérifier le code stocké dans le cache
        # Pour l'exemple, on accepte "123456"
        if code == "123456":
            user = request.user
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
"""
Sérialiseurs pour l'application users.
"""
from rest_framework import serializers
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError
from django.utils.translation import gettext_lazy as _
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from rest_framework_simplejwt.views import TokenObtainPairView
from .models import User, UserProfile, UserDevice


class UserRegistrationSerializer(serializers.ModelSerializer):
    """Sérialiseur pour l'inscription d'un nouvel utilisateur."""
    password = serializers.CharField(
        write_only=True,
        required=True,
        validators=[validate_password],
        style={'input_type': 'password'}
    )
    password2 = serializers.CharField(
        write_only=True,
        required=True,
        style={'input_type': 'password'}
    )
    full_name = serializers.CharField(required=True)

    account_type = serializers.ChoiceField(choices=User.ACCOUNT_TYPE_CHOICES, required=False)



    class Meta:
        model = User
        fields = [
            'phone_number',
            'full_name',
            'email',
            'password',
            'password2',
            'account_type',

        ]

    def validate(self, attrs):
        if attrs['password'] != attrs['password2']:
            raise serializers.ValidationError(
                {"password": "Les mots de passe ne correspondent pas."}
            )
        return attrs

    def create(self, validated_data):
        validated_data.pop('password2')
        validated_data['phone_number'] = normalize_phone(validated_data['phone_number'])
        user = User.objects.create_user(
            phone_number=validated_data['phone_number'],
            password=validated_data['password'],
            full_name=validated_data['full_name'],
            email=validated_data.get('email', ''),
            account_type=validated_data.get('account_type', 'participant'),

        )
        # Créer automatiquement le profil
        UserProfile.objects.create(user=user)
        return user


class UserProfileSerializer(serializers.ModelSerializer):
    """Sérialiseur pour le profil utilisateur."""
    phone_number = serializers.CharField(source='user.phone_number', read_only=True)
    full_name = serializers.CharField(source='user.full_name', read_only=True)
    email = serializers.EmailField(source='user.email', required=False)
    phone_verified = serializers.BooleanField(source='user.phone_verified', read_only=True)

    class Meta:
        model = UserProfile
        fields = [
            'id',
            'phone_number',
            'full_name',
            'email',
            'phone_verified',
            'risk_score',
            'language',
            'notification_enabled',
            'total_contributions',
            'total_received',
            'successful_cycles',
            'default_count',
            'created_at',
            'updated_at'
        ]
        read_only_fields = [
            'risk_score',
            'total_contributions',
            'total_received',
            'successful_cycles',
            'default_count',
            'created_at',
            'updated_at'
        ]

    def update(self, instance, validated_data):
        user_data = validated_data.pop('user', {})
        user = instance.user

        if 'email' in user_data:
            user.email = user_data['email']
            user.save(update_fields=['email'])

        return super().update(instance, validated_data)


class ChangePasswordSerializer(serializers.Serializer):
    """Sérialiseur pour le changement de mot de passe."""
    old_password = serializers.CharField(required=True, write_only=True)
    new_password = serializers.CharField(required=True, write_only=True, validators=[validate_password])
    new_password2 = serializers.CharField(required=True, write_only=True)

    def validate(self, attrs):
        if attrs['new_password'] != attrs['new_password2']:
            raise serializers.ValidationError(
                {"new_password": "Les nouveaux mots de passe ne correspondent pas."}
            )
        return attrs


class UserDeviceSerializer(serializers.ModelSerializer):
    """Sérialiseur pour l'enregistrement des appareils."""
    class Meta:
        model = UserDevice
        fields = ['id', 'device_id', 'device_type', 'push_token', 'app_version', 'last_active']
        read_only_fields = ['last_active']


class PhoneVerificationSerializer(serializers.Serializer):
    """Sérialiseur pour la vérification du numéro de téléphone."""
    code = serializers.CharField(required=True, max_length=6)



def normalize_phone(phone: str) -> str:
    """Convertit 0XXXXXXXXX → +243XXXXXXXXX. Laisse +... inchangé."""
    phone = phone.strip()
    if phone.startswith('+'):
        return phone
    if phone.startswith('0') and len(phone) == 10:
        return f'+243{phone[1:]}'
    if not phone.startswith('0') and len(phone) == 9:
        return f'+243{phone}'
    return phone


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    """
    Sérialiseur JWT personnalisé qui ajoute les informations utilisateur dans la réponse.
    """
    def validate(self, attrs):
        # Normalise le numéro avant l'authentification
        if 'phone_number' in attrs:
            attrs['phone_number'] = normalize_phone(attrs['phone_number'])
        data = super().validate(attrs)
        user = self.user
        # Ajouter les champs supplémentaires
                # Ajouter les champs supplémentaires
        data.update({
            'user_id': str(user.id),
            'phone_number': user.phone_number,
            'full_name': user.full_name,
            'account_type': user.account_type,
            'is_admin': user.account_type == 'admin',
            'phone_verified': user.phone_verified,
            'email_verified': user.email_verified,
            'biometric_enabled': user.biometric_enabled,
        })
        return data


class BiometricSetupSerializer(serializers.Serializer):
    """Sérialiseur pour la configuration de l'authentification biométrique."""
    public_key = serializers.CharField(required=True)
    device_id = serializers.CharField(required=True)
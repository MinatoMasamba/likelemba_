"""
Modèles pour la gestion des utilisateurs, profils et authentification.
"""
from django.contrib.auth.models import AbstractUser, BaseUserManager
from django.db import models
from django.core.validators import RegexValidator
from core.models import BaseModel


class UserManager(BaseUserManager):
    """Manager personnalisé pour le modèle User."""

    def create_user(self, phone_number, password=None, **extra_fields):
        if not phone_number:
            raise ValueError("Le numéro de téléphone est obligatoire")
        user = self.model(phone_number=phone_number, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, phone_number, password=None, **extra_fields):
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        extra_fields.setdefault('is_active', True)
        extra_fields.setdefault('email_verified', True)
        extra_fields.setdefault('phone_verified', True)

        if extra_fields.get('is_staff') is not True:
            raise ValueError("Superuser must have is_staff=True.")
        if extra_fields.get('is_superuser') is not True:
            raise ValueError("Superuser must have is_superuser=True.")

        return self.create_user(phone_number, password, **extra_fields)


class User(AbstractUser):
    """
    Modèle utilisateur personnalisé.
    Le champ d'identification principal est le numéro de téléphone.
    """
    username = None  # Désactive le champ username par défaut
    phone_regex = RegexValidator(
        regex=r'^\+?1?\d{9,15}$',
        message="Le numéro de téléphone doit être au format: '+243999999999'. Jusqu'à 15 chiffres autorisés."
    )

    phone_number = models.CharField(
        max_length=17,
        unique=True,
        validators=[phone_regex],
        help_text="Numéro de téléphone international (ex: +243xxxxxxxxx)"
    )
    email = models.EmailField(
        blank=True,
        null=True,
        unique=True,
        help_text="Adresse email (utilisée pour la connexion au tableau de bord)"
    )
    full_name = models.CharField(
        max_length=255,
        blank=True,
        help_text="Nom complet de l'utilisateur"
    )

    # Vérifications
    phone_verified = models.BooleanField(default=False)
    email_verified = models.BooleanField(default=False)

    # Champs biométriques (optionnels)
    biometric_public_key = models.TextField(
        blank=True,
        help_text="Clé publique pour l'authentification biométrique"
    )
    biometric_enabled = models.BooleanField(default=False)
    
    ACCOUNT_TYPE_CHOICES = [
        ('participant', 'Participant'),
        ('admin', 'Administrateur'),
    ]
    
    account_type = models.CharField(
        max_length=20,
        choices=ACCOUNT_TYPE_CHOICES,
        default='participant',
        help_text="Type de compte utilisateur"
    )


    # Métadonnées
    last_login_ip = models.GenericIPAddressField(null=True, blank=True)
    last_login_device = models.CharField(max_length=255, blank=True)

    USERNAME_FIELD = 'phone_number'
    REQUIRED_FIELDS = ['full_name']

    objects = UserManager()

    class Meta:
        db_table = 'users'
        verbose_name = "Utilisateur"
        verbose_name_plural = "Utilisateurs"
        ordering = ['-date_joined']

    def __str__(self):
        return f"{self.full_name} ({self.phone_number})"

    def get_short_name(self):
        return self.full_name.split()[0] if self.full_name else self.phone_number


class UserProfile(BaseModel):
    """
    Profil étendu de l'utilisateur avec des informations spécifiques à l'application.
    """
    user = models.OneToOneField(
        User,
        on_delete=models.CASCADE,
        related_name='profile'
    )

    # Score de risque calculé par l'IA (0-100)
    risk_score = models.FloatField(
        default=50.0,
        help_text="Score de risque de défaillance (0 = fiable, 100 = très risqué)"
    )

    # Préférences
    language = models.CharField(
        max_length=10,
        choices=[
            ('fr', 'Français'),
            ('ln', 'Lingala'),
            ('sw', 'Swahili'),
            ('en', 'English'),
        ],
        default='fr'
    )
    notification_enabled = models.BooleanField(default=True)
    push_token = models.CharField(max_length=255, blank=True)

    # Statistiques
    total_contributions = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=0
    )
    total_received = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=0
    )

    photo_user = models.ImageField(
        upload_to='profile_photos/%Y/%m/',
        blank=True,
        null=True
    )
    successful_cycles = models.IntegerField(default=0)
    default_count = models.IntegerField(default=0)

    class Meta:
        db_table = 'user_profiles'
        verbose_name = "Profil utilisateur"
        verbose_name_plural = "Profils utilisateurs"

    def __str__(self):
        return f"Profil de {self.user.full_name}"


class UserDevice(BaseModel):
    """
    Appareils enregistrés pour les notifications push et la synchronisation.
    """
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='devices'
    )
    device_id = models.CharField(max_length=255, unique=True)
    device_type = models.CharField(
        max_length=20,
        choices=[
            ('android', 'Android'),
            ('ios', 'iOS'),
        ]
    )
    push_token = models.CharField(max_length=255)
    last_active = models.DateTimeField(auto_now=True)
    app_version = models.CharField(max_length=20, blank=True)

    class Meta:
        db_table = 'user_devices'
        verbose_name = "Appareil utilisateur"
        verbose_name_plural = "Appareils utilisateurs"
        unique_together = ['user', 'device_id']

    def __str__(self):
        return f"{self.user.phone_number} - {self.device_type}"
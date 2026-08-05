from django import forms
from django.contrib.auth import get_user_model
from django.contrib.auth.forms import AuthenticationForm
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError

from apps.tontines.models import LikelembaGroup

User = get_user_model()


class EmailAuthenticationForm(AuthenticationForm):
    """Formulaire de connexion : le tableau de bord s'identifie par email + mot de passe."""
    username = forms.EmailField(
        label="Adresse email",
        widget=forms.EmailInput(attrs={'autofocus': True, 'placeholder': 'vous@exemple.com'}),
    )
    password = forms.CharField(
        label="Mot de passe",
        strip=False,
        widget=forms.PasswordInput(attrs={'placeholder': '••••••••'}),
    )

    error_messages = {
        'invalid_login': "Adresse email ou mot de passe incorrect.",
        'inactive': "Ce compte a été désactivé.",
    }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # AuthenticationForm.__init__ recopie le max_length du champ
        # USERNAME_FIELD du modèle (phone_number, 17 caractères) sur le champ
        # "username", quel que soit son type — ici un EmailField, où 17
        # caractères tronquerait la quasi-totalité des adresses email réelles.
        self.fields['username'].max_length = 254
        self.fields['username'].widget.attrs['maxlength'] = 254


class SignupForm(forms.Form):
    """Création de compte depuis le tableau de bord (email + mot de passe)."""
    ROLE_CHOICES = User.ACCOUNT_TYPE_CHOICES

    full_name = forms.CharField(
        label="Nom complet",
        max_length=255,
        widget=forms.TextInput(attrs={'autofocus': True, 'placeholder': 'Votre nom complet'}),
    )
    email = forms.EmailField(
        label="Adresse email",
        widget=forms.EmailInput(attrs={'placeholder': 'vous@exemple.com'}),
    )
    phone_number = forms.CharField(
        label="Numéro de téléphone",
        max_length=17,
        widget=forms.TextInput(attrs={'placeholder': '+243900000000'}),
    )
    account_type = forms.ChoiceField(
        choices=ROLE_CHOICES,
        widget=forms.HiddenInput,
        initial='participant',
    )
    password1 = forms.CharField(
        label="Mot de passe",
        strip=False,
        widget=forms.PasswordInput(attrs={'placeholder': '••••••••'}),
    )
    password2 = forms.CharField(
        label="Confirmer le mot de passe",
        strip=False,
        widget=forms.PasswordInput(attrs={'placeholder': '••••••••'}),
    )

    def clean_email(self):
        email = self.cleaned_data['email']
        if User.objects.filter(email__iexact=email).exists():
            raise ValidationError("Un compte existe déjà avec cette adresse email.")
        return email

    def clean_phone_number(self):
        phone_number = self.cleaned_data['phone_number'].strip()
        if User.objects.filter(phone_number=phone_number).exists():
            raise ValidationError("Un compte existe déjà avec ce numéro de téléphone.")
        return phone_number

    def clean(self):
        cleaned_data = super().clean()
        password1 = cleaned_data.get('password1')
        password2 = cleaned_data.get('password2')
        if password1 and password2 and password1 != password2:
            self.add_error('password2', "Les deux mots de passe ne correspondent pas.")
        elif password1:
            try:
                validate_password(password1)
            except ValidationError as exc:
                self.add_error('password1', exc)
        return cleaned_data

    def save(self):
        return User.objects.create_user(
            phone_number=self.cleaned_data['phone_number'],
            password=self.cleaned_data['password1'],
            email=self.cleaned_data['email'],
            full_name=self.cleaned_data['full_name'],
            account_type=self.cleaned_data['account_type'],
        )


class MemberReplaceForm(forms.Form):
    member_code = forms.CharField(
        label="Code membre",
        widget=forms.TextInput(attrs={'placeholder': 'LK-42', 'autocapitalize': 'characters'}),
    )
    position = forms.IntegerField(label="Position dans la file (optionnel)", required=False, min_value=1)


class JoinByCodeForm(forms.Form):
    invite_code = forms.CharField(
        label="Code d'invitation",
        max_length=12,
        widget=forms.TextInput(attrs={'placeholder': 'BKM4X9Q2', 'autofocus': True, 'autocapitalize': 'characters'}),
    )


class GroupCreateForm(forms.ModelForm):
    class Meta:
        model = LikelembaGroup
        fields = [
            'name', 'description', 'contribution_amount', 'distribution_interval_days',
        ]
        labels = {
            'name': "Nom de la tontine",
            'description': "Message de bienvenue (optionnel)",
            'contribution_amount': "Cotisation journalière (FC)",
            'distribution_interval_days': "Intervalle entre deux cagnottes (jours)",
        }
        help_texts = {
            'distribution_interval_days': (
                "La durée totale du cycle et le prélèvement de sécurité sont "
                "calculés automatiquement à partir de cet intervalle et de la "
                "cotisation."
            ),
        }
        widgets = {
            'name': forms.TextInput(attrs={'autofocus': True, 'placeholder': 'Ex. : Tontine des voisins'}),
            'description': forms.Textarea(attrs={'rows': 3, 'placeholder': 'Un mot pour les futurs membres…'}),
            'contribution_amount': forms.NumberInput(attrs={'placeholder': '5000'}),
            'distribution_interval_days': forms.NumberInput(attrs={'placeholder': '3'}),
        }


class AdminMoveMemberForm(forms.Form):
    target_group = forms.ModelChoiceField(
        queryset=LikelembaGroup.objects.none(),
        label="Groupe cible",
        empty_label="Choisir un groupe…",
    )

    def __init__(self, *args, other_groups=None, **kwargs):
        super().__init__(*args, **kwargs)
        if other_groups is not None:
            self.fields['target_group'].queryset = other_groups


class ProfileEditForm(forms.Form):
    full_name = forms.CharField(label="Nom complet", max_length=255)
    phone_number = forms.CharField(label="Téléphone", max_length=17)
    photo_user = forms.ImageField(label="Photo de profil", required=False)
    notification_enabled = forms.BooleanField(label="Notifications activées", required=False)

    def __init__(self, *args, instance=None, profile=None, **kwargs):
        self.user_instance = instance
        self.profile_instance = profile
        initial = kwargs.pop('initial', None) or {}
        if instance is not None:
            initial.setdefault('full_name', instance.full_name)
            initial.setdefault('phone_number', instance.phone_number)
        if profile is not None:
            initial.setdefault('notification_enabled', profile.notification_enabled)
        kwargs['initial'] = initial
        super().__init__(*args, **kwargs)

    def clean_phone_number(self):
        phone_number = self.cleaned_data['phone_number'].strip()
        qs = User.objects.filter(phone_number=phone_number)
        if self.user_instance is not None:
            qs = qs.exclude(pk=self.user_instance.pk)
        if qs.exists():
            raise ValidationError("Un autre compte utilise déjà ce numéro de téléphone.")
        return phone_number

    def save(self):
        self.user_instance.full_name = self.cleaned_data['full_name']
        self.user_instance.phone_number = self.cleaned_data['phone_number']
        self.user_instance.save(update_fields=['full_name', 'phone_number'])

        self.profile_instance.notification_enabled = self.cleaned_data['notification_enabled']
        if self.cleaned_data.get('photo_user'):
            self.profile_instance.photo_user = self.cleaned_data['photo_user']
        self.profile_instance.save()
        return self.user_instance

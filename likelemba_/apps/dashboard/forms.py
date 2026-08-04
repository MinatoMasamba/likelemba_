from django import forms
from django.contrib.auth import get_user_model
from django.contrib.auth.forms import AuthenticationForm
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError

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
    phone_number = forms.CharField(label="Téléphone du remplaçant")
    position = forms.IntegerField(label="Position dans la file (optionnel)", required=False, min_value=1)

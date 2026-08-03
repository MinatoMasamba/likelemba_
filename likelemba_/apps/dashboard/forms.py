from django import forms
from django.contrib.auth.forms import AuthenticationForm


class PhoneAuthenticationForm(AuthenticationForm):
    """Formulaire de connexion : le User du projet s'identifie par téléphone, pas par username."""
    username = forms.CharField(
        label="Numéro de téléphone",
        widget=forms.TextInput(attrs={'autofocus': True, 'placeholder': '+243900000000'})
    )


class MemberReplaceForm(forms.Form):
    phone_number = forms.CharField(label="Téléphone du remplaçant")
    position = forms.IntegerField(label="Position dans la file (optionnel)", required=False, min_value=1)

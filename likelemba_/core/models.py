"""
Modèles abstraits partagés par toutes les applications du projet.
"""
import uuid
from django.db import models


class BaseModel(models.Model):
    """
    Classe de base pour tous les modèles du projet.
    Fournit un UUID comme clé primaire et des timestamps automatiques.
    """
    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
        help_text="Identifiant unique universel"
    )
    created_at = models.DateTimeField(
        auto_now_add=True,
        help_text="Date de création de l'enregistrement"
    )
    updated_at = models.DateTimeField(
        auto_now=True,
        help_text="Date de dernière modification"
    )

    class Meta:
        abstract = True
        ordering = ['-created_at']

    def __str__(self):
        return f"{self.__class__.__name__} {self.id}"
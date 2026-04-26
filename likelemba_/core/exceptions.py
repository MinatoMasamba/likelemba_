"""
Gestion centralisée des exceptions pour l'API REST.
"""
import logging
from rest_framework.views import exception_handler
from rest_framework.response import Response
from rest_framework import status
from django.core.exceptions import ValidationError as DjangoValidationError
from django.http import Http404

logger = logging.getLogger(__name__)


class AppException(Exception):
    """Exception de base pour l'application."""
    status_code = status.HTTP_500_INTERNAL_SERVER_ERROR
    default_detail = "Une erreur interne est survenue."
    default_code = "error"

    def __init__(self, detail=None, code=None):
        self.detail = detail or self.default_detail
        self.code = code or self.default_code
        super().__init__(self.detail)


class ValidationError(AppException):
    """Exception de validation métier."""
    status_code = status.HTTP_400_BAD_REQUEST
    default_detail = "Données invalides."
    default_code = "validation_error"


class BusinessLogicError(AppException):
    """Exception pour les violations de règles métier."""
    status_code = status.HTTP_422_UNPROCESSABLE_ENTITY
    default_detail = "Opération non autorisée par les règles métier."
    default_code = "business_logic_error"


class InsufficientFundsError(BusinessLogicError):
    """Fonds insuffisants pour une opération."""
    default_detail = "Fonds insuffisants dans la réserve pour effectuer cette opération."
    default_code = "insufficient_funds"


class GroupNotActiveError(BusinessLogicError):
    """Le groupe n'est pas actif."""
    default_detail = "Ce groupe de tontine n'est plus actif."
    default_code = "group_not_active"


class NotYourTurnError(BusinessLogicError):
    """Ce n'est pas le tour du membre de recevoir la cagnotte."""
    default_detail = "Ce n'est pas encore votre tour de recevoir la cagnotte."
    default_code = "not_your_turn"


class MemberHasDebtError(BusinessLogicError):
    """Le membre a des dettes impayées."""
    default_detail = "Vous avez des cotisations impayées. Veuillez régulariser votre situation."
    default_code = "member_has_debt"


def custom_exception_handler(exc, context):
    """
    Gestionnaire d'exceptions personnalisé pour DRF.
    Capture nos exceptions métier et les formate correctement.
    """
    # D'abord, laisser DRF gérer ses propres exceptions
    response = exception_handler(exc, context)

    if response is not None:
        # Ajouter le code d'erreur si disponible
        if hasattr(exc, 'detail') and hasattr(exc, 'status_code'):
            response.data = {
                'code': getattr(exc, 'default_code', 'error'),
                'detail': exc.detail,
                'status_code': exc.status_code
            }
        return response

    # Gérer nos exceptions personnalisées
    if isinstance(exc, AppException):
        logger.error(f"AppException: {exc.detail}", exc_info=True)
        return Response(
            {
                'code': exc.code,
                'detail': exc.detail,
                'status_code': exc.status_code
            },
            status=exc.status_code
        )

    # Gérer les erreurs de validation Django
    if isinstance(exc, DjangoValidationError):
        return Response(
            {
                'code': 'validation_error',
                'detail': exc.messages,
                'status_code': status.HTTP_400_BAD_REQUEST
            },
            status=status.HTTP_400_BAD_REQUEST
        )

    # Gérer 404
    if isinstance(exc, Http404):
        return Response(
            {
                'code': 'not_found',
                'detail': "Ressource non trouvée.",
                'status_code': status.HTTP_404_NOT_FOUND
            },
            status=status.HTTP_404_NOT_FOUND
        )

    # Erreur non gérée
    logger.critical(f"Unhandled exception: {exc}", exc_info=True)
    return Response(
        {
            'code': 'internal_error',
            'detail': "Une erreur inattendue est survenue.",
            'status_code': status.HTTP_500_INTERNAL_SERVER_ERROR
        },
        status=status.HTTP_500_INTERNAL_SERVER_ERROR
    )
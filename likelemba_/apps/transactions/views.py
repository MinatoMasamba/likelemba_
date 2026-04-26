from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from drf_yasg.utils import swagger_auto_schema
from django.shortcuts import get_object_or_404

from .models import Contribution, Refund, Payout
from .serializers import (
    ContributionSerializer, ContributionValidationSerializer,
    RefundSerializer, PayoutSerializer
)
from .services import TransactionService
from core.permissions import IsGroupMember, IsGroupAdmin


class ContributionViewSet(viewsets.ModelViewSet):
    serializer_class = ContributionSerializer
    permission_classes = [permissions.IsAuthenticated, IsGroupMember]

    def get_queryset(self):
        user = self.request.user
        return Contribution.objects.filter(membership__user=user)

    def perform_create(self, serializer):
        membership = serializer.validated_data['membership']
        # Vérifier que l'utilisateur est bien le membre
        if membership.user != self.request.user and not self.request.user.is_superuser:
            raise permissions.PermissionDenied("Vous ne pouvez créer une cotisation que pour vous-même.")
        TransactionService.submit_contribution(
            membership=membership,
            amount=serializer.validated_data['amount'],
            due_date=serializer.validated_data.get('due_date'),
            proof=serializer.validated_data.get('proof_image')
        )

    @swagger_auto_schema(
        method='post',
        request_body=ContributionValidationSerializer,
        responses={200: ContributionSerializer}
    )
    @action(detail=False, methods=['post'], permission_classes=[IsGroupAdmin])
    def validate_contribution(self, request):
        """Admin : valider une cotisation."""
        serializer = ContributionValidationSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        contribution = TransactionService.validate_contribution(
            contribution_id=serializer.validated_data['contribution_id'],
            validator_user=request.user
        )

        return Response(ContributionSerializer(contribution).data)


class RefundViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = RefundSerializer
    permission_classes = [permissions.IsAuthenticated, IsGroupMember]

    def get_queryset(self):
        user = self.request.user
        if user.is_superuser:
            return Refund.objects.all()
        return Refund.objects.filter(membership__user=user)


class PayoutViewSet(viewsets.ReadOnlyModelViewSet):
    serializer_class = PayoutSerializer
    permission_classes = [permissions.IsAuthenticated, IsGroupMember]

    def get_queryset(self):
        user = self.request.user
        if user.is_superuser:
            return Payout.objects.all()
        return Payout.objects.filter(membership__user=user)
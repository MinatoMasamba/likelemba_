"""
Vues pour la gestion des groupes Likelemba.
"""
from datetime import timezone

from rest_framework import viewsets, status, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from apps.users import models
from drf_yasg.utils import swagger_auto_schema

from .models import LikelembaGroup, Cycle, Membership, QueuePosition
from .serializers import (
    LikelembaGroupSerializer, CycleSerializer, MembershipSerializer,
    QueuePositionSerializer, MemberExitSerializer, MemberReplacementSerializer,
    ReserveProjectionSerializer
)
from .services import MembershipService, LikelembaCalculator
from core.permissions import IsGroupMember, IsGroupAdmin

from apps.tontines import serializers


class LikelembaGroupViewSet(viewsets.ModelViewSet):
    """
    CRUD pour les groupes Likelemba.
    """
    queryset = LikelembaGroup.objects.all()
    serializer_class = LikelembaGroupSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.is_superuser:
            return self.queryset
        return self.queryset.filter(members__user=user, members__is_active=True)

    def perform_create(self, serializer):
        group = serializer.save(created_by=self.request.user)
        # Ajouter automatiquement le créateur comme membre avec son rôle préféré
        role = self.request.user.account_type if self.request.user.account_type in ['admin', 'participant'] else 'participant'
        Membership.objects.create(
            user=self.request.user,
            group=group,
            role=role,
            joined_at=timezone.now()
        )

    @swagger_auto_schema(
        method='post',
        request_body=MemberExitSerializer,
        responses={200: "Départ traité", 400: "Erreur"}
    )
    @action(detail=True, methods=['post'], permission_classes=[IsGroupAdmin])
    def exit_member(self, request, pk=None):
        """Traiter le départ d'un membre."""
        group = self.get_object()
        serializer = MemberExitSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        membership = get_object_or_404(
            Membership,
            id=serializer.validated_data['membership_id'],
            group=group
        )

        refund = MembershipService.process_member_exit(
            membership,
            exit_date=serializer.validated_data.get('exit_date')
        )

        return Response({
            'detail': 'Membre retiré avec succès.',
            'refund_amount': refund
        })

    @swagger_auto_schema(
        method='post',
        request_body=MemberReplacementSerializer,
        responses={201: MembershipSerializer}
    )
    @action(detail=True, methods=['post'], permission_classes=[IsGroupAdmin])
    def replace_member(self, request, pk=None):
        """Remplacer un membre parti."""
        group = self.get_object()
        serializer = MemberReplacementSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        from apps.users.models import User
        user = get_object_or_404(User, id=serializer.validated_data['user_id'])

        membership = MembershipService.replace_member(
            group=group,
            replacing_user=user,
            position_to_take=serializer.validated_data.get('position')
        )

        return Response(
            MembershipSerializer(membership).data,
            status=status.HTTP_201_CREATED
        )

    @swagger_auto_schema(
        method='post',
        request_body=ReserveProjectionSerializer,
        responses={200: "Projection calculée"}
    )
    @action(detail=True, methods=['post'])
    def project_reserve(self, request, pk=None):
        """Projeter l'évolution du fonds de réserve."""
        group = self.get_object()
        serializer = ReserveProjectionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        days = serializer.validated_data['days']
        outflows = []
        if serializer.validated_data.get('include_scheduled_exits'):
            # Récupérer les départs prévus (exemple simplifié)
            pass

        projection = LikelembaCalculator.calculate_reserve_fund_projection(
            initial_reserve=group.reserve_amount,
            daily_inflow_per_member=group.security_levy,
            number_of_members=group.number_of_members,
            days=days,
            outflows=outflows
        )

        return Response({
            'days': list(range(days + 1)),
            'projection': projection
        })
    
    @action(detail=False, methods=['post'], url_path='join-by-code')
    def join_by_code(self, request):
        """Rejoindre un groupe en fournissant le code d'invitation."""
        invite_code = request.data.get('invite_code')
        if not invite_code:
            return Response(
                {"error": "Le code d'invitation est requis."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        group = get_object_or_404(LikelembaGroup, invite_code__iexact=invite_code, is_active=True)
        user = request.user
        
        # Vérifier si déjà membre
        if group.members.filter(user=user, is_active=True).exists():
            return Response(
                {"error": "Vous êtes déjà membre de ce groupe."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Vérifier si demande en attente
        if JoinRequest.objects.filter(user=user, group=group, status='pending').exists():
            return Response(
                {"error": "Vous avez déjà une demande en attente pour ce groupe."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Créer la demande d'adhésion
        join_request = JoinRequest.objects.create(
            user=user,
            group=group,
            message=request.data.get('message', '')
        )
        
        serializer = JoinRequestSerializer(join_request, context={'request': request})
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    

    @action(detail=False, methods=['get', 'post'], url_path='join-by-code')
    def join_by_code(self, request):
        """Rejoindre un groupe en fournissant le code d'invitation (GET ou POST)."""
        # Récupérer le code soit depuis les query params (GET) soit depuis le body (POST)
        invite_code = request.query_params.get('code') or request.data.get('invite_code')
        
        if not invite_code:
            return Response(
                {"error": "Le code d'invitation est requis."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        group = get_object_or_404(LikelembaGroup, invite_code__iexact=invite_code, is_active=True)
        user = request.user
        
        # Si méthode GET, on affiche juste les infos du groupe (prévisualisation)
        if request.method == 'GET':
            serializer = self.get_serializer(group)
            return Response(serializer.data)
        
        # POST : Création de la demande d'adhésion
        if group.members.filter(user=user, is_active=True).exists():
            return Response(
                {"error": "Vous êtes déjà membre de ce groupe."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        if JoinRequest.objects.filter(user=user, group=group, status='pending').exists():
            return Response(
                {"error": "Vous avez déjà une demande en attente pour ce groupe."},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        join_request = JoinRequest.objects.create(
            user=user,
            group=group,
            message=request.data.get('message', '')
        )
        
        serializer = JoinRequestSerializer(join_request, context={'request': request})
        return Response(serializer.data, status=status.HTTP_201_CREATED)


class CycleViewSet(viewsets.ReadOnlyModelViewSet):
    """Consultation des cycles."""
    serializer_class = CycleSerializer
    permission_classes = [permissions.IsAuthenticated, IsGroupMember]

    def get_queryset(self):
        user = self.request.user
        return Cycle.objects.filter(group__members__user=user, group__members__is_active=True)


class MembershipViewSet(viewsets.ModelViewSet):
    """Gestion des adhésions."""
    serializer_class = MembershipSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.is_superuser:
            return Membership.objects.all()
        return Membership.objects.filter(user=user)

    def perform_create(self, serializer):
        # Seul un admin de groupe peut ajouter des membres
        group = serializer.validated_data.get('group')
        if not group.members.filter(user=self.request.user, role='admin', is_active=True).exists():
            raise permissions.PermissionDenied("Vous n'êtes pas administrateur de ce groupe.")
        serializer.save()


class QueuePositionViewSet(viewsets.ReadOnlyModelViewSet):
    """Consultation de la file d'attente."""
    serializer_class = QueuePositionSerializer
    permission_classes = [permissions.IsAuthenticated, IsGroupMember]

    def get_queryset(self):
        user = self.request.user
        cycle_id = self.request.query_params.get('cycle')
        queryset = QueuePosition.objects.filter(cycle__group__members__user=user)
        if cycle_id:
            queryset = queryset.filter(cycle_id=cycle_id)
        return queryset.order_by('position')
    

from .models import JoinRequest
from .serializers import JoinRequestSerializer, JoinRequestUpdateSerializer
from rest_framework import viewsets, mixins
from django.utils import timezone

class JoinRequestViewSet(mixins.CreateModelMixin,
                         mixins.ListModelMixin,
                         mixins.RetrieveModelMixin,
                         viewsets.GenericViewSet):
    """
    Gestion des demandes d'adhésion.
    - POST /join-requests/ : Créer une demande (utilisateur authentifié)
    - GET /join-requests/ : Lister ses propres demandes ou toutes si admin de groupe
    - PATCH /join-requests/{id}/ : Accepter/refuser (admin du groupe seulement)
    """
    queryset = JoinRequest.objects.all()
    serializer_class = JoinRequestSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        user = self.request.user
        if user.is_superuser:
            return self.queryset
        # Lister les demandes où l'utilisateur est demandeur OU admin du groupe concerné
        groups_admin = user.memberships.filter(role='admin', is_active=True).values_list('group_id', flat=True)
        return self.queryset.filter(
            models.Q(user=user) | models.Q(group_id__in=groups_admin)
        ).distinct()

    def get_serializer_class(self):
        if self.action in ['partial_update', 'update']:
            return JoinRequestUpdateSerializer
        return JoinRequestSerializer

    def perform_create(self, serializer):
        # Vérifier que l'utilisateur n'est pas déjà membre actif
        group = serializer.validated_data['group']
        if group.members.filter(user=self.request.user, is_active=True).exists():
            raise serializers.ValidationError("Vous êtes déjà membre de ce groupe.")
        # Vérifier qu'il n'y a pas déjà une demande en attente
        if JoinRequest.objects.filter(user=self.request.user, group=group, status='pending').exists():
            raise serializers.ValidationError("Vous avez déjà une demande en attente pour ce groupe.")
        serializer.save(user=self.request.user)

    @action(detail=True, methods=['patch'], permission_classes=[IsGroupAdmin])
    def accept(self, request, pk=None):
        """Accepter une demande et créer le membership."""
        join_request = self.get_object()
        if join_request.status != 'pending':
            return Response(
                {"detail": f"Cette demande a déjà été traitée (statut: {join_request.status})."},
                status=status.HTTP_400_BAD_REQUEST
            )

        serializer = JoinRequestUpdateSerializer(join_request, data={'status': 'accepted'}, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save(processed_by=request.user, processed_at=timezone.now())

        # Créer le membership avec le rôle préféré du demandeur
        membership = Membership.objects.create(
            user=join_request.user,
            group=join_request.group,
            role=join_request.user.profile.preferred_role,
            joined_at=timezone.now()
        )
        # Assigner une position dans la file d'attente (fin de file)
        active_cycle = join_request.group.cycles.filter(is_active=True, is_completed=False).first()
        if active_cycle:
            last_pos = QueuePosition.objects.filter(cycle=active_cycle).count()
            QueuePosition.objects.create(cycle=active_cycle, membership=membership, position=last_pos + 1)

        return Response({
            "detail": "Demande acceptée. L'utilisateur est maintenant membre du groupe.",
            "membership_id": str(membership.id)
        })

    @action(detail=True, methods=['patch'], permission_classes=[IsGroupAdmin])
    def reject(self, request, pk=None):
        """Refuser une demande."""
        join_request = self.get_object()
        if join_request.status != 'pending':
            return Response(
                {"detail": f"Cette demande a déjà été traitée (statut: {join_request.status})."},
                status=status.HTTP_400_BAD_REQUEST
            )

        serializer = JoinRequestUpdateSerializer(join_request, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save(processed_by=request.user, processed_at=timezone.now(), status='rejected')
        return Response({"detail": "Demande refusée."})

    @action(detail=True, methods=['patch'], permission_classes=[permissions.IsAuthenticated])
    def cancel(self, request, pk=None):
        """Annuler sa propre demande."""
        join_request = self.get_object()
        if join_request.user != request.user:
            raise permissions.PermissionDenied("Vous ne pouvez annuler que vos propres demandes.")
        if join_request.status != 'pending':
            return Response(
                {"detail": "Seules les demandes en attente peuvent être annulées."},
                status=status.HTTP_400_BAD_REQUEST
            )
        join_request.status = 'cancelled'
        join_request.save(update_fields=['status'])
        return Response({"detail": "Demande annulée."})


from rest_framework import generics, permissions, status
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from .models import LikelembaGroup, Membership, JoinRequest
from apps.users.models import User

class MembershipValidationView(generics.GenericAPIView):
    """
    Vérifie le statut d'un utilisateur par rapport à un groupe.
    GET /api/v1/tontines/groups/{group_id}/members/{user_id}/validation/
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, group_id, user_id):
        group = get_object_or_404(LikelembaGroup, id=group_id, is_active=True)
        user = get_object_or_404(User, id=user_id)

        # Vérifier si l'utilisateur est déjà membre actif
        membership = Membership.objects.filter(
            group=group,
            user=user,
            is_active=True
        ).first()

        if membership:
            return Response({
                'status': 'member',
                'message': 'L\'utilisateur est déjà membre actif.',
                'membership_id': str(membership.id),
                'role': membership.role,
                'joined_at': membership.joined_at,
            })

        # Vérifier s'il y a une demande en attente
        pending_request = JoinRequest.objects.filter(
            group=group,
            user=user,
            status='pending'
        ).first()

        if pending_request:
            return Response({
                'status': 'pending',
                'message': 'Une demande d\'adhésion est en attente de validation.',
                'join_request_id': str(pending_request.id),
                'created_at': pending_request.created_at,
            })

        # Ni membre ni demande en attente
        return Response({
            'status': 'none',
            'message': 'L\'utilisateur n\'a pas de demande d\'adhésion pour ce groupe.',
        })
    
@action(detail=False, methods=['get'], url_path='pending-for-group')
def pending_for_group(self, request):
    """Récupère toutes les demandes en attente pour un groupe donné."""
    group_id = request.query_params.get('group_id')
    if not group_id:
        return Response(
            {"error": "Le paramètre 'group_id' est requis."},
            status=status.HTTP_400_BAD_REQUEST
        )
    
    group = get_object_or_404(LikelembaGroup, id=group_id)
    
    # Vérifier que l'utilisateur est admin de ce groupe
    if not group.members.filter(user=request.user, role='admin', is_active=True).exists():
        raise permissions.PermissionDenied("Vous n'êtes pas administrateur de ce groupe.")
    
    pending_requests = JoinRequest.objects.filter(
        group=group,
        status='pending'
    ).select_related('user', 'user__profile').order_by('-created_at')
    
    serializer = self.get_serializer(pending_requests, many=True)
    return Response(serializer.data)
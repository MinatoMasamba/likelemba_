"""
Sérialiseurs pour l'application tontines.
"""
from rest_framework import serializers
from .models import JoinRequest, LikelembaGroup, Cycle, Membership, QueuePosition
from apps.users.serializers import UserProfileSerializer


class LikelembaGroupSerializer(serializers.ModelSerializer):
    # Champs calculés (propriétés du modèle)
    number_of_members = serializers.IntegerField(read_only=True)
    contribution_net = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)
    security_fee_rate = serializers.FloatField(read_only=True)
    elapsed_days = serializers.IntegerField(read_only=True)
    is_cycle_completed = serializers.BooleanField(read_only=True)
    gross_jackpot = serializers.DecimalField(max_digits=14, decimal_places=2, read_only=True)
    net_jackpot = serializers.DecimalField(max_digits=14, decimal_places=2, read_only=True)
    
    # Relations
    admin_link = serializers.UUIDField(source='created_by.id', read_only=True)
    created_by_name = serializers.CharField(source='created_by.full_name', read_only=True)
    invite_link = serializers.SerializerMethodField()

    class Meta:
        model = LikelembaGroup
        fields = [
            # Identité
            'id', 'name', 'description',
            'created_at', 'updated_at',
            # Paramètres financiers
            'contribution_amount', 'security_levy', 'security_fee_rate',
            'penalty_rate_initial', 'cycle_duration_days',
            'distribution_interval_days', 'regeneration_target_days',
            # Fonds et état du cycle
            'reserve_amount', 'current_beneficiary_index',
            'started_at', 'ended_at', 'is_active',
            'elapsed_days', 'is_cycle_completed',
            'gross_jackpot', 'net_jackpot',
            # Verrouillage
            'is_locked', 'locked_at',
            # Invitation
            'invite_code', 'invite_link',
            # Admin & membres
            'admin_link', 'created_by_name', 'number_of_members',
            # Contribution nette (déjà sous #Paramètres? On la garde)
            'contribution_net',
        ]
        read_only_fields = [
            'id', 'created_at', 'updated_at',
            'number_of_members', 'contribution_net', 'security_fee_rate',
            'elapsed_days', 'is_cycle_completed', 'gross_jackpot', 'net_jackpot',
            'invite_code', 'invite_link', 'admin_link', 'created_by_name',
            'reserve_amount', 'current_beneficiary_index',
        ]

    def get_invite_link(self, obj):
        """
        Génère l'URL absolue de l'endpoint API pour rejoindre le groupe
        en utilisant le code d'invitation.
        """
        request = self.context.get('request')
        if request:
            # Construire l'URL à partir de la requête actuelle (http://domaine:port)
            base_url = request.build_absolute_uri('/')[:-1]  # Enlève le slash final
            return f"{base_url}/api/v1/tontines/groups/join-by-code/?code={obj.invite_code}"
        else:
            # Fallback si aucun request dans le contexte (ex: génération hors vue)
            # Utiliser une variable de configuration ou settings.BASE_URL
            from django.conf import settings
            base_url = getattr(settings, 'BASE_URL', 'http://localhost:8000')
            return f"{base_url}/api/v1/tontines/groups/join-by-code/?code={obj.invite_code}"
     

class CycleSerializer(serializers.ModelSerializer):
    group_name = serializers.CharField(source='group.name', read_only=True)

    class Meta:
        model = Cycle
        fields = [
            'id', 'group', 'group_name', 'sequence_number', 'start_date', 'end_date',
            'is_completed', 'is_active', 'total_contributions_collected',
            'total_refunds_paid', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'sequence_number', 'start_date', 'total_contributions_collected', 'total_refunds_paid']


class MembershipSerializer(serializers.ModelSerializer):
    user_details = UserProfileSerializer(source='user.profile', read_only=True)
    group_name = serializers.CharField(source='group.name', read_only=True)

    class Meta:
        model = Membership
        fields = [
            'id', 'user', 'user_details', 'group', 'group_name', 'role',
            'joined_at', 'left_at', 'is_active', 'queue_position',
            'total_contributed', 'total_received', 'debt_count',
            'has_received_payout', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'joined_at', 'left_at', 'total_contributed', 'total_received', 'debt_count', 'has_received_payout']


class QueuePositionSerializer(serializers.ModelSerializer):
    member_name = serializers.CharField(source='membership.user.full_name', read_only=True)
    member_phone = serializers.CharField(source='membership.user.phone_number', read_only=True)

    class Meta:
        model = QueuePosition
        fields = [
            'id', 'cycle', 'membership', 'member_name', 'member_phone',
            'position', 'is_current', 'received_at', 'created_at'
        ]
        read_only_fields = ['id', 'created_at']


class MemberExitSerializer(serializers.Serializer):
    """Sérialiseur pour traiter un départ."""
    membership_id = serializers.UUIDField()
    exit_date = serializers.DateTimeField(required=False)


class MemberReplacementSerializer(serializers.Serializer):
    """Sérialiseur pour remplacer un membre."""
    user_id = serializers.UUIDField()
    position = serializers.IntegerField(required=False, min_value=1)


class ReserveProjectionSerializer(serializers.Serializer):
    """Sérialiseur pour la projection du fonds."""
    days = serializers.IntegerField(default=57, min_value=1)
    include_scheduled_exits = serializers.BooleanField(default=False)




class JoinRequestSerializer(serializers.ModelSerializer):
    user_name = serializers.CharField(source='user.full_name', read_only=True)
    user_phone = serializers.CharField(source='user.phone_number', read_only=True)
    group_name = serializers.CharField(source='group.name', read_only=True)

    class Meta:
        model = JoinRequest
        fields = [
            'id', 'user', 'user_name', 'user_phone', 'group', 'group_name',
            'message', 'status', 'processed_by', 'processed_at', 'response_message',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'user', 'status', 'processed_by', 'processed_at', 'created_at', 'updated_at']

    def create(self, validated_data):
        validated_data['user'] = self.context['request'].user
        return super().create(validated_data)


class JoinRequestUpdateSerializer(serializers.ModelSerializer):
    """Sérialiseur pour accepter/refuser une demande (admin seulement)."""
    class Meta:
        model = JoinRequest
        fields = ['status', 'response_message']
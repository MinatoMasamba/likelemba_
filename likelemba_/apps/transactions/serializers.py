from rest_framework import serializers
from .models import Contribution, Refund, Payout


class ContributionSerializer(serializers.ModelSerializer):
    member_name = serializers.CharField(source='membership.user.full_name', read_only=True)

    class Meta:
        model = Contribution
        fields = [
            'id', 'cycle', 'membership', 'member_name', 'amount', 'transaction_type',
            'status', 'due_date', 'is_late', 'proof_image', 'notes',
            'validated_by', 'validated_at', 'is_synced', 'local_id', 'created_at'
        ]
        read_only_fields = ['id', 'transaction_type', 'status', 'validated_by', 'validated_at', 'is_synced', 'created_at']


class ContributionValidationSerializer(serializers.Serializer):
    """Validation d'une cotisation par l'admin."""
    contribution_id = serializers.UUIDField()
    status = serializers.ChoiceField(choices=['validated', 'rejected'])


class RefundSerializer(serializers.ModelSerializer):
    class Meta:
        model = Refund
        fields = '__all__'


class PayoutSerializer(serializers.ModelSerializer):
    class Meta:
        model = Payout
        fields = '__all__'
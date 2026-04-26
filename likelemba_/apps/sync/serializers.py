from rest_framework import serializers
from .models import SyncBatch, SyncOperation


class SyncOperationSerializer(serializers.Serializer):
    local_id = serializers.CharField(max_length=100)
    entity_type = serializers.CharField(max_length=50)
    operation_type = serializers.ChoiceField(choices=['create', 'update', 'delete'])
    data = serializers.JSONField()


class SyncBatchSerializer(serializers.ModelSerializer):
    operations = SyncOperationSerializer(many=True, write_only=True)

    class Meta:
        model = SyncBatch
        fields = ['id', 'batch_id', 'device_id', 'operations', 'status', 'operations_count',
                  'success_count', 'failure_count', 'created_at', 'processed_at']
        read_only_fields = ['id', 'status', 'operations_count', 'success_count', 'failure_count',
                            'created_at', 'processed_at']

    def create(self, validated_data):
        validated_data.pop('operations')  # géré dans la vue
        return super().create(validated_data)
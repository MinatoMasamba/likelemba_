from rest_framework import generics, status, permissions
from rest_framework.response import Response
from drf_yasg.utils import swagger_auto_schema
from .models import SyncBatch, SyncOperation
from .sync_engine import SyncEngine
from .serializers import SyncBatchSerializer, SyncOperationSerializer


class SyncUploadView(generics.CreateAPIView):
    """
    Endpoint unique pour recevoir les lots de synchronisation des clients mobiles.
    """
    permission_classes = [permissions.IsAuthenticated]

    @swagger_auto_schema(
        request_body=SyncBatchSerializer,
        responses={201: "Lot traité", 400: "Erreur de validation"}
    )
    def post(self, request, *args, **kwargs):
        serializer = SyncBatchSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        # Créer le batch
        batch = SyncBatch.objects.create(
            user=request.user,
            device_id=serializer.validated_data['device_id'],
            batch_id=serializer.validated_data['batch_id'],
            operations_count=len(serializer.validated_data['operations'])
        )

        # Créer les opérations
        for op_data in serializer.validated_data['operations']:
            SyncOperation.objects.create(
                batch=batch,
                local_id=op_data['local_id'],
                entity_type=op_data['entity_type'],
                operation_type=op_data['operation_type'],
                data=op_data['data']
            )

        # Traiter immédiatement (ou déléguer à Celery pour les gros lots)
        batch = SyncEngine.process_batch(batch)

        # Préparer la réponse avec les mappings local_id -> server_id
        mapping = {}
        for op in batch.operations.filter(status='success'):
            mapping[op.local_id] = str(op.server_id) if op.server_id else None

        return Response({
            'batch_id': str(batch.id),
            'status': batch.status,
            'success_count': batch.success_count,
            'failure_count': batch.failure_count,
            'mapping': mapping
        }, status=status.HTTP_201_CREATED)


class SyncStatusView(generics.RetrieveAPIView):
    """
    Vérifier le statut d'un lot de synchronisation.
    """
    permission_classes = [permissions.IsAuthenticated]
    serializer_class = SyncBatchSerializer
    lookup_field = 'batch_id'
    queryset = SyncBatch.objects.all()

    def get_queryset(self):
        return super().get_queryset().filter(user=self.request.user)
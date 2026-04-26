from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import permissions
from drf_yasg.utils import swagger_auto_schema
from drf_yasg import openapi
from django.shortcuts import get_object_or_404
from apps.tontines.models import LikelembaGroup
from .services import ProjectionService


class FundProjectionView(APIView):
    """
    Calcule la projection du fonds de réserve pour un groupe donné.
    """
    permission_classes = [permissions.IsAuthenticated]

    @swagger_auto_schema(
        manual_parameters=[
            openapi.Parameter('group_id', openapi.IN_QUERY, type=openapi.TYPE_STRING, format='uuid'),
            openapi.Parameter('days', openapi.IN_QUERY, type=openapi.TYPE_INTEGER),
            openapi.Parameter('lambda_rate', openapi.IN_QUERY, type=openapi.TYPE_NUMBER)
        ],
        responses={200: "Projection calculée"}
    )
    def get(self, request):
        group_id = request.query_params.get('group_id')
        days = int(request.query_params.get('days', 57))
        lambda_rate = float(request.query_params.get('lambda_rate', 0.0))

        group = get_object_or_404(LikelembaGroup, id=group_id)
        # Vérifier que l'utilisateur est membre
        if not group.members.filter(user=request.user, is_active=True).exists():
            return Response({"error": "Vous n'êtes pas membre de ce groupe."}, status=403)

        result = ProjectionService.solve_edo(
            n=group.number_of_members,
            a=group.security_levy,
            alpha_0=group.penalty_rate_initial,
            T=days,
            initial_reserve=group.reserve_amount,
            lambda_rate=lambda_rate,
            s=group.contribution_amount
        )

        return Response(result)


class RiskSimulationView(APIView):
    """
    Simule des scénarios de départs pour évaluer le risque.
    """
    permission_classes = [permissions.IsAuthenticated]

    @swagger_auto_schema(
        request_body=openapi.Schema(
            type=openapi.TYPE_OBJECT,
            properties={
                'group_id': openapi.Schema(type=openapi.TYPE_STRING, format='uuid'),
                'scenarios': openapi.Schema(
                    type=openapi.TYPE_ARRAY,
                    items=openapi.Schema(
                        type=openapi.TYPE_ARRAY,
                        items=openapi.Schema(type=openapi.TYPE_INTEGER)
                    )
                )
            }
        ),
        responses={200: "Simulation terminée"}
    )
    def post(self, request):
        group_id = request.data.get('group_id')
        scenarios = request.data.get('scenarios', [])

        group = get_object_or_404(LikelembaGroup, id=group_id)
        if not group.members.filter(user=request.user, is_active=True).exists():
            return Response({"error": "Non membre."}, status=403)

        results = ProjectionService.simulate_exits(group, scenarios)
        return Response(results)
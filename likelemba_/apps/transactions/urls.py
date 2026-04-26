from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import ContributionViewSet, RefundViewSet, PayoutViewSet

router = DefaultRouter()
router.register(r'contributions', ContributionViewSet, basename='contributions')
router.register(r'refunds', RefundViewSet, basename='refunds')
router.register(r'payouts', PayoutViewSet, basename='payouts')

app_name = 'transactions'

urlpatterns = [
    path('', include(router.urls)),
]
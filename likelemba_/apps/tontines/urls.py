from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import (
    LikelembaGroupViewSet,
    CycleViewSet,
    MembershipValidationView,
    MembershipViewSet,
    JoinRequestViewSet,
    QueuePositionViewSet
)

router = DefaultRouter()
router.register(r'groups', LikelembaGroupViewSet, basename='groups')
router.register(r'cycles', CycleViewSet, basename='cycles')
router.register(r'memberships', MembershipViewSet, basename='memberships')
router.register(r'queue', QueuePositionViewSet, basename='queue')
router.register(r'join-requests', JoinRequestViewSet, basename='join-requests')

app_name = 'tontines'

urlpatterns = [
    path('groups/<uuid:group_id>/members/<uuid:user_id>/validation/',
        MembershipValidationView.as_view(),
        name='member-validation'),
    path('', include(router.urls)),
]
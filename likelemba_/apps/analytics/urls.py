from django.urls import path
from .views import FundProjectionView, RiskSimulationView

app_name = 'analytics'

urlpatterns = [
    path('projection/', FundProjectionView.as_view(), name='fund_projection'),
    path('simulate/', RiskSimulationView.as_view(), name='risk_simulation'),
]
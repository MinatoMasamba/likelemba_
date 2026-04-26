from django.urls import path
from .views import SyncUploadView, SyncStatusView

app_name = 'sync'

urlpatterns = [
    path('upload/', SyncUploadView.as_view(), name='sync_upload'),
    path('status/<str:batch_id>/', SyncStatusView.as_view(), name='sync_status'),
]
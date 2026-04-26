from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from rest_framework import permissions
from drf_yasg.views import get_schema_view
from drf_yasg import openapi

schema_view = get_schema_view(
    openapi.Info(
        title="Likelemba Sécurisé API",
        default_version='v1',
        description="Backend pour l'application de tontine sécurisée",
        contact=openapi.Contact(email="contact@likelemba.cd"),
    ),
    public=True,
    permission_classes=(permissions.AllowAny,),
)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/v1/users/', include('apps.users.urls')),
    path('api/v1/tontines/', include('apps.tontines.urls')),
    path('api/v1/transactions/', include('apps.transactions.urls')),
    path('api/v1/sync/', include('apps.sync.urls')),
    path('api/v1/analytics/', include('apps.analytics.urls')),

    # Documentation
    path('api/docs/', schema_view.with_ui('swagger', cache_timeout=0), name='schema-swagger-ui'),
    path('api/redoc/', schema_view.with_ui('redoc', cache_timeout=0), name='schema-redoc'),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
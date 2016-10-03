from django.conf.urls import url
from django.contrib import admin
from .views import repo_creations_by_month_view

urlpatterns = [
    url(r'^repo-creations-by-month', repo_creations_by_month_view),
]

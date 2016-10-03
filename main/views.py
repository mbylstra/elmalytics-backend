from django.shortcuts import render

# Create your views here.
from django.http import JsonResponse

from .models import repo_creations_by_month

def repo_creations_by_month_view(request):
    return JsonResponse(repo_creations_by_month(), safe=False)


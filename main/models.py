from __future__ import unicode_literals

from django.db import models
from django.db.models import Count
from django.db.models.functions import TruncMonth

from wham.apis.github.models import Repository


def repo_creations_by_month():

    creations_by_month = (
        Repository.objects
            # .order_by('created_at')
            .annotate(month=TruncMonth('created_at'))
            .values('month')
            .annotate(total_repos_created=Count('id'))
            .order_by('month')
    )

    data = []

    for row in creations_by_month:
        data.append(
            (row['month'].year, row['month'].month, row['total_repos_created'])
        )
    return data

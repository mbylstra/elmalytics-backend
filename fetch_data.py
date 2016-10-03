import os
from time import sleep

import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "elmalytics.settings")
django.setup()

from wham.apis.github.models import Repository
from wham.models import (
    ReachedMaxRequestsPerMinuteLimit,
    ReachedDailyRequestLimit,
)


def update_data():
    # This attempts to fetch data for ALL Elm github repos
    data = Repository.objects.wham_custom_fetch_resources(q="language:Elm", sort="updated", order="asc", per_page="100")
    while len(data['items']) > 0:
        try:
            Repository.objects.check_request_limit()
        except ReachedMaxRequestsPerMinuteLimit as e:
            print 'Reached max requests per minute. Sleeping one minute'
            sleep(60)
        except ReachedDailyRequestLimit as e:
            print 'Reached max requests per day. Sleeping one day'
            sleep(60 * 60 * 24)
        pushed_at = data['items'][-1]['pushed_at']
        print pushed_at
        data = Repository.objects.wham_custom_fetch_resources(q="language:Elm pushed:>{}".format(pushed_at), sort="updated", order="asc", per_page="100")

update_data()


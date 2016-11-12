import requests
import time

from elmalytics import settings

BASE_URL = "https://api.github.com/"


ENDPOINTS = {
    'search_repositories': 'search/repositories',
    'rate_limit': 'rate_limit',
    'repos': 'repos',
}


def get_current_rate_limits():
    """
    eg:
    {
        "core": {
          "limit": 5000,
          "remaining": 4999,
          "reset": 1372700873
        },
        "search": {
          "limit": 30,
          "remaining": 18,
          "reset": 1372697452
        }
    }
    """
    response = requests.get(
        BASE_URL + ENDPOINTS['rate_limit'],
        params=settings.GITHUB_CREDENTIALS
    )
    return response.json()['resources']


def get_current_search_rate_limit():
    return get_current_rate_limits()['search']


class Exception404(Exception):
    pass


def rate_limited_github_get(url, params, search_api=False):

    params.update(settings.GITHUB_CREDENTIALS)

    print params

    if search_api:
        current_rate_limit = get_current_rate_limits()['search']
    else:
        current_rate_limit = get_current_rate_limits()['core']
    print current_rate_limit
    if current_rate_limit['remaining'] == 0:
        now = time.time()
        reset_time = current_rate_limit['reset']
        sleep_time = (reset_time - now) + 1
        if sleep_time < 60:
            print 'hit rate limit. sleeping for {} seconds'.format(sleep_time)
        else:
            print 'hit rate limit. sleeping for {} minutes'.format(sleep_time / 60.0)
        time.sleep(sleep_time)
    response = requests.get(url, params)
    if response.status_code == 400:
        raise Exception404()
    while response.status_code != 200:
        print response.headers
        print 'status code: {}', response.status_code
        print 'response content: {}', response.content
        print 'unsuccessful get. Trying again in 10 seconds'
        time.sleep(10)
        response = requests.get(url, params)
    return response


def fetch_all_elm_repo_data():

    kwargs = {
        'q': 'language:elm',
        'sort': 'updated',
        'order': 'asc',
        'per_page': 100,
    }

    url = BASE_URL + ENDPOINTS['search_repositories']

    page_response = rate_limited_github_get(url, kwargs, search_api=True)
    items = page_response.json()['items']
    while len(items) > 0:
        yield items
        print 'fetched a page of data'
        most_recent_date_pushed_at = items[-1]['pushed_at']
        kwargs['q'] = 'language:elm pushed:>{}'.format(most_recent_date_pushed_at)
        page_response = rate_limited_github_get(url, kwargs, search_api=True)
        items = page_response.json()['items']


def fetch_newer_repos(iso_date):
    kwargs = {
        'q': 'language:elm created:>{}'.format(iso_date),
        # 'sort': 'created', # this does not work :( it just gets ignored and defaults to sorting by star count
        'order': 'asc',
        'per_page': 100,
    }
    url = BASE_URL + ENDPOINTS['search_repositories']
    page_response = rate_limited_github_get(url, kwargs, search_api=True)
    items = page_response.json()['items']
    yield items

def fetch_all_commits_for_repo(owner, repo_name, since=None):
    url = "{}/{}/{}/commits".format(
        BASE_URL + ENDPOINTS['repos'],
        owner,
        repo_name,
    )
    params = {
        'per_page': 100,
    }
    if since:
        params["since"] = since
    try:
        response = rate_limited_github_get(url, params, search_api=False)
        yield response.json()
    except Exception404 as e:
        print 'Exception404 during fetch_all_commits_for_repo'
        return


# Error

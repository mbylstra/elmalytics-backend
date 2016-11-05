from django.core.management.base import BaseCommand, CommandError

from github.models import Repository


class Command(BaseCommand):
    help = ''

    def handle(self, *args, **options):
        Repository.objects.fetch_new_repos()
        for repo in Repository.objects.all():
            repo.fetch_newest_commits()

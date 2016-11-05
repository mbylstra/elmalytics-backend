from django.core.management.base import BaseCommand, CommandError

from github.models import Repository


class Command(BaseCommand):
    help = ''

    def handle(self, *args, **options):
        Repository.objects.fetch_and_update_all()

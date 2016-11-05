from __future__ import unicode_literals

import datetime
from django.db import models
from django.contrib.postgres.fields import JSONField

from github.fetch import (
    fetch_all_elm_repo_data,
    fetch_all_commits_for_repo,
    fetch_newer_repos)


class UserManager(models.Manager):

    def update_or_create_from_data(self, data):
        return self.update_or_create(
            id=str(data['id']),
            defaults={
                'raw_data': data,
                'login': data['login'],
                'user_type': data['type'],
                'avatar_url': data['avatar_url'],
            },
        )


class User(models.Model):

    id = models.CharField(primary_key=True, max_length=255)
    raw_data = JSONField(null=True) # A full copy of the json response from the github api. Delete if the db gets too big
    login = models.CharField(max_length=255)
    avatar_url = models.URLField()
    user_type = models.CharField(max_length=255)

    objects = UserManager()


class RepositoryManager(models.Manager):

    def fetch_and_update_all(self):
        for items in fetch_all_elm_repo_data():
            self.update_or_create_data_items(items)

    def fetch_new_repos(self):
        latest_time = self.get_time_of_newest_repo()
        for items in fetch_newer_repos(latest_time):
            self.update_or_create_data_items(items)

    def update_or_create_data_items(self, items):
        for item in items:
            print item['name']
            user, _created = User.objects.update_or_create_from_data(item['owner'])
            self.update_or_create(
                id=str(item['id']),
                defaults={
                    'raw_data': item,
                    'owner': user,
                    'name': item['name'],
                    'language': item['language'],
                    'created_at': item['created_at'],
                    'updated_at': item['updated_at'],
                    'pushed_at': item['pushed_at'],
                },
            )


    def get_newest_repo(self):
        return self.all().order_by('-created_at')[0]

    def get_time_of_newest_repo(self):
        return self.get_newest_repo().created_at.isoformat()



class Repository(models.Model):

    id = models.CharField(primary_key=True, max_length=255)
    raw_data = JSONField(null=True) # A full copy of the json response from the github api. Delete if the db gets too big
    name = models.TextField()
    language = models.TextField(null=True)
    owner = models.ForeignKey('User')
    created_at = models.DateTimeField()
    updated_at = models.DateTimeField()
    pushed_at = models.DateTimeField()

    objects = RepositoryManager()

    def __unicode__(self):
        return self.name

    def fetch_newest_commits(self):
        owner_login = self.owner.login
        actual_newest_commit_time = self.get_time_of_newest_commit()
        if actual_newest_commit_time:
            since = (
                actual_newest_commit_time +
                datetime.timedelta(minutes=60) #so as to make sure the github api doesn't get confused by comparisons
            ).isoformat()
        else:
            since = None
        total_added = 0
        for items in fetch_all_commits_for_repo(owner_login, self.name, since):
            total_added += len(items)
            for item in items:
                Commit.objects.update_or_create_from_data(item, self)
        return total_added

    def get_newest_commit(self):
        try:
            return self.commit_set.order_by('-date')[0]
        except IndexError:
            return None

    def get_time_of_newest_commit(self):
        newest_commit = self.get_newest_commit()
        if newest_commit:
            return newest_commit.date
        else:
            return None


class CommitManager(models.Manager):

    def update_or_create_from_data(self, data, repository):
        author_data = data['author']
        if author_data is not None:
            user, _created = User.objects.update_or_create_from_data(author_data)
        else:
            user = None
        return self.update_or_create(
            sha=str(data['sha']),
            defaults={
                'repository': repository,
                'raw_data': data,
                'author': user,
                'date': data['commit']['author']['date']
            }
        )


class Commit(models.Model):

    sha = models.CharField(primary_key=True, max_length=255)
    raw_data = JSONField(null=True) # A full copy of the json response from the github api. Delete if the db gets too big
    author = models.ForeignKey(User, null=True) # somehow it is possible to have commits that don't have an author. I'm not sure how (perhaps because the commiter doesn't have a github account?)
    repository = models.ForeignKey(Repository)
    date = models.DateTimeField()

    objects = CommitManager()

module Queries exposing (..)


import SqlBuilder exposing(..)
import SqlBuilder.AST exposing (..)


formattedNumReposCreatedPerMonth : SimpleSelect
formattedNumReposCreatedPerMonth =
  select
    [ column "created_at_month" |> formatDate "YYYY" |> asColumn "year"
    , column "created_at_month" |> formatDate "Mon" |> asColumn "month"
    , column "total_repos_created" |> asColumn "total"
    ]
  |> fromSelect numReposCreatedPerMonth "unformatted_repos_created_per_month"


numReposCreatedPerMonth : SimpleSelect
numReposCreatedPerMonth =
  select
    [ countStar |> asColumn "total_repos_created"
    , column "created_at" |> withPrecision Month |> asColumn "created_at_month"
    ]
  |> fromTable "github_repository"
  |> groupByColumn "created_at_month"
  |> sortByColumn "created_at_month" Ascending


-- TODO: needs refactor (too much duplication, defeats the point of elm-sql-builder!)
formattedNumCommitsPerMonth : SimpleSelect
formattedNumCommitsPerMonth =
  select
    [ column "date_month" |> formatDate "YYYY" |> asColumn "year"
    , column "date_month" |> formatDate "Mon" |> asColumn "month"
    , column "num_commits" |> asColumn "total"
    ]
  |> fromSelect numCommitsPerMonth "unformatted_num_commits_per_month"

numCommitsPerMonth : SimpleSelect
numCommitsPerMonth =
  select
    [ countStar |> asColumn "num_commits"
    , column "date" |> withPrecision Month |> asColumn "date_month"
    ]
  |> fromTable "github_commit"
  |> groupByColumn "date_month"
  |> sortByColumn "date_month" Ascending


mostStarredRepos : SimpleSelect
mostStarredRepos =
  select
    [ column "github_repository.name" |> asColumn "repo_name"
    , column "github_user.login" |> asColumn "user_login"
    , column "stargazers_count" |> asColumn "num_stars"
    ]
  |> from
    [ table "github_repository"
      |> innerJoinTable "github_user"
         on (equalColumns ("github_repository.owner_id", "github_user.id"))
    ]
  |> sortByColumn "stargazers_count" Descending
  |> limit 50


totalReposCreatedByUser : SimpleSelect
totalReposCreatedByUser =
  select
    [ column "github_user.login" |> asColumn "a"
    , count "github_user.login" |> asColumn "b"
    ]
  |> from
    [ table "github_repository"
      |> innerJoinTable "github_user"
         on (equalColumns ("github_respository.owner_id", "github_user.id"))
    ]
  |> groupByColumn "github_user.login"
  |> sortByColumn "total_repos" Descending

  -- }>

-- basicJoin : SimpleSelect
-- basicJoin =
--   selectColumns ["book.name", "author.name"]
--   |> from
--     [ table "book"
--       |> innerJoinTable "author"
--          on (equalColumns ("book.author_id", "author.id"))
    -- ]

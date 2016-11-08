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
  selectColumns ["github_repository.stars", "github_repository.name"]
  |> fromTable "github_repository"
  |> sortByColumn "github_repository.star" Descending


-- total repos created
-- Select count repo as total, user
-- From user
-- Join repo
-- Group by rep
-- Order by total desc

totalReposCreatedByUser : SimpleSelect
totalReposCreatedByUser =
  selectColumns ["dfghdfgh"]
  |> from
    [ table "github_repository"
      |> innerJoinTable "github_user"
         on (equalColumns ("github_respository.owner_id", "github_user.id"))
    ]

-- basicJoin : SimpleSelect
-- basicJoin =
--   selectColumns ["book.name", "author.name"]
--   |> from
--     [ table "book"
--       |> innerJoinTable "author"
--          on (equalColumns ("book.author_id", "author.id"))
    -- ]

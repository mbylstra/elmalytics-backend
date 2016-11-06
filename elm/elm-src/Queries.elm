module Queries exposing (..)


import SqlBuilder exposing(..)
import SqlBuilder.AST exposing (..)


formattedNumReposCreatedPerMonth : SimpleSelect
formattedNumReposCreatedPerMonth =
  select
    [ column "created_at_month" |> formatDate "YYYY" |> asColumn "year"
    , column "created_at_month" |> formatDate "Mon" |> asColumn "month"
    , column "total_repos_created"
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

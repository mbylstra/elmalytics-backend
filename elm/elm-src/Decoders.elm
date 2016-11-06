module Decoders exposing (..)


import Json.Decode as Decode exposing (Decoder, object3, (:=), string, int, list, map)
import String exposing (toInt)
import Result

type alias TotalReposCreatedRow =
  { year: String
  , month : String
  , totalReposCreated : Int
  }

type alias TotalReposCreatedRowTuple =
  ( String, String, Int )

totalReposCreatedRowDecoder : Decoder TotalReposCreatedRow
totalReposCreatedRowDecoder =
    object3 TotalReposCreatedRow
      ("year" := string)
      ("month" := string)
      ("total_repos_created" := int)

totalReposCreatedRowTupleDecoder : Decoder TotalReposCreatedRowTuple
totalReposCreatedRowTupleDecoder =
    object3 (,,)
      ("year" := string)
      ("month" := string)
      ("total_repos_created" := map (toInt >> Result.withDefault 0) string)

totalReposCreatedDecoder : Decoder (List TotalReposCreatedRowTuple)
totalReposCreatedDecoder =
  list totalReposCreatedRowTupleDecoder

-- Remember that a big problem with lists in Elm is they can only contain
-- one type! So, for each column you need a list, rather than a list for each
-- row.

-- Let's not bother with this, obtaining the labels is too much of a pain
type alias NiceOutput =
  { labels : List String
  , data : List (String, String, Int)
    -- { year : List String
    -- , month : List String
    -- , totalReposCreated : List Int
    -- }
  }


-- The problem with this, is you can't generalise it!
-- So, you might be better off making a decoder that just
-- generates tuples
-- toTable rowDecoder =

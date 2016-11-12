module Decoders exposing (..)


import Json.Decode as Decode exposing (Decoder, object3, object2, (:=), string, int, list, map)
import String exposing (toInt)
import Result


-- type alias TotalReposCreatedRow =
--   { year: String
--   , month : String
--   , totalReposCreated : Int
--   }

type alias TotalReposCreatedRowTuple =
  ( String, String, Int )

-- totalReposCreatedRowDecoder : Decoder TotalReposCreatedRow
-- totalReposCreatedRowDecoder =
--     object3 TotalReposCreatedRow
--       ("year" := string)
--       ("month" := string)
--       ("total" := int)

-- type alias String2Tuple = ( String, String)

totalReposCreatedRowTupleDecoder : Decoder TotalReposCreatedRowTuple
totalReposCreatedRowTupleDecoder =
    object3 (,,)
      ("year" := string)
      ("month" := string)
      ("total" := map (toInt >> Result.withDefault 0) string)

-- totalReposCreatedDecoder : Decoder (List TotalReposCreatedRowTuple)
-- totalReposCreatedDecoder =
--   list totalReposCreatedRowTupleDecoder


mostStarredReposRowDecoder : Decoder (String, String, Int)
mostStarredReposRowDecoder =
    object3 (,,)
      ("repo_name" := string)
      ("user_login" := string)
      ("num_stars" := int)


mostReposCreatedRowDecoder : Decoder (String, Int)
mostReposCreatedRowDecoder =
    object2 (,)
      ("user_login" := string)
      ("total_repos" := map (toInt >> Result.withDefault 0) string)

-- Remember that a big problem with lists in Elm is they can only contain
-- one type! So, for each column you need a list, rather than a list for each
-- row.

-- Let's not bother with this, obtaining the labels is too much of a pain
-- type alias NiceOutput =
--   { labels : List String
--   , data : List (String, String, Int)
--     -- { year : List String
--     -- , month : List String
--     -- , totalReposCreated : List Int
--     -- }
--   }


-- The problem with this, is you can't generalise it!
-- So, you might be better off making a decoder that just
-- generates tuples
-- toTable rowDecoder =

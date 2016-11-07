port module Project exposing (..)


import Html.App
import Html exposing (Html, div )

import Json.Decode exposing (decodeString)

import Postgres exposing (connect, disconnect, query, moreQueryResults, executeSQL)

import SqlBuilder.SQLRenderer exposing (..)
import SqlBuilder.AST exposing (SimpleSelect)

import Queries exposing
  ( formattedNumReposCreatedPerMonth
  , formattedNumCommitsPerMonth
  )
import Decoders exposing (totalReposCreatedRowTupleDecoder)

type alias Flags =
  { host: String
  , port_: Int
  , database: String
  , user: String
  , password: String
  , queryName: String
  }

-- MODEL

type alias Model = String -- the queryname

init : Flags -> (Model, Cmd Msg)
init flags =
  let
    connectCmd =
      connect
        PostgresError
        Connect
        ConnectionLostError
        flags.host
        flags.port_
        flags.database
        flags.user
        flags.password
  in
    flags.queryName ! [ connectCmd ]

-- UPDATE

type Msg
  = NoOp
  | Connect Int
  | PostgresError (Int, String)
  | ConnectionLostError (Int, String)
  | Disconnect Int
  | Query (Int, List String)



queryNameToSqlSelect : String -> SimpleSelect
queryNameToSqlSelect queryName =
  case queryName of
    "formattedNumReposCreatedPerMonth" ->
      formattedNumReposCreatedPerMonth
    "formattedNumCommitsPerMonth" ->
      formattedNumCommitsPerMonth
    _ ->
      Debug.crash ("There is no SQL query named " ++ queryName)

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    NoOp ->
      model ! []

    Connect connectionId ->
        let
            l =
              Debug.log "Connect" connectionId
            queryName = model
            select = queryNameToSqlSelect queryName
            queryString = renderSimpleSelect select
            queryCmd =
              query
                PostgresError
                Query
                connectionId
                queryString
                1000
        in
            model ! [ queryCmd ]

    ConnectionLostError ( connectionId, errorMessage ) ->
        let
            l =
                Debug.log "ConnectError" ( connectionId, errorMessage )
        in
            model ! []

    PostgresError ( connectionId, errorMessage ) ->
        let
            l =
                Debug.log "ConnectionLostError" ( connectionId, errorMessage )
        in
            model ! []

    Disconnect connectionId ->
        let
            l =
                Debug.log "Disconnect" connectionId
        in
            model ! []

    Query ( connectionId, results ) ->
        let
            l =
                Debug.log "Query results fetched" True
            decodedResults : List (String, String, Int)
            decodedResults =
              results
              |> List.map (decodeString totalReposCreatedRowTupleDecoder)
              |> List.map
                  (\rowResult ->
                    case rowResult of
                      Ok result-> result
                      Err msg -> Debug.crash msg
                  )
        in
            -- model ! [ exitNode 1 ]
            model ! [ dataGenerated decodedResults ]



-- VIEW

view : Model -> Html Msg
view model =
  div [] []

main : Program Flags
main =
  Html.App.programWithFlags
    { init = init
    , update = update
    , view = view
    , subscriptions = subscriptions
    }


subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none


--------------------------------------------------------------------------------
-- Posgresql stuff

-- connect : ErrorTagger msg -> ConnectTagger msg -> ConnectionLostTagger msg -> String -> Int -> String -> String -> String -> Cmd msg
-- connect errorTagger tagger connectionLostTagger host port' database user password

port exitNode : Float -> Cmd msg
port dataGenerated : List (String, String, Int) -> Cmd msg

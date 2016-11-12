port module Project exposing (..)

-- import Dict
import Html.App
import Html exposing (Html, div )

import Json.Decode exposing (decodeString)

import Postgres exposing (connect, disconnect, query, moreQueryResults, executeSQL)

import SqlBuilder.SQLRenderer exposing (..)
import SqlBuilder.AST exposing (SimpleSelect)

import Queries exposing
  ( formattedNumReposCreatedPerMonth
  , formattedNumCommitsPerMonth
  , mostStarredRepos
  , mostReposCreated
  )
import Decoders exposing
  ( totalReposCreatedRowTupleDecoder
  , mostStarredReposRowDecoder
  , mostReposCreatedRowDecoder
  )

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
  | QueryResponse (Int, List String)


-- TODO: this needs to include the decoder
-- also consider a record? Or maybe a dict?


type alias Query decoder =
  { query : SimpleSelect
  , decoder : decoder
  }


queryNameToSqlSelect : String -> SimpleSelect
queryNameToSqlSelect queryName =
  case queryName of
    "formattedNumReposCreatedPerMonth" ->
      formattedNumReposCreatedPerMonth
    "formattedNumCommitsPerMonth" ->
      formattedNumCommitsPerMonth
    "mostStarredRepos" ->
      mostStarredRepos
    "mostReposCreated" ->
      mostReposCreated
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
                QueryResponse
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
                Debug.crash "PostgresError" ( connectionId, errorMessage )
        in
            model ! []

    Disconnect connectionId ->
        let
            l =
                Debug.log "Disconnect" connectionId
        in
            model ! []

    QueryResponse ( connectionId, results ) ->
      case model of
        "formattedNumReposCreatedPerMonth" ->
          handleTotalReposCreated model results
        "formattedNumCommitsPerMonth" ->
          handleTotalReposCreated model results
        "mostStarredRepos" ->
          handleMostStarredRepos model results
        "mostReposCreated" ->
          handleMostReposCreated model results
        _ ->
          Debug.crash ("no query named " ++ model)


filterDecodeErrors : List (Result String a) -> List a
filterDecodeErrors rows =
  rows
  |> List.map
      (\rowResult ->
        case rowResult of
          Ok result-> result
          Err msg -> Debug.crash msg
      )

handleTotalReposCreated : Model -> List String -> (Model, Cmd Msg)
handleTotalReposCreated model results =
  model !
    [ results
        |> List.map (decodeString totalReposCreatedRowTupleDecoder)
        |> filterDecodeErrors
        |> formattedNumReposCreatedPerMonthGenerated
    ]

handleMostStarredRepos : Model -> List String -> (Model, Cmd Msg)
handleMostStarredRepos model results =
  model !
    [ results
        |> List.map (decodeString mostStarredReposRowDecoder)
        |> filterDecodeErrors
        |> mostStarredReposGenerated
    ]

handleMostReposCreated : Model -> List String -> (Model, Cmd Msg)
handleMostReposCreated model results =
  model !
    [ results
        |> List.map (decodeString mostReposCreatedRowDecoder)
        |> filterDecodeErrors
        |> mostReposCreatedGenerated
    ]

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

port exitNode : Float -> Cmd msg
port formattedNumReposCreatedPerMonthGenerated : List (String, String, Int) -> Cmd msg
port mostStarredReposGenerated: List (String, String, Int) -> Cmd msg
port mostReposCreatedGenerated: List (String, Int) -> Cmd msg

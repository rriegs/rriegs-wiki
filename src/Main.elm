module Main exposing (main)

import Html
import RemoteData

type alias Model =
    { topics : List Topic
    }

type alias Topic =
    { title : String
    , content : RemoteData.WebData TopicContent
    }

type alias TopicContent =
    { source : String
    }

type Msg
    = NoOp

init : ( Model, Cmd Msg )
init =
    Model
        [ Topic "Hello" RemoteData.NotAsked
        , Topic "RemoteData" RemoteData.NotAsked
        ]
        ! []

view : Model -> Html.Html Msg
view model =
    Html.div [] (List.map viewTopic model.topics)

viewTopic : Topic -> Html.Html Msg
viewTopic topic =
    Html.div []
        [ Html.h2 [] [ Html.text topic.title ]
        , case topic.content of
              RemoteData.NotAsked -> Html.text ""

              RemoteData.Loading -> Html.text "Loading"

              RemoteData.Failure error -> Html.text (toString error)

              RemoteData.Success content -> Html.text content.source
        ]

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    model ! []

subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none

main : Program Never Model Msg
main =
    Html.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }

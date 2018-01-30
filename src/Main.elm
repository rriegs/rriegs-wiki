module Main exposing (main)

import Html

type alias Model =
    { topics : List Topic
    }

type alias Topic =
    { title : String
    }

type Msg
    = NoOp

init : ( Model, Cmd Msg )
init =
    Model [ Topic "Hello", Topic "Topics" ]
        ! []

view : Model -> Html.Html Msg
view model =
    Html.div [] (List.map viewTopic model.topics)

viewTopic : Topic -> Html.Html Msg
viewTopic topic =
    Html.div []
        [ Html.h2 [] [ Html.text topic.title ]
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

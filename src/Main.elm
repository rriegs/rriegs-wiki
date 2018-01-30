module Main exposing (main)

import Html

type alias Model = String

type Msg
    = NoOp

init : ( Model, Cmd Msg )
init =
    "Hello Elm Architecture!" ! []

view : Model -> Html.Html Msg
view model =
    Html.text model

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

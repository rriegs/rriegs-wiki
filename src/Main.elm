module Main exposing (main)

import Html
import Html.Events
import Http
import Markdown
import Navigation
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
    , body : Html.Html Msg
    }

type Msg
    = NoOp
    | OnLocationChange Navigation.Location
    | OnGetTopic String (RemoteData.WebData String)
    | OnEdit String String
    | OnSave String String

init : Navigation.Location -> ( Model, Cmd Msg )
init location =
    let
        titles =
            if String.startsWith "#" location.hash then
                [ String.dropLeft 1 location.hash ]
            else
                [ "Hello" ]

        createTopic title =
            Topic title RemoteData.Loading
    in
        Model (List.map createTopic titles)
            ! List.map getTopic titles



getTopic : String -> Cmd Msg
getTopic title =
    Http.getString ("data/" ++ title ++ ".md")
        |> RemoteData.sendRequest
        |> Cmd.map (OnGetTopic title)

putTopic : String -> String -> Cmd Msg
putTopic title source =
    Http.request
        { method = "PUT"
        , headers = []
        , url = "data/" ++ title ++ ".md"
        , body = Http.stringBody "text/plain" source
        , expect = Http.expectStringResponse (\_ -> Ok ())
        , timeout = Nothing
        , withCredentials = False
        }
        |> Http.send (\_ -> NoOp)



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

              RemoteData.Failure error ->
                  viewEditor topic.title (Html.text (toString error)) ""

              RemoteData.Success content ->
                  viewEditor topic.title content.body content.source
        ]

viewEditor : String -> Html.Html Msg -> String -> Html.Html Msg
viewEditor title body source =
    Html.div []
        [ body
        , Html.div []
            [ Html.textarea
                  [ Html.Events.onInput (OnEdit title) ]
                  [ Html.text source ]
            ]
        , Html.div []
            [ Html.button
                  [ Html.Events.onClick (OnSave title source) ]
                  [ Html.text "Save" ]
            ]
        ]



update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp -> model ! []

        OnLocationChange location ->
            if String.startsWith "#" location.hash then
                let
                    title = String.dropLeft 1 location.hash
                in
                    if List.any (\topic -> topic.title == title) model.topics then
                        model ! []
                    else
                        Model (Topic title RemoteData.Loading :: model.topics)
                            ! [ getTopic title ]
            else
                model ! []

        OnGetTopic title response ->
            Model (List.map (updateTopic title response) model.topics)
                ! []

        OnEdit title source ->
            Model (List.map (updateTopic title (RemoteData.Success source)) model.topics)
                ! []

        OnSave title source ->
            model
                ! [ putTopic title source ]

updateTopic : String -> RemoteData.WebData String -> Topic -> Topic
updateTopic title response topic =
    let
        createTopicContent source =
            TopicContent source (Markdown.toHtml [] source)
    in
        if (topic.title == title) then
            Topic title (RemoteData.map createTopicContent response)
        else
            topic



subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



main : Program Never Model Msg
main =
    Navigation.program OnLocationChange
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }

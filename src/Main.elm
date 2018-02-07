port module Main exposing (main)

import Dom.Scroll
import Html
import Html.Attributes
import Html.Events
import HtmlParser
import HtmlParser.Util
import Http
import Navigation
import RemoteData
import Task



type alias Model =
    { topics : List Topic
    }

type alias Topic =
    { title : String
    , content : RemoteData.WebData TopicContent
    }

type alias TopicContent =
    { source : String
    , body : List (Html.Html Msg)
    }

type Msg
    = NoOp
    | OnLocationChange Navigation.Location
    | OnGetTopic String (RemoteData.WebData String)
    | OnMarkdownHtml ( String, String, String )
    | OnClose String
    | OnEdit String String
    | OnSave String String
    | OnDelete String

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

delTopic : String -> Cmd Msg
delTopic title =
    Http.request
        { method = "DELETE"
        , headers = []
        , url = "data/" ++ title ++ ".md"
        , body = Http.emptyBody
        , expect = Http.expectStringResponse (\_ -> Ok ())
        , timeout = Nothing
        , withCredentials = False
        }
        |> Http.send (\_ -> NoOp)



scrollToTop : Cmd Msg
scrollToTop =
    Cmd.batch
        [ Task.attempt (\_ -> NoOp) (Dom.Scroll.toTop "html")
        , Task.attempt (\_ -> NoOp) (Dom.Scroll.toTop "body")
        ]



view : Model -> Html.Html Msg
view model =
    Html.div [] (List.map viewTopic model.topics)

viewTopic : Topic -> Html.Html Msg
viewTopic topic =
    Html.div
        [ Html.Attributes.class "topic"
        , Html.Attributes.id topic.title
        ]
        [ Html.h2 [] [ Html.text topic.title ]
        , Html.div []
            [ Html.button
                  [ Html.Events.onClick (OnClose topic.title) ]
                  [ Html.text "Close" ]
            ]
        , case topic.content of
              RemoteData.NotAsked -> Html.text ""

              RemoteData.Loading -> Html.text "Loading"

              RemoteData.Failure error ->
                  viewEditor topic.title [ Html.text (toString error) ] ""

              RemoteData.Success content ->
                  viewEditor topic.title content.body content.source
        ]

viewEditor : String -> List (Html.Html Msg) -> String -> Html.Html Msg
viewEditor title body source =
    Html.div []
        [ Html.div [] body
        , Html.div []
            [ Html.textarea
                  [ Html.Attributes.class "editor"
                  , Html.Events.onInput (OnEdit title)
                  ]
                  [ Html.text source ]
            ]
        , Html.div []
            [ Html.button
                  [ Html.Events.onClick (OnSave title source) ]
                  [ Html.text "Save" ]
            , Html.button
                  [ Html.Events.onClick (OnDelete title) ]
                  [ Html.text "Delete" ]
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
                            ! [ getTopic title, scrollToTop ]
            else
                model ! []

        OnGetTopic title response ->
            Model (List.map (updateTopic title (RemoteData.map (\source -> ( source, "Parsing" )) response)) model.topics)
                ! case response of
                      RemoteData.Success source ->
                          [ parseMarkdown ( title, source ) ]
                      _ -> []

        OnMarkdownHtml ( title, source, rawHtml ) ->
            Model (List.map (updateTopic title (RemoteData.Success ( source, rawHtml ))) model.topics)
                ! []

        OnClose title ->
            Model (List.filter (\topic -> topic.title /= title) model.topics)
                ! [ Navigation.newUrl "#" ]

        OnEdit title source ->
            Model (List.map (updateTopic title (RemoteData.Success ( source, "Parsing" ))) model.topics)
                ! [ parseMarkdown ( title, source ) ]

        OnSave title source ->
            model
                ! [ putTopic title source ]

        OnDelete title ->
            model
                ! [ delTopic title ]

updateTopic : String -> RemoteData.WebData ( String, String ) -> Topic -> Topic
updateTopic title response topic =
    let
        createTopicContent ( source, rawHtml ) =
            HtmlParser.parse rawHtml
                |> HtmlParser.Util.toVirtualDom
                |> TopicContent source
    in
        if (topic.title == title) then
            Topic title (RemoteData.map createTopicContent response)
        else
            topic



subscriptions : Model -> Sub Msg
subscriptions model =
    markdownHtml OnMarkdownHtml



port parseMarkdown : ( String, String ) -> Cmd msg

port markdownHtml : (( String, String, String ) -> msg) -> Sub msg

main : Program Never Model Msg
main =
    Navigation.program OnLocationChange
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }

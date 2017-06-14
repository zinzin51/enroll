module AddressComponent exposing (main)

{-| Simple Address Component - represents a simple, universal address data

@docs main

-}

import Html exposing (div, select)
import Html.Attributes exposing (defaultValue, type_)
import Html.Events exposing (onInput)
import Platform
import Platform.Cmd
import Platform.Sub
import Json.Decode exposing (Value, Decoder, string, decodeValue, list)
import Json.Decode.Pipeline exposing (required, decode)
import Result exposing (withDefault)

flagDecoder : Json.Decode.Decoder Model
flagDecoder =
    decode Model
       |> required "kind" string
       |> required "address_1" string
       |> required "address_2" string
       |> required "city" string
       |> required "state" string
       |> required "zip" string
       |> required "stateData" (list string)
    

{-| Represent the Address model itself -}
type alias Model = {
               kind : String,
               address_1 : String,
               address_2 : String,
               city : String,
               state : String,
               zip : String,
               stateData : List String
             }

initialModel : Model
initialModel = { 
                 kind = "home",
                 address_1 = "",
                 address_2 = "",
                 city = "",
                 state = "",
                 zip = "",
                 stateData = []
               }

type UpdateMessage = UpdateStreet1 String
                     | UpdateStreet2 String
                     | UpdateCity String
                     | UpdateState String
                     | UpdateZip String

update : UpdateMessage -> Model -> (Model, Platform.Cmd.Cmd UpdateMessage)
update msg model = case msg of 
                     (UpdateStreet1 s1) -> ({model | address_1 = s1}, Platform.Cmd.none)
                     (UpdateStreet2 s2) -> ({model | address_2 = s2}, Platform.Cmd.none)
                     (UpdateCity c) -> ({model | city = c}, Platform.Cmd.none)
                     (UpdateZip v) -> ({model | zip = v}, Platform.Cmd.none)
                     (UpdateState st) -> ({model | state = st}, Platform.Cmd.none)

view : Model -> Html.Html UpdateMessage
view m = div [] [
    addressFormRow [
      addressControlCell "col-md-6 col-sm-6 col-xs-12" [
        addressTextField "address_1" m.address_1 UpdateStreet1
      ],
      addressControlCell "col-md-6 col-sm-6 col-xs-12" [
        addressTextField "address_2" m.address_2 UpdateStreet2
      ]
    ],
    addressFormRow [
      addressControlCell "col-md-4 col-sm-4 col-xs-12" [
        addressTextField "city" m.city UpdateCity],
      addressControlCell "col-md-4 col-sm-4 col-xs-12" [
        select [Html.Attributes.name "state", Html.Events.onInput UpdateState] (selectedOptions m.state m.stateData)],
      addressControlCell "col-md-4 col-sm-4 col-xs-12" [
        addressTextField "zip" m.zip UpdateZip]
    ]
  ]

selectedOptions val opts = List.map (\x -> Html.option [(Html.Attributes.selected (val == x)), Html.Attributes.value x] [Html.text x]) opts

addressTextField : String -> String -> (String -> UpdateMessage) -> Html.Html UpdateMessage
addressTextField n v oi =  Html.input [Html.Attributes.class "floatlabel form-control", type_ "text", Html.Attributes.name n, onInput oi, defaultValue v] []

addressControlCell : String -> List (Html.Html UpdateMessage) -> Html.Html UpdateMessage
addressControlCell moreStyle html = div [Html.Attributes.class ("form-group form-group-lg no-pd" ++ moreStyle)] html

addressFormRow : List (Html.Html UpdateMessage) -> Html.Html UpdateMessage
addressFormRow html = div [Html.Attributes.class "row row-form-wrapper no-buffer address-row home-div"] html

{-| Start the program -}
main : Platform.Program Json.Decode.Value Model UpdateMessage
main =
    Html.programWithFlags
        { 
          init = (\flags -> (withDefault initialModel (Json.Decode.decodeValue flagDecoder flags), Platform.Cmd.none))
        , view = view
        , update = update
        , subscriptions = (\_ -> Platform.Sub.none)
        }

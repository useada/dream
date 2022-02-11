(* This file is part of Dream, released under the MIT license. See LICENSE.md
   for details, or visit https://github.com/aantron/dream.

   Copyright 2021 Anton Bachin *)



(* Note: this is not a stable API! *)



type client
type server
type 'a message
type request = client message
type response = server message

type 'a promise = 'a Lwt.t
type handler = request -> response promise
type middleware = handler -> handler



val request :
  ?method_:[< Method.method_ ] ->
  ?target:string ->
  ?version:int * int ->
  ?headers:(string * string) list ->
  Stream.stream ->
  Stream.stream ->
    request

val method_ : request -> Method.method_
val target : request -> string
val version : request -> int * int
val set_method_ : request -> [< Method.method_ ] -> unit
val set_target : request -> string -> unit
val set_version : request -> int * int -> unit



val response :
  ?status:[< Status.status ] ->
  ?code:int ->
  ?headers:(string * string) list ->
  Stream.stream ->
  Stream.stream ->
    response

val status : response -> Status.status



val header : 'a message -> string -> string option
val headers : 'a message -> string -> string list
val all_headers : 'a message -> (string * string) list
val has_header : 'a message -> string -> bool
val add_header : 'a message -> string -> string -> unit
val drop_header : 'a message -> string -> unit
val set_header : 'a message -> string -> string -> unit
val set_all_headers : 'a message -> (string * string) list -> unit
val sort_headers : (string * string) list -> (string * string) list



val body : 'a message -> string promise
val set_body : 'a message -> string -> unit



val read : Stream.stream -> string option promise
val write : Stream.stream -> string -> unit promise
val flush : Stream.stream -> unit promise
val close : Stream.stream -> unit promise
val client_stream : 'a message -> Stream.stream
val server_stream : 'a message -> Stream.stream
val set_client_stream : 'a message -> Stream.stream -> unit
val set_server_stream : 'a message -> Stream.stream -> unit



(* TODO Is there any reason not to have a separate WebSocket type? Would we want
   to do anything with a WebSocket that we normally do with responses? The
   answer is no... It's easier to have a separate type. *)
val create_websocket : response -> (Stream.stream * Stream.stream)
val get_websocket : response -> (Stream.stream * Stream.stream) option
val close_websocket : ?code:int -> Stream.stream * Stream.stream -> unit promise

type text_or_binary = [
  | `Text
  | `Binary
]

type end_of_message = [
  | `End_of_message
  | `Continues
]

(* TODO This also needs message length limits. *)
val receive :
  Stream.stream -> string option promise
val receive_fragment :
  Stream.stream -> (string * text_or_binary * end_of_message) option promise
val send :
  ?text_or_binary:text_or_binary ->
  ?end_of_message:end_of_message ->
  Stream.stream ->
  string ->
    unit promise



val no_middleware : middleware
val pipeline : middleware list -> middleware



type 'a field
val new_field : ?name:string -> ?show_value:('a -> string) -> unit -> 'a field
val field : 'b message -> 'a field -> 'a option
val set_field : 'b message -> 'a field -> 'a -> unit
val fold_fields : (string -> string -> 'a -> 'a) -> 'a -> 'b message -> 'a

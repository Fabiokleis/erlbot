-module(discord_validation_middleware).
-behaviour(cowboy_middleware).

-export([execute/2]).

%% -define(INTERACTIONS_REQUEST, 
%% 	#{
%% 	  1 => pong,
%% 	  2 => application_command,
%% 	  3 => message_component,
%% 	  4 => application_command_autocomplete,
%% 	  5 => modal_submit
%% 	 }
%%        ).

%% -define(INTERACTIONS_RESPONSE,
%% 	#{
%% 	  1 => pong,
%% 	  4 => channel_message_with_source,
%% 	  5 => deferred_channel_message_with_source,
%% 	  6 => deferred_update_message,
%% 	  7 => update_message,
%% 	  8 => application_command_autocomplete_result,
%% 	  9 => modal,
%% 	  10 => premium_required
%% 	 }
%%        ).

hexstr_to_bin(S) ->
    hexstr_to_bin(S, []).

hexstr_to_bin([], Acc) ->
    list_to_binary(lists:reverse(Acc));
hexstr_to_bin([X,Y|T], Acc) ->
    {ok, [V], _} = io_lib:fread("~16u", [X,Y]),
    hexstr_to_bin(T, [V | Acc]);
hexstr_to_bin([X], Acc) -> % Handling odd-length strings
    hexstr_to_bin([X, $0], Acc); % Pad with '0'
hexstr_to_bin([X|T], Acc) ->
    {ok, [V], _} = io_lib:fread("~16u", [X]),
    hexstr_to_bin(T, [V | Acc]).

verify_key(RawBody, Signature, Timestamp, PubKey) -> 
    SignBin = hexstr_to_bin(Signature),
    PkBin = hexstr_to_bin(PubKey),
    Msg = <<Timestamp/binary, RawBody/binary>>,

    enacl:sign_verify_detached(SignBin, Msg, PkBin).
	

execute(Req=#{headers := #{<<"x-signature-ed25519">> := SignKey, <<"x-signature-timestamp">> := SignTs}}, Env) ->
    PubKey = cowboy:get_env(erlbot_listener, pub_key),
   
    RawBody = case cowboy_req:read_body(Req) of
		  {ok, Data, _} -> Data;
		  _ -> []
	      end,

    case verify_key(RawBody, bitstring_to_list(SignKey), SignTs, PubKey) of
	true -> 
	    io:format("valid signature~n"),
	    {ok, Req, Env};
	false -> 
	    io:format("invalid signature~n"),
	    {stop, cowboy_req:reply(401, Req)}
    end;

execute(Req, Env) ->
    {ok, Req, Env}.

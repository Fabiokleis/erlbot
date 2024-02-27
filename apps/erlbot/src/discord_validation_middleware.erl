-module(discord_validation_middleware).
-behaviour(cowboy_middleware).

-export([execute/2]).

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
	

read_body(Req0, Acc) ->
    case cowboy_req:read_body(Req0) of
        {ok, Data, Req} -> {ok, <<Acc/binary, Data/binary>>, Req};
        {more, Data, Req} -> read_body(Req, <<Acc/binary, Data/binary>>)
    end.

execute(Req=#{headers := #{<<"x-signature-ed25519">> := SignKey, <<"x-signature-timestamp">> := SignTs}}, Env) ->
    PubKey = cowboy:get_env(erlbot_listener, pub_key),
   
    {ok, RawBody, Req0} = read_body(Req, <<>>),
    cowboy:set_env(erlbot_listener, body, RawBody),
   
    case verify_key(RawBody, bitstring_to_list(SignKey), SignTs, PubKey) of
	true ->
	    {ok, Req0, Env};
	false -> 
	    {stop, cowboy_req:reply(401, #{<<"Content-type">> => <<"plain/text">>}, <<"Bad request signature">>, Req0)}
    end;

execute(Req, _) ->
    {stop, cowboy_req:reply(400, Req)}.

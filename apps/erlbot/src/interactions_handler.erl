-module(interactions_handler).
-behaviour(cowboy_handler).

-export([init/2]).
-import(discord_utils, [bot_headers/0]).

create_interaction() ->
    jiffy:encode(#{
      type => 4,
      data => #{content => <<"a health check message from mr john bot API ...">>}
     }).

init(Req0, State) ->
    Headers = maps:from_list(bot_headers()),
    Req = cowboy_req:reply(200,
        Headers#{<<"Content-Type">> => <<"application/json">>},
        create_interaction(),
        Req0),
    {ok, Req, State}.

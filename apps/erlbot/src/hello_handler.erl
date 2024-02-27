-module(hello_handler).
-behaviour(cowboy_handler).

-export([init/2]).

init(Req0, State) ->
    Req = cowboy_req:reply(200,
        #{<<"Content-Type">> => <<"plain/text">>},
        <<"Hello Erlang!">>,
        Req0),
    {ok, Req, State}.

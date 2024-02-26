-module(hello_handler).
-behaviour(cowboy_handler).

-export([init/2]).
-import(discord_utils, [discord_request/1]).

init(Req0, State) ->
    Dreq = discord_request({post, command, jiffy:encode(#{
					     name => <<"ping">>,
					     type => 1,
					     description => <<"ping pong health check!">>
					  })}),
    io:format("discord req: ~p~n", [Dreq]),
    Req = cowboy_req:reply(200,
        #{<<"Content-Type">> => <<"plain/text">>},
        <<"Hello Erlang!">>,
        Req0),
    {ok, Req, State}.

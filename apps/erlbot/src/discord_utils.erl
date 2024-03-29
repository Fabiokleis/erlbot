-module(discord_utils).

-export([bot_headers/0, parse_body/1, discord_request/1]).
-define(DISCORD_API_URL, "https://discord.com/api/v10/applications/").

parse_body([] = _) -> invalid_json;
parse_body(RawBody) ->
    case catch jiffy:decode(RawBody, [return_maps]) of
       {'EXIT', _} -> invalid_json;
       Json -> Json
    end.

bot_headers() ->
    [{"Authorization", cowboy:get_env(erlbot_listener, token)},
     {"User-Agent", "DiscordBot (https://github.com/fabiokleis/erlbot, 0.1.0)"}].

format_url(Route) ->
    lists:concat([?DISCORD_API_URL, cowboy:get_env(erlbot_listener, app_id), Route]).

discord_request({post, command, Body}) ->
    io:format("url: ~p~nbody: ~p~n", [format_url("/commands"), Body]),
    httpc:request(post, {format_url("/commands"), bot_headers(), "application/json; charset=UTF-8", Body}, [], []).

-module(interactions_handler).
-behaviour(cowboy_handler).

-export([init/2]).
-import(discord_utils, [bot_headers/0]).

-define(INTERACTIONS_REQUEST, 
	#{
	  1 => pong,
	  2 => application_command,
	  3 => message_component,
	  4 => application_command_autocomplete,
	  5 => modal_submit
	 }
       ).

-define(INTERACTIONS_RESPONSE,
	#{
	  1 => pong,
	  4 => channel_message_with_source,
	  5 => deferred_channel_message_with_source,
	  6 => deferred_update_message,
	  7 => update_message,
	  8 => application_command_autocomplete_result,
	  9 => modal,
	  10 => premium_required
	 }
       ).

match_interaction({response, Opt}) ->
    maps:get(Opt, ?INTERACTIONS_RESPONSE, []);
match_interaction({request, Opt}) ->
    maps:get(Opt, ?INTERACTIONS_REQUEST, []).

create_interaction({InteractionType, #{<<"type">> := Type}}) ->
    case match_interaction({InteractionType, Type}) of
	pong -> {200, jiffy:encode(#{type => 1})};
	[] -> invalid_interaction;
	_ -> todo
    end.

parse_body([] = _) -> invalid_json;
parse_body(RawBody) ->
    case catch jiffy:decode(RawBody, [return_maps]) of
       {'EXIT', _} -> invalid_json;
       Json -> Json
    end.

init(Req=#{method := <<"POST">>, headers := #{<<"content-type">> := <<"application/json">>}}, State) ->
    RawBody = cowboy:get_env(erlbot_listener, body),

    case parse_body(RawBody) of
	invalid_json -> {ok, cowboy_req:reply(400, Req), State};
	Json -> case create_interaction({request, Json}) of
		    {Code, Body} -> {ok, cowboy_req:reply(Code, #{<<"content-type">> => <<"application/json">>}, Body, Req), State};
		    invalid_interaction -> {ok, cowboy_req:reply(400, Req), State};
		    todo -> io:format("caiu no todo?~n"), todo
		end
    end.

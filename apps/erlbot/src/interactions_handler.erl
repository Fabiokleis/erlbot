-module(interactions_handler).
-behaviour(cowboy_handler).

-export([init/2]).
-import(discord_utils, [parse_body/1]).

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

-define(INTERACTIONS_REQUEST, 
	#{
	  1 => pong,
	  2 => application_command,
	  3 => message_component,
	  4 => application_command_autocomplete,
	  5 => modal_submit
	 }
       ).

%% match_interaction({response, Opt}) ->
%%     maps:get(Opt, ?INTERACTIONS_RESPONSE, []);
match_interaction({request, Opt}) ->
    maps:get(Opt, ?INTERACTIONS_REQUEST, []).

match_command(#{<<"name">> := Name}) -> 
    case Name of
	<<"olar">> -> 
	    {
	     olar, 
	     #{
	       type => 4,
	       data => #{content => <<"olar I'm mr john bot, an erlang discord application....">>}
	      }
	    };
	<<"ping">> ->
	    {
	     ping,
	     #{
	       type => 4,
	       data => #{content => <<"pong from mr bot.">>}
	      }
	    };
	_ -> todo
    end.


create_interaction(#{<<"type">> := 1}) ->
    {200, jiffy:encode(#{type => 1})}; %% discord ack
create_interaction(#{<<"type">> := Type, <<"data">> := Data}) ->
    case match_interaction({request, Type}) of
	application_command -> 
	    case match_command(Data) of
		{_, Payload} -> {200, jiffy:encode(Payload)};
		todo -> todo
	    end;
	[] -> invalid_interaction;
	_ -> todo
    end.

init(Req=#{method := <<"POST">>, headers := #{<<"content-type">> := <<"application/json">>}}, State) ->
    RawBody = cowboy:get_env(erlbot_listener, body),

    case parse_body(RawBody) of
	invalid_json -> {ok, cowboy_req:reply(400, Req), State};
	Json -> io:format("body: ~p~n", [Json]), case create_interaction(Json) of
		    {Code, Body} -> {ok, cowboy_req:reply(Code, #{<<"content-type">> => <<"application/json">>}, Body, Req), State};
		    invalid_interaction -> {ok, cowboy_req:reply(400, Req), State};
		    todo -> io:format("caiu no todo?~n"), todo
		end
    end.

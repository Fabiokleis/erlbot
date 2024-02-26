%%%-------------------------------------------------------------------
%% @doc erlbot public API
%% @end
%%%-------------------------------------------------------------------

-module(erlbot_app).

-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    {ok, Port} = application:get_env(erlbot, port),
    {ok, Token} = application:get_env(erlbot, token),
    {ok, AppId} = application:get_env(erlbot, app_id),
    {ok, PubKey} = application:get_env(erlbot, pub_key),
    io:format("~p~n~p~n~p~n~p~n", [Port, Token, AppId, PubKey]),

    Dispatch = cowboy_router:compile([
        {'_', [
	       {"/interactions", interactions_handler, []},
	       {"/", hello_handler, []}
	  ]}
    ]),
    {ok, _} = cowboy:start_clear(
		erlbot_listener,
		[Port],
		#{env => #{dispatch => Dispatch, token => Token, app_id => AppId, pub_key => PubKey},
		middlewares => [cowboy_router, discord_validation_middleware, cowboy_handler]}
    ),
    erlbot_sup:start_link().

stop(_State) ->
    ok = cowboy:stop_listener(erlbot_listener).

%% internal functions

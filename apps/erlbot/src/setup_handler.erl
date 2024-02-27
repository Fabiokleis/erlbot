-module(setup_handler).
-behaviour(cowboy_handler).

-export([init/2]).
-import(discord_utils, [bot_headers/0, discord_request/1]).

%% https://discord.com/developers/docs/interactions/application-commands#application-command-object-application-command-types
create_commands() ->
    discord_request({post, command, 
		     jiffy:encode(
		       #{
			 type => 1,
			 name => <<"olar">>,
			 description => <<"salu">>
			}
		      )
		    }),
    discord_request({post, command, 
		     jiffy:encode(
		       #{
			 type => 1,
			 name => <<"ping">>,
			 description => <<"ping ack">>
			}
		      )
		    }).

init(Req=#{method := <<"GET">>}, State) ->
    create_commands(),
    {ok, cowboy_req:reply(200, #{<<"content-type">> => <<"text/plain">>}, <<"Setup endpoint done!">>, Req), State}.

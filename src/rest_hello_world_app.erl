%% Feel free to use, reuse and abuse the code in this file.

%% @private
-module(rest_hello_world_app).
-behaviour(application).

%% API.
-export([start/2]).
-export([stop/1]).

%% API.

-import(routing,[routes/0]). 

start(_Type, _Args) ->
	Dispatch = cowboy_router:compile(routes()),
	{ok, _} = cowboy:start_http(http, 100, [{port, 8002}], [
		{env, [{dispatch, Dispatch}]}
	]),
	rest_hello_world_sup:start_link().

stop(_State) ->
	ok.

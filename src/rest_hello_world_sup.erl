%% Feel free to use, reuse and abuse the code in this file.

%% @private
-module(rest_hello_world_sup).
-behaviour(supervisor).

%% API.
-export([start_link/0]).

%% supervisor.
-export([init/1]).

%% API.

-spec start_link() -> {ok, pid()}.
start_link() ->
	crypto:start(),
    application:start(emysql),

    emysql:add_pool(hello_pool, [{size,1},
                 {user,"root"},
                 {password,""},
                 {database,"LycosMessenger"},
                 {encoding,utf8}]),
	supervisor:start_link({local, ?MODULE}, ?MODULE, []).

%% supervisor.

init([]) ->
	Procs = [],
	{ok, {{one_for_one, 10, 10}, Procs}}.

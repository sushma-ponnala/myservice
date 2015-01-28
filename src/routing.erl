-module(routing).

-export([routes/0]).

routes() ->
	[
		{'_', [
			{"/", toppage_handler, []},
			{"/register", register_handler, []},
			{"/login", login_handler, []}
		]}
	].
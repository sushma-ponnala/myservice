-module(routing).

-export([routes/0]).

routes() ->
	[
		{'_', [
			{"/", toppage_handler, []},
			{"/user", user_handler, []},
			{"/login", login_handler, []}
		]}
	].
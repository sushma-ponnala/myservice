%% Feel free to use, reuse and abuse the code in this file.

%% @doc Hello world handler.
-module(toppage_handler).

-export(
  [ init/3, 
    content_types_accepted/2,
    content_types_provided/2,
    terminate/3,
    allowed_methods/2,
    handle_request/2,
    delete_resource/2,
    process_response/5,
    process_request/3
  ]).

init(_Transport, _Req, []) -> {upgrade, protocol, cowboy_rest}.

terminate(_Reason, _Req, _State) -> ok.

allowed_methods(Req, State) -> 
	% io:format("allowed_methods\n\n\n"),
	{[<<"GET">>, <<"POST">>, <<"PUT">>, <<"DELETE">>], Req, State}.

content_types_accepted(Req, State) -> 
	% io:format("content_types_accepted\n\n\n"),
	{[{<<"application/json">>, handle_request}], Req, State}.

content_types_provided(Req, State) -> 
	% io:format("content_types_provided\n\n\n"),
	{[{<<"application/json">>, handle_request}], Req, State}.

delete_resource(Req, State) -> 
	% io:format("delete\n\n\n"),
	handle_request(Req, State).

handle_request(Req, State) ->
	% io:format("handle_request\n\n"),
    {Method, Req2} = cowboy_req:method(Req),
	process_request(Method, Req2, State).

process_request(<<"GET">>, Req, State) ->
	% io:format("get process_request \n\n\n"),
	

    Result = emysql:execute(hello_pool, <<"select ID, USERNAME from lycusers">>),
    JSON = emysql:as_json(Result),
    Body = jsx:encode(JSON),
    % io:format(extended_start_script),
	% Body = <<"{\"rest\": \"Hello GET World!\"}">>,
	process_response("NORMAL", Body, Req, State, 200);

process_request(<<"POST">>, Req, State) ->
	% io:format("post process_request \n\n\n"),
    Body = <<"{\"rest\": \"Hello POST World!\"}">>,
	process_response("PRESET", Body, Req, State, 200);

process_request(<<"PUT">>, Req, State) ->
	% io:format("put process_request \n\n\n"),
	Body = <<"{\"rest\": \"Hello PUT World!\"}">>,
	process_response("PRESET", Body, Req, State, 200);

process_request(<<"DELETE">>, Req, State) ->
	% io:format("delete process_request \n\n\n"),
	Body = <<"{\"rest\": \"Hello DELETE World!\"}">>,
	process_response("PRESET", Body, Req, State, 200).

process_response("PRESET", Body, Req, State, StatusCode)->
	Req2 = cowboy_req:set_resp_header(<<"StatusCode">>, StatusCode, Req),
	Req3 = cowboy_req:set_resp_body(Body, Req2),
    {true, Req3, State};
    
process_response("NORMAL", Body, Req, State, StatusCode)->
	Req2 = cowboy_req:set_resp_header(<<"StatusCode">>, StatusCode, Req),
	{Body, Req2, State}.
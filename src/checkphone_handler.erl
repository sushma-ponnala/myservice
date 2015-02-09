%% Feel free to use, reuse and abuse the code in this file.

%% @doc Hello world handler.
-module(checkphone_handler).

-export(
  [ init/3, 
    content_types_accepted/2,
    terminate/3,
    allowed_methods/2,
    handle_request/2,
    process_response/5,
    process_request/3
  ]).

init(_Transport, _Req, []) -> {upgrade, protocol, cowboy_rest}.

terminate(_Reason, _Req, _State) -> ok.

allowed_methods(Req, State) -> 
	% io:format("allowed_methods\n\n\n"),
	{[<<"POST">>], Req, State}.

content_types_accepted(Req, State) -> 
	% io:format("content_types_accepted\n\n\n"),
	{[  
		{<<"application/x-www-form-urlencoded">>, handle_request},
		{<<"application/json">>, handle_request}
		], Req, State}.

handle_request(Req, State) ->
	% io:format("handle_request\n\n"),
    {Method, Req2} = cowboy_req:method(Req),
	process_request(Method, Req2, State).

process_request(<<"POST">>, Req, State) ->
	% io:format("post process_request \n\n\n"),
    % Body = <<"{\"rest\": \"Hello POST World!\"}">>,

    {ok, PostVals, Req2} = cowboy_req:body_qs(Req),
    % TODO: Perform form validations
	UserName = binary_to_list(proplists:get_value(<<"userName">>, PostVals)),
	Phone = binary_to_list(proplists:get_value(<<"phone">>, PostVals)),
	
	Result = emysql:execute(hello_pool, "SELECT PHONE FROM lycusers	WHERE USERNAME = '"++ UserName ++"' AND
				PHONE = '"++Phone++"'		
				"),
	% Id = integer_to_list(emysql:insert_id(Result1)),
	% % % TODO: check is row inserted successfully
 %    Result2 = emysql:execute(hello_pool, "SELECT FIRSTNAME, LASTNAME FROM lycusers WHERE ID = '"++Id++"'"),
    % TODO: check if row exist
    JSON = emysql:as_json(Result),
    Body = jsx:encode(JSON),
	process_response("PRESET", Body, Req2, State, 200).

process_response("PRESET", Body, Req, State, StatusCode)->
	Req2 = cowboy_req:set_resp_header(<<"StatusCode">>, StatusCode, Req),
	Req3 = cowboy_req:set_resp_body(Body, Req2),
    {true, Req3, State}.
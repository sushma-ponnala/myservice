%% Feel free to use, reuse and abuse the code in this file.

%% @doc Hello world handler.
-module(user_handler).

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
	{[  
		{<<"application/x-www-form-urlencoded">>, handle_request},
		{<<"application/json">>, handle_request}
		], Req, State}.

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
	% Body = <<"{\"rest\": \"Hello GET World!\"}">>,
    Result = emysql:execute(hello_pool, <<"select ID, USERNAME from lycusers">>),
    JSON = emysql:as_json(Result),
    Body = jsx:encode(JSON),
    % io:format(extended_start_script),
	process_response("NORMAL", Body, Req, State, 200);

process_request(<<"POST">>, Req, State) ->
	% io:format("post process_request \n\n\n"),
    % Body = <<"{\"rest\": \"Hello POST World!\"}">>,
    {{Year,Month,Day},{Hour,Min,Sec}} = {date(),time()},

    {ok, PostVals, Req2} = cowboy_req:body_qs(Req),
    % TODO: Perform form validations
	UserName = binary_to_list(proplists:get_value(<<"userName">>, PostVals)),
	Pass = binary_to_list(proplists:get_value(<<"pass">>, PostVals)),
	Namespace = binary_to_list(proplists:get_value(<<"namespace">>, PostVals)),
	LoginAlias = binary_to_list(proplists:get_value(<<"loginAlias">>, PostVals)),
	FirstName = binary_to_list(proplists:get_value(<<"firstName">>, PostVals)),
	LastName = binary_to_list(proplists:get_value(<<"lastName">>, PostVals)),
	Address = binary_to_list(proplists:get_value(<<"address">>, PostVals)),
	City = binary_to_list(proplists:get_value(<<"city">>, PostVals)),
	Zip = binary_to_list(proplists:get_value(<<"zip">>, PostVals)),
	CountryState = binary_to_list(proplists:get_value(<<"state">>, PostVals)),
	Country = binary_to_list(proplists:get_value(<<"country">>, PostVals)),
	Email = binary_to_list(proplists:get_value(<<"email">>, PostVals)),
	ISD = binary_to_list(proplists:get_value(<<"ISD">>, PostVals)),
	Phone = binary_to_list(proplists:get_value(<<"phone">>, PostVals)),
	Telegram = binary_to_list(proplists:get_value(<<"telegram">>, PostVals)),
	Gender = binary_to_list(proplists:get_value(<<"gender">>, PostVals)),
	Birthday = binary_to_list(proplists:get_value(<<"birthday">>, PostVals)),
	CreationTime = integer_to_list(Year)++"-"++integer_to_list(Month)++"-"++integer_to_list(Day)++" "++
				integer_to_list(Hour)++":"++integer_to_list(Min)++":"++integer_to_list(Sec),
	LastLogin = 
				% integer_to_list(Year)++"-"++integer_to_list(Month)++"-"++integer_to_list(Day)++" "++
				% integer_to_list(Hour)++":"++integer_to_list(Min)++":"++integer_to_list(Sec),
	RefIp = binary_to_list(proplists:get_value(<<"RefIp">>, PostVals)),
	Enabled = binary_to_list(proplists:get_value(<<"Enabled">>, PostVals)),

	Result1 = emysql:execute(hello_pool, "INSERT INTO lycusers SET 
				USERNAME = '"++ UserName ++"', 
				PASS = '"++Pass++"', 
				NAMESPACE = '"++Namespace++"',
				LOGINALIAS = '"++LoginAlias++"',
				FIRSTNAME = '"++FirstName++"',
				LASTNAME = '"++LastName++"',
				ADDRESS = '"++Address++"',
				CITY = '"++City++"',
				ZIP = '"++Zip++"',
				STATE = '"++CountryState++"',
				COUNTRY = '"++Country++"',
				EMAIL = '"++Email++"',
				ISD = '"++ISD++"',
				PHONE = '"++Phone++"',
				TELEGRAM = '"++Telegram++"',
				GENDER = '"++Gender++"',
				BIRTHDAY = '"++Birthday++"',
				CREATIONTIME = '"++CreationTime++"',
				LASTLOGIN = '"++LastLogin++"',
				REFIP = '"++RefIp++"',
				ENABLED = '"++Enabled++"'
				"),
	Id = integer_to_list(emysql:insert_id(Result1)),
	% TODO: check is row inserted successfully
    Result2 = emysql:execute(hello_pool, "SELECT TELEGRAM, USERNAME FROM lycusers WHERE ID = '"++Id++"'"),
    % TODO: check if row exist
    JSON = emysql:as_json(Result2),
    Body = jsx:encode(JSON),
	process_response("PRESET", Body, Req2, State, 200);

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
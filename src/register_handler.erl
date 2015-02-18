-module(register_handler).

-export(
  [ init/3, 
    content_types_accepted/2,
    content_types_provided/2,
    terminate/3,
    allowed_methods/2,
    handle_request/2,
    process_response/5,
    process_request/3
  ]).

init(_Transport, _Req, []) -> {upgrade, protocol, cowboy_rest}.

terminate(_Reason, _Req, _State) -> ok.

allowed_methods(Req, State) ->
	{[<<"POST">>], Req, State}.

content_types_provided(Req, State) -> 
    {[{<<"application/json">>, handle_request}], Req, State}.

content_types_accepted(Req, State) ->
	{[  
		{<<"application/x-www-form-urlencoded">>, handle_request},
		{<<"application/json">>, handle_request}
		], Req, State}.

handle_request(Req, State) ->
    {Method, Req2} = cowboy_req:method(Req),
	process_request(Method, Req2, State).

process_request(<<"POST">>, Req, State) ->
    {{Year,Month,Day},{Hour,Min,Sec}} = {date(),time()},
	{ok, PostVals, Req2} = cowboy_req:body_qs(Req),
    % TODO: Perform form validations
	UserName 	 = binary_to_list(proplists:get_value(<<"userName">>, PostVals)),
	Pass 		 = binary_to_list(proplists:get_value(<<"pass">>, PostVals)),
	Namespace    = binary_to_list(proplists:get_value(<<"namespace">>, PostVals)),
	LoginAlias   = binary_to_list(proplists:get_value(<<"loginAlias">>, PostVals)),
	FirstName 	 = binary_to_list(proplists:get_value(<<"firstName">>, PostVals)),
	LastName 	 = binary_to_list(proplists:get_value(<<"lastName">>, PostVals)),
	Address 	 = binary_to_list(proplists:get_value(<<"address">>, PostVals)),
	City 		 = binary_to_list(proplists:get_value(<<"city">>, PostVals)),
	Zip          = binary_to_list(proplists:get_value(<<"zip">>, PostVals)),
	CountryState = binary_to_list(proplists:get_value(<<"state">>, PostVals)),
	Country 	 = binary_to_list(proplists:get_value(<<"country">>, PostVals)),
	Email 		 = binary_to_list(proplists:get_value(<<"email">>, PostVals)),
	ISD 		 = binary_to_list(proplists:get_value(<<"ISD">>, PostVals)),
	Phone        = binary_to_list(proplists:get_value(<<"phone">>, PostVals)),
	Telegram  	 = binary_to_list(proplists:get_value(<<"telegram">>, PostVals)),
	Gender 		 = binary_to_list(proplists:get_value(<<"gender">>, PostVals)),
	Birthday     = binary_to_list(proplists:get_value(<<"birthday">>, PostVals)),
	CreationTime = integer_to_list(Year)++"-"++integer_to_list(Month)++"-"++integer_to_list(Day)++" "++
					integer_to_list(Hour)++":"++integer_to_list(Min)++":"++integer_to_list(Sec),
	LastLogin 	 = integer_to_list(Year)++"-"++integer_to_list(Month)++"-"++integer_to_list(Day)++" "++
					integer_to_list(Hour)++":"++integer_to_list(Min)++":"++integer_to_list(Sec),
	RefIp 	 	 = binary_to_list(proplists:get_value(<<"RefIp">>, PostVals)),
	Enabled      = binary_to_list(proplists:get_value(<<"Enabled">>, PostVals)),

	Result = emysql:execute(hello_pool, "INSERT INTO lycusers SET 
				USERNAME 	 = '"++ UserName ++"', 
				PASS 		 = '"++Pass++"', 
				NAMESPACE 	 = '"++Namespace++"',
				LOGINALIAS 	 = '"++LoginAlias++"',
				FIRSTNAME 	 = '"++FirstName++"',
				LASTNAME 	 = '"++LastName++"',
				ADDRESS 	 = '"++Address++"',
				CITY 		 = '"++City++"',
				ZIP 		 = '"++Zip++"',
				STATE 		 = '"++CountryState++"',
				COUNTRY 	 = '"++Country++"',
				EMAIL 	     = '"++Email++"',
				ISD 	  	 = '"++ISD++"',
				PHONE 		 = '"++Phone++"',
				TELEGRAM 	 = '"++Telegram++"',
				GENDER  	 = '"++Gender++"',
				BIRTHDAY 	 = '"++Birthday++"',
				CREATIONTIME = '"++CreationTime++"',
				LASTLOGIN 	 = '"++LastLogin++"',
				REFIP        = '"++RefIp++"',
				ENABLED 	 = '"++Enabled++"'
				"), 

    AffectedRows = emysql:affected_rows(Result),
	Condition = case AffectedRows>0 of
    	true -> <<"{\"Registration successful\"}">>;
		false -> <<"{\"Registration unsuccessful\"}">>
		
    end,
	Body = "{\"status\": 0,
    		 \"message\":'"++binary_to_list(Condition)++"',
    		 \"telegram\": true,
    		 \"userData\": null,
    		 \"groupContacts\": null,
    		 \"userGroups\": null
    		}",
	process_response("PRESET", Body, Req2, State, 200).

process_response("PRESET", Body, Req, State, StatusCode)->
	Req2 = cowboy_req:set_resp_header(<<"StatusCode">>, StatusCode, Req),
	Req3 = cowboy_req:set_resp_body(Body, Req2),
    {true, Req3, State};
    
process_response("NORMAL", Body, Req, State, StatusCode)->
	Req2 = cowboy_req:set_resp_header(<<"StatusCode">>, StatusCode, Req),
	{Body, Req2, State}.
-module(login_handler).

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
	{[<<"POST">>], Req, State}.

content_types_accepted(Req, State) ->
	{[  
		{<<"application/x-www-form-urlencoded">>, handle_request},
		{<<"application/json">>, handle_request}
		], Req, State}.

handle_request(Req, State) ->
    {Method, Req2} = cowboy_req:method(Req),
	process_request(Method, Req2, State).

process_request(<<"POST">>, Req, State) ->
    {ok, PostVals, Req2} = cowboy_req:body_qs(Req),
    % TODO: Perform form validations
	UserName  = binary_to_list(proplists:get_value(<<"userName">>, PostVals)),
	Pass 	  = binary_to_list(proplists:get_value(<<"pass">>, PostVals)),
	Namespace = binary_to_list(proplists:get_value(<<"namespace">>, PostVals)),

	Result = emysql:execute(hello_pool, "SELECT USERNAME, NAMESPACE, LOGINALIAS, FIRSTNAME, LASTNAME, ADDRESS, CITY, ZIP, STATE, COUNTRY, EMAIL, PHONE, ISD, TELEGRAM, GENDER, BIRTHDAY FROM lycusers WHERE 
				USERNAME  = '"++ UserName ++"' AND
				PASS 	  = '"++Pass++"' AND
				NAMESPACE = '"++Namespace++"'		
				"),

    % TODO: check if row exist
    JSON = emysql:as_json(Result),
    Add = jsx:encode(JSON),
    Body = "{\"status\": 0,
    		 \"message\": null,
    		 \"telegram\": true,
    		 \"userData\": '"++binary_to_list(Add)++"',
    		 \"groupContacts\": null,
    		 \"userGroups\": null
    		}",
	process_response("PRESET", Body, Req2, State, 200).

process_response("PRESET", Body, Req, State, StatusCode)->
	Req2 = cowboy_req:set_resp_header(<<"StatusCode">>, StatusCode, Req),
	Req3 = cowboy_req:set_resp_body(Body, Req2),
    {true, Req3, State}.
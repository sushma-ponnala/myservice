-module(add_contact_handler).

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
    {ok, PostVals, Req2} = cowboy_req:body_qs(Req),
    % TODO: Perform form validations
	UserName    = binary_to_list(proplists:get_value(<<"userName">>, PostVals)),
    ContactName = binary_to_list(proplists:get_value(<<"contactName">>, PostVals)),
    
    User_id    = emysql:execute(hello_pool, "SELECT ID FROM lycusers WHERE USERNAME = '"++UserName++"' "), 
    [[{<<"ID">>,User_Id}]] = emysql:as_proplist(User_id),

    Contact_id = emysql:execute(hello_pool, "SELECT ID FROM lycusers WHERE USERNAME = '"++ContactName++"' "),
    [[{<<"ID">>,Contact_Id}]] = emysql:as_proplist(Contact_id),

    {result_packet,_,_,IdContent,_} =  emysql:execute(hello_pool, "SELECT ID FROM usercontacts WHERE USER_ID = '"++integer_to_list(User_Id)++"' AND CONTACT_ID = '"++integer_to_list(Contact_Id)++"' "),
  
    Check1 = case IdContent of
        [[Userid]] ->
            "{\"contact already exist '"++integer_to_list(Userid)++"'\"}";
        [] ->
            Result = emysql:execute(hello_pool, "INSERT INTO usercontacts (USER_ID, CONTACT_ID) values ('"++integer_to_list(User_Id)++"','"++integer_to_list(Contact_Id)++"')"),
            Id = emysql:insert_id(Result),
                case Id>0 of
                    true ->
                        <<"{\"message\": \"contacts added\"}">>;
                    false ->
                        <<"{\"message\": \"something wrong\"}">>
                end
        
    end,

	process_response("PRESET", Check1, Req2, State, 200).

process_response("PRESET", Body, Req, State, StatusCode)->
	Req2 = cowboy_req:set_resp_header(<<"StatusCode">>, StatusCode, Req),
	Req3 = cowboy_req:set_resp_body(Body, Req2),
    {true, Req3, State}.
    
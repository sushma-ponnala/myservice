-module(get_message_history_handler).

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
    % {{Year,Month,Day},{Hour,Min,Sec}} = {date(),time()},
	{ok, PostVals, Req2} = cowboy_req:body_qs(Req),
    % TODO: Getting form values
	Sender = binary_to_list(proplists:get_value(<<"sender">>, PostVals)),	
	
	% Getting Sender ID
	Sender_id = emysql:execute(hello_pool, "SELECT ID FROM lycusers WHERE USERNAME = '"++Sender++"' "), 
    [[{<<"ID">>,SenderID}]] = emysql:as_proplist(Sender_id),
    % io:format("SELECT ID FROM lycusers WHERE USERNAME = '"++Sender++"' "), 

    % Result = emysql:execute(hello_pool, "SELECT lu.*,lm.* FROM `lycusers` lu,`lycmessages` lm WHERE lu.`ID` = lm.`SENDER_ID` "),
    {result_packet,_,_,IdContent,_} = emysql:execute(hello_pool, "SELECT * FROM lycmessages WHERE SENDER_ID = '"++integer_to_list(SenderID)++"'"),

    % io:format("SELECT ID FROM lycmessages WHERE SENDER_ID = '"++integer_to_list(SenderID)++"'"), 
    io:format("message history count-->:~p~n",[IdContent]), 
    
	Body = case [IdContent] of
        [_] ->
            "{\"data exist\"}";
        [] ->            
            "{\"data does not exist\"}"
        
    end,
process_response("PRESET", Body, Req2, State, 200).

process_response("PRESET", Body, Req, State, StatusCode)->
	Req2 = cowboy_req:set_resp_header(<<"StatusCode">>, StatusCode, Req),
	Req3 = cowboy_req:set_resp_body(Body, Req2),
    {true, Req3, State};
    
process_response("NORMAL", Body, Req, State, StatusCode)->
	Req2 = cowboy_req:set_resp_header(<<"StatusCode">>, StatusCode, Req),
	{Body, Req2, State}.
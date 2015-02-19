-module(update_message_status_handler).

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
    % TODO: Getting form values
	AppMsgId   = binary_to_list(proplists:get_value(<<"appMsgId">>, PostVals)),
	MsgStatus  = binary_to_list(proplists:get_value(<<"msgStatus">>, PostVals)), 

    Result = emysql:execute(hello_pool, "UPDATE lycmessages SET MSG_STATUS = '"++MsgStatus++"' WHERE APP_MSG_ID='"++AppMsgId++"'"),	 

    AffectedRows = emysql:affected_rows(Result),    
	MMessage = case AffectedRows>0 of
    	true ->    	
    	 <<"{\"Message status updated.\"}">>;
		false -> 
    	 <<"{\"Message status not updated.\"}">>
		
    end,
    MStatus = case AffectedRows>0 of
    	true ->0;
		false ->1		
    end,
	Body = "{\"status\": '"++integer_to_list(MStatus)++"',
    		 \"message\":'"++binary_to_list(MMessage)++"',		 
    		}",
process_response("PRESET", Body, Req2, State, 200).

process_response("PRESET", Body, Req, State, StatusCode)->
	Req2 = cowboy_req:set_resp_header(<<"StatusCode">>, StatusCode, Req),
	Req3 = cowboy_req:set_resp_body(Body, Req2),
    {true, Req3, State};
    
process_response("NORMAL", Body, Req, State, StatusCode)->
	Req2 = cowboy_req:set_resp_header(<<"StatusCode">>, StatusCode, Req),
	{Body, Req2, State}.
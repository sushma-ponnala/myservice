-module(send_message_handler).

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
	Sender 	 			 = binary_to_list(proplists:get_value(<<"sender">>, PostVals)),
	Receiver 		 	 = binary_to_list(proplists:get_value(<<"receiver">>, PostVals)),
	MsgType    			 = binary_to_list(proplists:get_value(<<"msgType">>, PostVals)),
	Msg   				 = binary_to_list(proplists:get_value(<<"msg">>, PostVals)),
	LocalPathSender 	 = binary_to_list(proplists:get_value(<<"localPathSender">>, PostVals)),
	LocalPathReceiver 	 = binary_to_list(proplists:get_value(<<"localPathReceiver">>, PostVals)),
	MsgDate 	 		 = binary_to_list(proplists:get_value(<<"msgDate">>, PostVals)),
	MsgTime 		 	 = binary_to_list(proplists:get_value(<<"msgTime">>, PostVals)),
	MsgTz          	 	 = binary_to_list(proplists:get_value(<<"msgTz">>, PostVals)),
	MsgStatus 			 = binary_to_list(proplists:get_value(<<"msgStatus">>, PostVals)),
	
	% Getting Sender ID
	Sender_id = emysql:execute(hello_pool, "SELECT ID FROM lycusers WHERE USERNAME = '"++Sender++"' "), 
    [[{<<"ID">>,SenderID}]] = emysql:as_proplist(Sender_id),
    % io:format("sender_Id-->:~p ~n", [SenderID]),    
    
    % Getting Receiver ID
	Receiver_id = emysql:execute(hello_pool, "SELECT ID FROM lycusers WHERE USERNAME = '"++Receiver++"' "), 
    [[{<<"ID">>,ReceiverID}]] = emysql:as_proplist(Receiver_id),
    % io:format("receiver_Id-->:~p ~n", [ReceiverID]),

 %    SAffectedRows = emysql:affected_rows(Sender_id),
 %    RAffectedRows = emysql:affected_rows(Receiver_id),
    
	% Condition = case SAffectedRows and RAffectedRows > 0 of
 %    	true -> <<"{\"Send message successful\"}">>;
	% 	false -> <<"{\"Send message unsuccessful\"}">>
		
 %    end,

    Result = emysql:execute(hello_pool, "INSERT INTO lycmessages SET 
		SENDER_ID 			 = '"++integer_to_list(SenderID)++"',
		RECEIVER_ID 		 = '"++integer_to_list(ReceiverID)++"',
		MSG_TYPE 			 = '"++MsgType++"',
		MSG 				 = '"++Msg++"',
		LOCAL_PATH_SENDER    = '"++LocalPathSender++"',
		LOCAL_PATH_RECEIVER  = '"++LocalPathReceiver++"',
		MSG_DATE 			 = '"++MsgDate++"',
		MSG_TIME 			 = '"++MsgTime++"',
		MSG_TZ 				 = '"++MsgTz++"',
		MSG_STATUS 			 = '"++MsgStatus++"'"
		),	 

    AffectedRows = emysql:affected_rows(Result),
    % Condition = if
    %     AffectedRows>0 ->
    %         <<"{\"Registration successful\"}">>;
    %     true -> % works as an 'else' branch
    %         <<"{\"Registration unsuccessful\"}">>
    % end,
	Condition = case AffectedRows>0 of
    	true ->    	
    	 <<"{\"Message send successful\"}">>;
		false -> 
    	 <<"{\"Message send unsuccessful\"}">>
		
    end,
	Body = "{\"status\": 0,
    		 \"message\":'"++binary_to_list(Condition)++"',		 
    		}",
process_response("PRESET", Body, Req2, State, 200).

process_response("PRESET", Body, Req, State, StatusCode)->
	Req2 = cowboy_req:set_resp_header(<<"StatusCode">>, StatusCode, Req),
	Req3 = cowboy_req:set_resp_body(Body, Req2),
    {true, Req3, State};
    
process_response("NORMAL", Body, Req, State, StatusCode)->
	Req2 = cowboy_req:set_resp_header(<<"StatusCode">>, StatusCode, Req),
	{Body, Req2, State}.
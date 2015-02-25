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
	{ok, PostVals, Req2} = cowboy_req:body_qs(Req),
	Sender = binary_to_list(proplists:get_value(<<"sender">>, PostVals)),	
	% Getting Sender ID
	Sender_id = emysql:execute(hello_pool, "SELECT ID FROM lycusers WHERE USERNAME = '"++Sender++"' "), 
    [[{<<"ID">>,Sender_Id}]] = emysql:as_proplist(Sender_id),
    % io:format("~p ~n",[Sender_Id]), 
    Check  = emysql:execute(hello_pool, "select rec.receiver_id, lu.username as sender, rec.username as receiver, rec.sender_id, rec.msgType,rec.localPathSender,rec.localPathReceiver,rec.remotePath,rec.mapLat,rec.mapLong,rec.msgDate,rec.msgTime,rec.msgTz,rec.msgStatus,lu.username from (select lycmessages.id, receiver_id, lycusers.username, sender_id,lycmessages.msg_type as msgType,lycmessages.local_path_sender as localPathSender,lycmessages.local_path_receiver as localPathReceiver,lycmessages.remote_path as remotePath,lycmessages.map_lat as mapLat,lycmessages.map_long as mapLong,lycmessages.msg_date as msgDate,lycmessages.msg_time as msgTime,lycmessages.msg_tz as msgTz,lycmessages.msg_status as msgStatus from lycmessages JOIN lycusers ON lycusers.id = lycmessages.receiver_id where lycmessages.sender_id = '"++integer_to_list(Sender_Id)++"') as rec JOIN lycusers lu where rec.sender_id = lu.id"),

    % Check  = emysql:execute(hello_pool, "SELECT APP_MSG_ID, SESSID, RECEIVER_ID, MSG_TYPE, MSG, LOCAL_PATH_SENDER, LOCAL_PATH_RECEIVER, REMOTE_PATH, MAP_LAT, MAP_LONG, MSG_DATE, MSG_TIME, MSG_TZ, MSG_STATUS  FROM lycmessages WHERE SENDER_ID = '"++integer_to_list(Sender_Id)++"'"),
    Check_Json = emysql:as_json(Check),
    io:format("Check_Json :~p ~n",[Check_Json]),
    Add  = jsx:encode([Check_Json]),
    io:format("Add :~p ~n",[Add]),
    Body = "{\"status\": 0,
             \"message\": '"++ binary_to_list(Add) ++"',
             \"telegram\": true,
             \"userData\": null,
             \"groupContacts\": null,
             \"userGroups\": null
            }",
     io:format("body :~p ~n",[Body]),       
process_response("PRESET", Body, Req2, State, 200).

process_response("PRESET", Body, Req, State, StatusCode)->
	Req2 = cowboy_req:set_resp_header(<<"StatusCode">>, StatusCode, Req),
	Req3 = cowboy_req:set_resp_body(Body, Req2),
    {true, Req3, State};
    
process_response("NORMAL", Body, Req, State, StatusCode)->
	Req2 = cowboy_req:set_resp_header(<<"StatusCode">>, StatusCode, Req),
	{Body, Req2, State}.
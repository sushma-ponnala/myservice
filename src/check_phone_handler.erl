-module(check_phone_handler).

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
    UserName = binary_to_list(proplists:get_value(<<"userName">>, PostVals)),
    Phone    = binary_to_list(proplists:get_value(<<"phone">>, PostVals)),
    {result_packet,_,_,ID,_} = emysql:execute(hello_pool, "SELECT ID FROM lycusers WHERE USERNAME = '"++UserName++"' "), 
    Body = case ID of
        [] ->
            <<"{\"status\": 1,
             \"message\": \"Username doesn't exist\"}">>;
        [_] ->
            {result_packet,_,_,[[Count]],_} = emysql:execute(hello_pool, "SELECT count(*) FROM lycusers WHERE PHONE = '"++Phone++"' "),
            case Count of
                0 -> <<"{\"status\": 0,
                     \"message\": \"Mobile number is unique\"}">>;
                1-> <<"{\"status\": 1,
                    \"message\": \"Mobile number is already exist\"}">>
            end
    end,
    process_response("PRESET", Body, Req2, State, 200).

process_response("PRESET", Body, Req, State, StatusCode)->
    Req2 = cowboy_req:set_resp_header(<<"StatusCode">>, StatusCode, Req),
    Req3 = cowboy_req:set_resp_body(Body, Req2),
    {true, Req3, State}.
-module(login_handler).

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
    
    UserName  = binary_to_list(proplists:get_value(<<"userName">>, PostVals)),
    Pass      = binary_to_list(proplists:get_value(<<"pass">>, PostVals)),
    Namespace = binary_to_list(proplists:get_value(<<"namespace">>, PostVals)),

    User_id    = emysql:execute(hello_pool, "SELECT ID FROM lycusers WHERE USERNAME = '"++UserName++"' AND PASS = '"++Pass++"' AND NAMESPACE = '"++Namespace++"' "), 
    [[{<<"ID">>,User_Id}]] = emysql:as_proplist(User_id),
    % io:format("userid: ~p ~n", [User_Id]),

    % // fetching message //
    Contacts = emysql:execute(hello_pool, "SELECT lycusers.ID, lycusers.USERNAME, lycusers.FIRSTNAME, lycusers.LASTNAME, usercontacts.SELF_STATUS, usercontacts.CONTACT_STATUS FROM usercontacts INNER JOIN lycusers ON usercontacts.CONTACT_ID = lycusers.ID WHERE usercontacts.USER_ID= '"++ integer_to_list(User_Id) ++"' "),
    Contacts_Json = emysql:as_json(Contacts),
    Contacts_Jsx  = jsx:encode(Contacts_Json),

    % // userdata //
    UserData = emysql:execute(hello_pool, "SELECT USERNAME, NAMESPACE, LOGINALIAS, FIRSTNAME, LASTNAME, ADDRESS, CITY, ZIP, STATE, COUNTRY, EMAIL, PHONE, ISD, TELEGRAM, GENDER, BIRTHDAY FROM lycusers WHERE 
                USERNAME  = '"++ UserName ++"' AND
                PASS      = '"++Pass++"' AND
                NAMESPACE = '"++Namespace++"'       
                "),
    UserData_Json = emysql:as_json(UserData),
    UserData_Jsx  = jsx:encode(UserData_Json),

    %  // userGroups //
    UserGroups = emysql:execute(hello_pool, "SELECT GROUPNAME FROM lycbuddygroups WHERE ID IN (SELECT DISTINCT GROUP_ID FROM lycusers_buddygroups WHERE USER_NAME = '"++UserName++"') "),
    UserGroups_Json = emysql:as_json(UserGroups),
    UserGroups_Jsx  = jsx:encode(UserGroups_Json),

    % // groupcontacts //

    GroupContacts = emysql:execute(hello_pool,"SELECT USER_NAME FROM lycusers_buddygroups WHERE GROUP_ID IN (SELECT DISTINCT GROUP_ID FROM lycusers_buddygroups WHERE USER_NAME = '"++UserName++"')"),
    GroupContacts_Json = emysql:as_json(GroupContacts),
    GroupContacts_Jsx  = jsx:encode(GroupContacts_Json),

    Body = "{\"status\": 0,
             \"message\": '"++ binary_to_list(Contacts_Jsx) ++"',
             \"telegram\": true,
             \"userData\": '"++ binary_to_list(UserData_Jsx) ++"',
             \"groupContacts\": '"++ binary_to_list(GroupContacts_Jsx) ++"',
             \"userGroups\": '"++ binary_to_list(UserGroups_Jsx) ++"'
            }",
    process_response("PRESET", Body, Req2, State, 200).

process_response("PRESET", Body, Req, State, StatusCode)->
    Req2 = cowboy_req:set_resp_header(<<"StatusCode">>, StatusCode, Req),
    Req3 = cowboy_req:set_resp_body(Body, Req2),
    {true, Req3, State}.
    
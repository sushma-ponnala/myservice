-module(file_upload_handler).

-export([init/2]).

init(Req, Opts) ->

    Path = "/home/webservices/rest_hello_world/uploads/",
    {ok, Headers, Req2} = cowboy_req:part(Req),
    {ok, Data, Req3} = cowboy_req:part_body(Req2),
    {file, _, Filename, _, _TE} = cow_multipart:form_data(Headers),

    Filename2 = binary_to_list(Filename),
    FilePath = lists:concat([Path, Filename2]),
    file:write_file(FilePath, Data),

    Req4 = cowboy_req:reply(200, [{<<"content-type">>, <<"text/plain">>}], "File saved to "++FilePath, Req3),
    {ok, Req4, Opts}.

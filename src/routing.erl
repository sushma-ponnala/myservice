-module(routing).

-export([routes/0]).

routes() ->
	[
		{'_', [
			{"/", toppage_handler, []},
			{"/register", register_handler, []},
			{"/login", login_handler, []},
			{"/check_phone", check_phone_handler, []},
			{"/update_phone", update_phone_handler, []},
			{"/file_upload", file_upload_handler, []},
			{"/get_message_history", get_message_history_handler, []},
			{"/add_contact", add_contact_handler, []},
			{"/update_contact", update_contact_handler, []},
			{"/search_contact", search_contact_handler, []},
			{"/send_message", send_message_handler, []},
			{"/update_message_status", update_message_status_handler, []}
			
		]}
	].
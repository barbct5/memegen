-module(memebot_auth_handler).

-export([init/3, handle/2, terminate/3]).

-record(state, { client_id :: string(), client_secret :: string() }).

init(_Type, Req, Opts) ->
    case lists:keyfind(client_secret, 1, Opts) of
	false ->
	    {stop, missing_client_secret};
	{client_secret, ClientSecret} ->
	    case lists:keyfind(client_id, 1, Opts) of
		false ->
		    {stop, missing_client_id};
		{client_id, ClientId} ->
		    {ok, Req, #state{client_id=ClientId,
				     client_secret=ClientSecret}}
	    end
    end.

handle(Req, State) ->
    handle_method(cowboy_req:method(Req), State).

handle_method({<<"GET">>, Req}, State) ->
    case cowboy_req:qs_val(<<"code">>, Req, undefined) of
	{undefined, Req2} ->
	    request_code(Req2, State);
	{Code, Req2} ->
	    retrieve_token(Code, Req2, State)
    end;
handle_method({_Method, Req}, State) ->
    Req2 = cowboy_req:reply(405, Req),
    {ok, Req2, State}.

retrieve_token(Code, Req, State) ->
    #state{client_id=ClientId, client_secret=ClientSecret} = State,
    Url = io_lib:format("https://slack.com/api/oauth.access?client_id=~s&client_secret=~s&code=~s&redirect_url=https://memebot.io/auth",
			[ClientId, ClientSecret, Code]),
    {ok, {Status, Headers, Body}} = httpc:request(Url),
    ok = error_logger:info_msg("Status: ~p~nHeaders: ~p~nBody: ~p~n", [Status, Headers, Body]),
    parse_access_token(jsx:decode(list_to_binary(Body), [return_maps]), Req, State).

parse_access_token(#{<<"ok">> := true, <<"access_token">> := AccessToken}, Req, State) ->
    {ok, UserId} = retrieve_user_id(AccessToken),
    ok = memebot_token_store:put(UserId, AccessToken),
    {ok, Req2} = cowboy_req:reply(200, Req),
    {ok, Req2, State};
parse_access_token(#{<<"ok">> := false, <<"error">> := Error}, Req, State) ->
    ok = error_logger:error_msg("Failed to retrieve access token: ~s~n", [Error]),
    Response = jsx:encode(#{<<"ok">> => false, <<"error">> => Error}),
    {ok, Req2} = cowboy_req:reply(400, [], Response, Req),
    {ok, Req2, State}.

request_code(Req, State) ->
    {AuthState, Req2} = cowboy_req:qs_val(<<"text">>, Req, <<"">>),
    AuthUrl = authentication_url(AuthState, State),
    ok = error_logger:info_msg("Request code: ~s~n", [AuthUrl]),
    {ok, Req2} = cowboy_req:reply(302, [{<<"location">>, AuthUrl}], Req),
    {ok, Req2, State}.

retrieve_user_id(Token) ->
    Url = io_lib:format("https://slack.com/api/auth.test?token=~s", [Token]),
    {ok, {_Status, _Headers, Body}} = httpc:request(Url),
    parse_user_id(jsx:decode(list_to_binary(Body), [return_maps])).

parse_user_id(#{<<"ok">> := true, <<"user_id">> := UserId}) ->
    {ok, UserId};
parse_user_id(#{<<"ok">> := false, <<"error">> := Error}) ->
    {error, Error}.

terminate(_Reason, _Req, _State) ->
    ok.

authentication_url(AuthState, State) ->
    ClientId = State#state.client_id,
    ["https://slack.com/oauth/authorize?client_id=", ClientId,
     "&redirect_url=https://memebot.io/auth&scope=client&state=", AuthState].
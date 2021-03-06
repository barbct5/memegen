-module(memebot).

-export([generate/1]).

generate(Opts) ->
    Prog = filename:join(code:priv_dir(memebot), "memebot"),
    Args = build_args(Opts, []),
    Port = open_port({spawn_executable, Prog},
		     [stream, use_stdio, exit_status,
		     {args, Args}]),
    wait_for_data(Port, []).

wait_for_data(Port, Acc) ->
    receive
	{Port, {data, Data}} ->
	    wait_for_data(Port, [Data|Acc]);
	{Port, {exit_status, _Status}}  ->
	    {ok, lists:reverse(Acc)};
	Other ->
	    {error, {badmatch, Other}}
    after
	500 ->
	    {error, timeout}
    end.

build_args([], Args) ->
    Args;
build_args([{top, Top} | Rest], Args) when is_list(Top) ->
    build_args(Rest, [<<"--top=", (list_to_binary(Top))/binary>>|Args]);
build_args([{bottom, Bottom} | Rest], Args) when is_list(Bottom) ->
    build_args(Rest, [<<"--bottom=", (list_to_binary(Bottom))/binary>>|Args]);
build_args([{source, Source} | Rest], Args) when is_list(Source) ->
    build_args(Rest, [<<"--source=", (list_to_binary(Source))/binary>>|Args]);
build_args([_ | Rest], Args) ->
    build_args(Rest, Args).

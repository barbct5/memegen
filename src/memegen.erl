-module(memegen).

-export([generate/1]).

generate(Opts) ->
    Prog = filename:join(code:priv_dir(memegen), "memegen"),
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

switch(Switch, Value) ->
    lists:flatten(io_lib:format("--~s=~s", [Switch, Value])).

build_args([], Args) ->
    Args;
build_args([{text, Text} | Rest], Args) ->
    build_args(Rest, [switch("text", Text) | Args]);
build_args([{source, Source} | Rest], Args) ->
    build_args(Rest, [switch("source", Source) | Args]);
build_args([_ | Rest], Args) ->
    build_args(Rest, Args).

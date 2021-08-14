%% Copyright (c) 2008-2021 Robert Virding
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%%
%%     http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.

%%% File    : lfe_init.erl
%%% Author  : Robert Virding
%%% Purpose : Lisp Flavoured Erlang init module.

%%% This little beauty allows you to start Erlang with the LFE shell
%%% running and still has ^G and user_drv enabled. Use it as follows:
%%%
%%% erl -user lfe_init
%%%
%%% Add -pa to find modules if necessary.
%%%
%%% Thanks to Attila Babo for showing me how to do this.

-module(lfe_init).

-export([start/0,eval_strings/0,eval_strings/1]).

-include("lfe.hrl").

-define(OK_STATUS, 0).
-define(ERROR_STATUS, 127).

%% Start LFE running a script or the shell depending on arguments.

start() ->
    Args = init:get_arguments(),
    erlang:display({args,Args}),
    Plain = init:get_plain_arguments(),
    erlang:display({plain,Plain}),
    Repl = init:get_argument(norepl),
    erlang:display({norepl,Repl}),
    Evals = collect_evals(),
    erlang:display({evals,Evals}),
    run_repl().

collect_evals() ->
    collect_evals(init:get_argument(lfe_eval)).

collect_evals({ok,Evals}) ->
    lists:flatmap(fun (E) -> E end, Evals);
collect_evals(error) -> [].

%% run_repl() -> no_return().
%%  Run the LFE repl the "smart" way if the tty works, otherwise
%%  start a dumb terminal version.

run_repl() ->
    Tty = check_tty(),
    Repl = check_repl(),
    erlang:display({check_tty_repl,Tty,Repl}),
    case Tty and Repl of
	true ->
	    user_drv:start(['tty_sl -c -e',{lfe_shell,start,[]}]);
	false ->
	    user:start(),
	    Repl andalso lfe_shell:start()
    end.

%% check_tty() -> boolean().
%%  Check whether we can open the tty and it works.

check_tty() ->
    try
	Port = open_port({spawn,'tty_sl -c -e'}, [eof]),
	port_close(Port)
    catch
	_Class:_Exception -> false
    end.

check_repl() ->
    init:get_argument(norepl) =:= error.

%% eval_strings() -> ok.
%% eval_strings(Strings) -> ok.
%%  Evaluate the strings in an -eval/-lfe_eval flag. We specially
%%  allow, and handle, no strings. Note that we do each use of -eval
%%  separately.

eval_strings() ->
    ok.

eval_strings(Strings) ->
    lfe_shell:run_strings(Strings),
    ok.

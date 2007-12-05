%% ``The contents of this file are subject to the Erlang Public License,
%% Version 1.1, (the "License"); you may not use this file except in
%% compliance with the License. You should have received a copy of the
%% Erlang Public License along with this software. If not, it can be
%% retrieved via the world wide web at http://www.erlang.org/.
%% 
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and limitations
%% under the License.
%% 
%% The Initial Developer of the Original Code is Ericsson Utvecklings AB.
%% Portions created by Ericsson are Copyright 1999, Ericsson Utvecklings
%% AB. All Rights Reserved.''
%% 
%%     $Id$
%% 

%% 
%% @doc Percept - Erlang Concurrency Profiling Tool
%%
%%	This module provides the user interface for the application.
%% @author Bj�rn-Egil Dahlberg 
%% 

-module(percept).
-behaviour(application).
-export([
	profile/1, 
	profile/2, 
	profile/3,
	stop_profile/0, 
	start_webserver/0, 
	start_webserver/1, 
	stop_webserver/0, 
	stop_webserver/1, 
	analyze/1,
	% Application behaviour
	start/2, 
	stop/1]).


-include("percept.hrl").

%%==========================================================================
%%
%% 		Type definitions 
%%
%%==========================================================================

%% @type percept_option() = procs | ports | exclusive

-type(percept_option() :: 'procs' | 'ports' | 'exclusive' | 'scheduler').

%%==========================================================================
%%
%% 		Application callback functions
%%
%%==========================================================================

%% @spec start(Type, Args) -> {started, Hostname, Port} | {error, Reason} 
%% @doc none
%% @hidden

start(_Type, _Args) ->
    %% start web browser service
    start_webserver(0).

%% @spec stop(State) -> ok 
%% @doc none
%% @hidden

stop(_State) ->
    %% stop web browser service
    stop_webserver(0).

%%==========================================================================
%%
%% 		Interface functions
%%
%%==========================================================================

%% @spec profile(Filename::string()) -> {ok, Port} | {already_started, Port}
%% @equiv profile(Filename, [procs])

-spec(profile/1 :: (Filename :: string()) -> 
	{'ok', port()} | {'already_started', port()}).

profile(Filename) ->
    profile_to_file(Filename, [procs]).

%% @spec profile(Filename::string(), Options::[profile_option()]) -> {ok, Port} | {already_started, Port}
%%	Port = port()
%% @doc Starts profiling with supplied options. 
%%	All events are stored in the file given by Filename. 
%%	An explicit call to stop_profile/0 is needed to stop profiling. 
%% @see stop_profile/0

-spec(profile/2 :: (
	Filename :: string(),
	Options :: [percept_option()]) ->
	{'ok', port()} | {'already_started', port()}).

profile(Filename, Opts) ->
    profile_to_file(Filename, Opts). 

%% @spec profile(string(), MFA::mfa(), [percept_option()]) -> ok | {already_started, Port} | {error, not_started}
%%	Port = port()
%% @doc Starts profiling at the entrypoint specified by the MFA. All events are collected, 
%%	this means that processes outside the scope of the entry-point are also profiled. 
%%	No explicit call to stop_profile/0 is needed, the profiling stops when
%%	the entry function returns.

-spec(profile/3 :: (
	Filename :: string(),
	Entry :: {atom(), atom(), list()},
	Options :: [percept_option()]) ->
	'ok' | {'already_started', port()} | {'error', 'not_started'}).

profile(Filename, {Module, Function, Args}, Opts) ->
    case whereis(percept_port) of
	undefined ->
	    profile_to_file(Filename, Opts),
	    erlang:apply(Module, Function, Args),
	    stop_profile();
	Port ->
	    {already_started, Port}
    end.

-spec(stop_profile/0 :: () -> 'ok' | {'error', 'not_started'}).

%% @spec stop_profile() -> ok | {'error', 'not_started'}
%% @doc Stops profiling.

stop_profile() ->
    erlang:system_profile(undefined, [runnable_ports, runnable_procs]),
    erlang:trace(all, false, [procs, ports, timestamp]),
    
    case whereis(percept_port) of
    	undefined -> 
	    {error, not_started};
	Port ->
	    erlang:port_command(Port, erlang:term_to_binary({profile_stop, erlang:now()})),
	    %% trace delivered?
	    erlang:port_close(Port),
	    ok
    end. 

%% @spec analyze(string()) -> ok | {error, Reason} 
%% @doc Analyse file.

-spec(analyze/1 :: (Filename :: string()) -> 
	'ok' | {'error', any()}).

analyze(Filename) ->
    case percept_db:start() of 
	{started, DB} ->
	    parse_and_insert(Filename,DB);
	{restarted, DB} ->
	    parse_and_insert(Filename,DB)
    end.

%% @spec start_webserver() -> {started, Hostname, Port} | {error, Reason}
%%	Hostname = string()
%%	Port = integer()
%%	Reason = term() 
%% @doc Starts webserver.

-spec(start_webserver/0 :: () -> 
	{'started', string(), pos_integer()} | 
	{'error', any()}).

start_webserver() ->
    start_webserver(0).

%% @spec start_webserver(integer()) -> {started, Hostname, AssignedPort} | {error, Reason}
%%	Hostname = string()
%%	AssignedPort = integer()
%%	Reason = term() 
%% @doc Starts webserver. If port number is 0, an available port number will 
%%	be assigned by inets.

-spec(start_webserver/1 :: (Port :: non_neg_integer()) -> 
	{'started', string(), pos_integer()} | 
	{'error', any()}).

start_webserver(Port) when is_integer(Port) ->
    application:load(percept),
    case whereis(percept_httpd) of
	undefined ->
	    {ok, Config} = get_webserver_config("percept", Port),
	    inets:start(),
	    case inets:start(httpd, Config) of
		{ok, Pid} ->
		    AssignedPort = find_service_port_from_pid(inets:services_info(), Pid),
		    {ok, Host} = inet:gethostname(),
		    %% workaround until inets can get me a service from a name.
		    Mem = spawn(fun() -> service_memory({Pid,AssignedPort,Host}) end),
		    register(percept_httpd, Mem),
		    {started, Host, AssignedPort};
		{error, Reason} ->
		    {error, {inets, Reason}}
	   end;
	_ ->
	    {error, already_started}
    end.

%% @spec stop_webserver() -> ok | {error, not_started}  
%% @doc Stops webserver.

stop_webserver() ->
    case whereis(percept_httpd) of
    	undefined -> 
	    {error, not_started};
	Pid ->
	    Pid ! {self(), get_port},
	    receive Port -> ok end,
	    Pid ! quit,
	    stop_webserver(Port)
    end.

%% @spec stop_webserver(integer()) -> ok | {error, not_started}
%% @doc Stops webserver of the given port.
%% @hidden

stop_webserver(Port) ->
    case find_service_pid_from_port(inets:services_info(), Port) of
	undefined ->
	    {error, not_started};
	Pid ->
	    inets:stop(httpd, Pid)
    end. 

%%==========================================================================
%%
%% 		Auxiliary functions 
%%
%%==========================================================================

profile_to_file(Filename, Opts) ->
    case whereis(percept_port) of 
	undefined ->
	    io:format("Starting profiling.~n", []),

	    erlang:system_flag(multi_scheduling, block),
	    Port = (dbg:trace_port(file, Filename))(),
	    % Send start time
	    erlang:port_command(Port, erlang:term_to_binary({profile_start, erlang:now()})),
	    erlang:system_flag(multi_scheduling, unblock),
		
	    %% Register Port
    	    erlang:register(percept_port, Port),
	    set_tracer(Port, Opts), 
	    {ok, Port};
	Port ->
	    io:format("Profiling already started at port ~p.~n", [Port]),
	    {already_started, Port}
    end.

%% set_tracer

set_tracer(Port, Opts) ->
    {TOpts, POpts} = parse_profile_options(Opts),
    % Setup profiling and tracing
    erlang:trace(all, true, [{tracer, Port}, timestamp | TOpts]),
    erlang:system_profile(Port, POpts).

%% parse_profile_options

parse_profile_options(Opts) ->
    parse_profile_options(Opts, {[],[]}).

parse_profile_options([], Out) ->
    Out;
parse_profile_options([Opt|Opts], {TOpts, POpts}) ->
    case Opt of
	procs ->
	    parse_profile_options(Opts, {
		[procs | TOpts], 
		[runnable_procs | POpts]
	    });
	ports ->
	    parse_profile_options(Opts, {
		[ports | TOpts], 
		[runnable_ports | POpts]
	    });
	scheduler ->
	    parse_profile_options(Opts, {
		[TOpts], 
		[scheduler | POpts]
	    });
	exclusive ->
	    parse_profile_options(Opts, {
		[TOpts], 
		[exclusive | POpts]
	    });
	_ -> 
	    parse_profile_options(Opts, {TOpts, POpts})

    end.

%% parse_and_insert

parse_and_insert(Filename, DB) ->
    io:format("Parsing: ~p ~n", [Filename]),
    T0 = erlang:now(),
    Pid = dbg:trace_client(file, Filename, mk_trace_parser(self())),
    Ref = erlang:monitor(process, Pid), 
    parse_and_insert_loop(Filename, Pid, Ref, DB, T0).

parse_and_insert_loop(Filename, Pid, Ref, DB, T0) ->
    receive
	{'DOWN',Ref,process, Pid, noproc} ->
	    io:format("Incorrect file or malformed trace file: ~p~n", [Filename]),
	    {error, file};
    	{parse_complete, {Pid, Count}} ->
	    receive {'DOWN', Ref, process, Pid, normal} -> ok after 0 -> ok end,
	    DB ! {action, consolidate},
	    T1 = erlang:now(),
	    io:format("Parsed ~p entries in ~p s.~n", [Count, ?seconds(T1, T0)]),
    	    io:format("    ~p created processes.~n", [length(percept_db:select({information, procs}))]),
     	    io:format("    ~p opened ports.~n", [length(percept_db:select({information, ports}))]),
	    ok;
	{'DOWN',Ref, process, Pid, normal} -> 
	    parse_and_insert_loop(Filename, Pid, Ref, DB, T0);
	{'DOWN',Ref, process, Pid, Reason} -> 
	    {error, Reason};
	Unhandled ->
    	    io:format("percept:analyze, receive unhandled ~p ~n", [Unhandled]),
	    {error, Unhandled}
    end.

mk_trace_parser(Pid) -> 
    {fun trace_parser/2, {0, Pid}}.

trace_parser(end_of_trace, {Count, Pid}) -> 
    Pid ! {parse_complete, {self(),Count}},
    receive
	{ack, Pid} -> 
	    ok
    end;
trace_parser(Trace, {Count, Pid}) ->
    percept_db:insert(Trace),
    {Count + 1,  Pid}.

find_service_pid_from_port([], _) ->
    undefined;
find_service_pid_from_port([{_, Pid, Options} | Services], Port) ->
    case lists:keysearch(port, 1, Options) of
	false ->
	    find_service_pid_from_port(Services, Port);
	{value, {port, Port}} ->
	    Pid
    end.

find_service_port_from_pid([], _) ->
    undefined;
find_service_port_from_pid([{_, Pid, Options} | _], Pid) ->
    case lists:keysearch(port, 1, Options) of
	false ->
	    undefined;
	{value, {port, Port}} ->
	   Port
    end;
find_service_port_from_pid([{_, _, _} | Services], Pid) ->
    find_service_port_from_pid(Services, Pid).
    
%% service memory

service_memory({Pid, Port, Host}) ->
    receive
	quit -> 
	    ok;
	{Reply, get_port} ->
	    Reply ! Port,
	    service_memory({Pid, Port, Host});
	{Reply, get_host} -> 
	    Reply ! Host,
	    service_memory({Pid, Port, Host});
	{Reply, get_pid} -> 
	    Reply ! Pid,
	    service_memory({Pid, Port, Host})
    end.

% Create config data for the webserver 

get_webserver_config(Servername, Port) when is_list(Servername), is_integer(Port) ->
    Path = code:priv_dir(percept),
    Root = filename:join([Path, "server_root"]),
    MimeTypesFile = filename:join([Root,"conf","mime.types"]),
    {ok, MimeTypes} = httpd_conf:load_mime_types(MimeTypesFile),
    Config = [
	% Roots
	{server_root, Root},
	{document_root,filename:join([Root, "htdocs"])},
	
	% Aliases
	{eval_script_alias,{"/eval",[io]}},
	{erl_script_alias,{"/cgi-bin",[percept_graph,percept_html,io]}},
	{script_alias,{"/cgi-bin/", filename:join([Root, "cgi-bin"])}},
	{alias,{"/javascript/",filename:join([Root, "scripts"]) ++ "/"}},
	{alias,{"/images/", filename:join([Root, "images"]) ++ "/"}},
	{alias,{"/css/", filename:join([Root, "css"]) ++ "/"}},
	
	% Logs
	%{transfer_log, filename:join([Path, "logs", "transfer.log"])},
	%{error_log, filename:join([Path, "logs", "error.log"])},
	
	% Configs
	{default_type,"text/plain"},
	{directory_index,["index.html"]},
	{mime_types, MimeTypes},
	{modules,[mod_alias,
	          mod_esi,
	          mod_actions,
	          mod_cgi,
	          mod_include,
	          mod_dir,
	          mod_get,
	          mod_head
	%          mod_log,
	%          mod_disk_log
	]},
	{com_type,ip_comm},
	{server_name, Servername},
	{bind_address, any},
	{port, Port}],
    {ok, Config}.
%% -*- erlang-indent-level: 2 -*-
%%--------------------------------------------------------------------
%% File        : hipe_icode_coordinator.erl
%% Author      : Per Gustafsson <pergu@it.uu.se>
%% Description : This module coordinates an Icode pass.
%% Created     : 20 Feb 2007 by Per Gustafsson <pergu@it.uu.se>
%%---------------------------------------------------------------------

-module(hipe_icode_coordinator).

-export([coordinate/4]).

-include("hipe_icode.hrl").
-include("../util/hipe_digraph.hrl").

%%---------------------------------------------------------------------

-define(MAX_CONCURRENT, erlang:system_info(schedulers)).

%%---------------------------------------------------------------------

-spec coordinate(#hipe_digraph{}, [{mfa(),bool()}], [mfa()], atom()) -> no_return().

coordinate(CG, Escaping, NonEscaping, Mod) ->
  ServerPid = initialize_server(Escaping, Mod),
  Clean = [MFA || {MFA, _} <- Escaping],
  All = NonEscaping ++ Clean,
  Restart = 
    fun(MFALists, PM) -> restart_funs(MFALists, PM, All, ServerPid) end,
  LastAction = 
    fun(PM) -> last_action(PM, ServerPid, Mod, All) end, 
  coordinate({Clean,All}, CG, gb_trees:empty(), Restart, LastAction, ServerPid).

coordinate(MFALists, CG, PM, Restart, LastAction, ServerPid) ->
  case MFALists of
    {[], []} -> 
      LastAction(PM),
      ServerPid ! stop,
      receive 
	{stop, Ans2Pid} ->
	  Ans2Pid ! {done, self()},
	  exit(normal)
      end;
    _ -> ok
  end,
  receive 
    {stop, AnsPid} ->
      ServerPid ! stop,
      AnsPid ! {done, self()},
      exit(normal);
    Message ->
      {NewPM, NewMFALists} = 
	case Message of
	  {restart_call, MFA} -> 
	    {PM,handle_restart_call(MFA, MFALists)};
	  {ready, {MFA, Pid}} ->
	    handle_ready(MFA, Pid, MFALists, PM);	
	  {restart_done, MFA} ->
	    {PM, handle_restart_done(MFA, MFALists, CG)};
	  {no_change_done, MFA} ->
	    {PM, handle_no_change_done(MFA, MFALists)}
	end,
      coordinate(Restart(NewMFALists, NewPM), CG, NewPM, Restart, 
		 LastAction, ServerPid)
  end.

handle_restart_call(MFA, {Queue, Busy}) ->
  case lists:member(MFA, Queue) of
    true ->
      {Queue, Busy};
    false ->
      {[MFA|Queue], Busy}
  end.

handle_ready(MFA, Pid, {Queue, Busy}, PM) ->
  {gb_trees:insert(MFA, Pid, PM), {Queue, Busy -- [MFA]}}.

handle_restart_done(MFA, {Queue, Busy}, CG) ->
  Restarts  = hipe_digraph:get_parents(MFA, CG),
  {ordsets:from_list(Restarts ++ Queue), Busy -- [MFA]}.

handle_no_change_done(MFA, {Queue, Busy}) ->
  {Queue, Busy -- [MFA]}.

last_action(PM, ServerPid, Mod, All) ->
  lists:foreach(fun(MFA) -> gb_trees:get(MFA, PM) ! {done, final_funs(ServerPid, Mod)},
			    receive 
			      {done_rewrite, MFA} -> ok
			    end
		end, All),
  ok.

restart_funs({Queue, Busy}, PM, All, ServerPid) ->
  case ?MAX_CONCURRENT - length(Busy) of
    X when is_integer(X), X > 0 ->
      Possible = [Pos || Pos <- Queue, (not lists:member(Pos, Busy))],
      Restarts = lists:sublist(Possible, X),
      lists:foreach(fun(MFA) ->
			restart_fun(MFA, PM, All, ServerPid)
		    end, Restarts),
      {Queue -- Restarts, Busy ++ Restarts};
    X when is_integer(X) ->
      {Queue, Busy}
  end.

initialize_server(Escaping, Mod) ->
  Pid = spawn_link(fun () -> info_server(Mod) end),
  lists:foreach(fun ({MFA, _}) -> 
		    Pid ! {set_escaping, MFA}
		end, Escaping),
  Pid.
 
safe_get_args(MFA, Cfg, Pid, Mod) ->
  Mod:replace_nones(get_args(MFA, Cfg, Pid)).

get_args(MFA, Cfg, Pid) ->
  Ref = make_ref(),
  Pid ! {get_call, MFA, Cfg, self(), Ref},
  receive
    {Ref, Types} ->
      Types
  end.

safe_get_res(MFA, Pid, Mod) ->
  Mod:replace_nones(get_res(MFA, Pid)).

get_res(MFA, Pid) ->
  Ref = make_ref(),
  Pid ! {get_return, MFA, self(), Ref},
  receive
    {Ref, Types} ->
      Types
  end.

update_return_type(MFA, NewType, Pid) ->
  Ref = make_ref(),
  Pid ! {update_return, MFA, NewType, self(), Ref}, 
  receive 
    {Ref, Ans} ->
      Ans
  end.

update_call_type(MFA, NewTypes, Pid) ->
  Ref = make_ref(),
  Pid ! {update_call, MFA, NewTypes, self(), Ref}, 
  receive
    {Ref, Ans} ->
      Ans
  end.

restart_fun(MFA, PM, All, ServerPid) ->
  gb_trees:get(MFA, PM) ! {analyse, analysis_funs(All, ServerPid)},
  ok.

analysis_funs(All, Pid) ->
  Self = self(),
  ArgsFun = fun (MFA, Cfg) -> get_args(MFA, Cfg, Pid) end,
  GetResFun = fun (MFA, Args) -> 
		  case lists:member(MFA, All) of
		    true ->
		      case update_call_type(MFA, Args, Pid) of
			do_restart -> 
			  Self ! {restart_call, MFA},
			  ok;
			no_change ->
			  ok
		      end;
		    false ->
		      ok
		  end,
		  [Ans] = get_res(MFA, Pid),
		  Ans
	      end,
  FinalFun = fun (MFA, RetTypes) ->
		 case update_return_type(MFA, RetTypes, Pid) of
		   do_restart -> 
		     Self ! {restart_done, MFA},
		     ok;
		   no_change ->
		     Self ! {no_change_done, MFA},
		     ok
		 end
	     end,
  {ArgsFun, GetResFun, FinalFun}. 

final_funs(Pid,Mod) ->
  ArgsFun = fun (MFA, Cfg) -> safe_get_args(MFA, Cfg, Pid, Mod) end,
  GetResFun = fun (MFA, _) ->   
		  [Ans] = safe_get_res(MFA, Pid, Mod),
		  Ans
	      end,
  FinalFun = fun(_,_) -> ok end,
  {ArgsFun, GetResFun, FinalFun}. 

info_server(Mod) ->
  info_server_loop(gb_trees:empty(), gb_trees:empty(), Mod).

info_server_loop(CallInfo, ReturnInfo, Mod) ->
  receive
    {update_return, MFA, NewInfo, Pid, Ref} ->
      NewReturnInfo = handle_update(MFA, ReturnInfo, NewInfo, Pid, Ref, Mod),
      info_server_loop(CallInfo, NewReturnInfo, Mod);
    {update_call, MFA, NewInfo, Pid, Ref} ->
      NewCallInfo = handle_update(MFA, CallInfo, NewInfo, Pid, Ref, Mod),
      info_server_loop(NewCallInfo, ReturnInfo, Mod);
    {get_return, MFA, Pid, Ref} ->
      Ans = 
	case gb_trees:lookup(MFA,ReturnInfo) of 
	  none ->
	    Mod:return_none();
	  {value, TypesComp} ->
	    Mod:return__info((TypesComp))
	end,
      Pid ! {Ref, Ans},
      info_server_loop(CallInfo, ReturnInfo, Mod);
    {get_call, MFA, Cfg, Pid, Ref} ->
      Ans = 
	case gb_trees:lookup(MFA, CallInfo) of 
	  none ->
	    Mod:return_none_args(Cfg, MFA);
	  {value, escaping} ->
	    Mod:return_any_args(Cfg, MFA);
	  {value, TypesComp} ->
	    Mod:return__info((TypesComp))
	end,
      Pid ! {Ref, Ans},
      info_server_loop(CallInfo, ReturnInfo, Mod);
    {set_escaping, MFA} ->
      info_server_loop(gb_trees:enter(MFA,escaping,CallInfo),ReturnInfo,Mod);
    stop ->
      ok
  end.

handle_update(MFA, Tree, NewInfo, Pid, Ref, Mod) ->
  case gb_trees:lookup(MFA,Tree) of
    none ->
      %% io:format("First Type: ~w ~w~n", [NewType, MFA]),
      Pid ! {Ref, do_restart},
      ResType = Mod:new__info(NewInfo);
    {value, escaping} ->
      Pid ! {Ref, no_change},
      ResType = escaping;
    {value, OldInfoComp} ->
      OldInfo = (OldInfoComp),
      %% io:format("New Type: ~w ~w~n", [NewType,MFA]),
      %% io:format("Old Type: ~w ~w~n", [OldType,MFA]),
      case Mod:update__info(NewInfo, OldInfo) of
	{true, ResType} ->
	  Pid ! {Ref, no_change};
	{false, ResType} ->
	  Pid ! {Ref, do_restart}
      end 
  end,
  %% ResType = binary_to_term(term_to_binary(ResType)),
  gb_trees:enter(MFA, ResType, Tree).

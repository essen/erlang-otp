%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Copyright (c) 2001 by Erik Johansson.  All Rights Reserved 
%% Time-stamp: <01/03/01 12:21:53 happi>
%% ====================================================================
%%  Filename : 	hipe_data_pp.erl
%%  Module   :	hipe_data_pp
%%  Purpose  :  
%%  Notes    : 
%%  History  :	* 2001-02-25 Erik Johansson (happi@csd.uu.se): 
%%               Created.
%%  CVS      :
%%              $Author: richardc $
%%              $Date: 2001/03/26 18:37:08 $
%%              $Revision: 1.1.1.1 $
%% ====================================================================
%%  Exports  :
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

-module(hipe_data_pp).
-export([pp/4]).

%% --------------------------------------------------------------------
%% Prety print

pp(Dev, Table, CodeType, Pre) ->
  Ls = hipe_consttab:labels(Table),
  lists:map(fun ({{_,ref},_}) -> ok;
		({L,E}) -> 
		pp_element(Dev, L, E, CodeType, Pre) end, 
	    lists:map(fun (L) -> {L,hipe_consttab:lookup(L, Table)} end, 
		      Ls)).

pp_element(Dev, Name, Element, CodeType, Prefix) ->
  
  %% Alignment
  case hipe_consttab:const_align(Element) of
    4 -> ok; %% Wordalignment is assumed
    Alignment -> 
      io:format(Dev, "    .align~w\n", [Alignment])
  end,

  %% Local or exported?
  Exported = hipe_consttab:const_exported(Element), 
  case CodeType of
    rtl ->
      if Exported==true ->
	  io:format(Dev, "DL~w: ", [Name]);
	 true ->
	  io:format(Dev, ".DL~w: ", [Name])
      end;
    sparc ->
      if Exported==true ->
	  io:format(Dev, "    .global ~s_dl_~w\n", [Prefix,Name]),
	  io:format(Dev, "~s_dl_~w: ", [Prefix, Name]);
	 true ->
	  io:format(Dev, ".~s_dl_~w: ", [Prefix, Name])
      end;
    _ -> 
      io:format(Dev, "~w ", [Name])
  end,

  %% Type and data...
  case hipe_consttab:const_type(Element) of
    term ->
      case CodeType of
	sparc ->
	  io:format(Dev, "0 ! .term ~w\n", [hipe_consttab:const_data(Element)]);
	_ ->
	  io:format(Dev, "~w\n", [hipe_consttab:const_data(Element)])
      end;
    sorted_block ->
      Data = hipe_consttab:const_data(Element),
      pp_block(Dev, {word, lists:sort(Data)}, CodeType,
	       Prefix);
    block ->
      pp_block(Dev, hipe_consttab:const_data(Element), CodeType,
	       Prefix)

  end.

pp_block(Dev, {word, Data, SortOrder}, CodeType, Prefix) ->
  case CodeType of 
    rtl ->
      io:format(Dev, "\n",[]);
    sparc ->
      io:format(Dev, ".word\n",[]);
    _ ->
      ok
  end,
  pp_wordlist(Dev, Data, CodeType, Prefix),
  case CodeType of 
    rtl ->
      io:format(Dev, ";; Sorted by ~w\n",[SortOrder]);
    sparc ->
      io:format(Dev, "!! Sorted by ~w\n",[SortOrder]);
    _ ->
      ok
  end;
pp_block(Dev, {word, Data}, CodeType, Prefix) ->
  case CodeType of 
    rtl ->
      io:format(Dev, ".word\n",[]);
    sparc ->
      io:format(Dev, ".word\n",[]);
    _ ->
      ok
  end,
  pp_wordlist(Dev, Data, CodeType, Prefix);
pp_block(Dev, {byte, Data}, CodeType, Prefix) ->
  case CodeType of 
    rtl ->
      io:format(Dev, ".byte\n   ",[]);
    sparc ->
      io:format(Dev, ".byte\n   ",[]);
    _ -> 
      ok
  end,
  pp_bytelist(Dev, Data, CodeType),
  case CodeType of 
    rtl ->
      io:format(Dev, "      ;; ~s\n   ",[Data]);
    _ -> ok
  end;
pp_block(Dev, {dword, Data}, CodeType, Prefix) ->
  case CodeType of 
    rtl ->
      io:format(Dev, ".dword\n",[]);
    sparc ->
      io:format(Dev, ".dword\n",[]);
    _ -> 
      ok
  end,
  pp_dwordlist(Dev, Data, CodeType).

  
pp_wordlist(Dev, [{label,L}|Rest], CodeType, Prefix) ->
  case CodeType of 
    rtl ->
      io:format(Dev, "      &L~w\n",[L]);
    sparc ->
      io:format(Dev, "      .~s_~w\n",[Prefix, L]);
    _ -> 
      io:format(Dev, "      <~w>\n",[L])
  end,
  pp_wordlist(Dev, Rest, CodeType, Prefix);
pp_wordlist(Dev, [D|Rest], CodeType, Prefix) ->
  case CodeType of 
    rtl ->
      io:format(Dev, "      ~w\n",[D]);
    _ -> 
      io:format(Dev, "      ~w\n",[D])
  end,
  pp_wordlist(Dev, Rest, CodeType, Prefix);
pp_wordlist(Dev, [], CodeType, Prefix) ->
  ok.

pp_bytelist(Dev, [D], CodeType) ->
  case CodeType of 
    rtl ->
      io:format(Dev, "~w\n",[D]);
    _ -> 
      io:format(Dev, "~w\n",[D])
  end,
  ok;
pp_bytelist(Dev, [D|Rest], CodeType) ->
  case CodeType of 
    rtl ->
      io:format(Dev, "~w,",[D]);
    _ -> 
      io:format(Dev, "~w,",[D])
  end,
  pp_bytelist(Dev, Rest, CodeType);
pp_bytelist(Dev, [], CodeType) ->
  io:format(Dev, "\n",[]).

pp_dwordlist(Dev, [D|Rest], CodeType) ->
  case CodeType of 
    rtl ->
      io:format(Dev, "      ~w\n",[D]);
    _ -> 
      io:format(Dev, "      ~w\n",[D])
  end,
  pp_dwordlist(Dev, Rest, CodeType);
pp_dwordlist(Dev, [], CodeType) ->
  ok.
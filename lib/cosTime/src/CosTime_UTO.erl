%%------------------------------------------------------------
%%
%% Implementation stub file
%% 
%% Target: CosTime_UTO
%% Source: /ldisk/daily_build/otp_prebuild_r12b.2008-11-05_12/otp_src_R12B-5/lib/cosTime/src/CosTime.idl
%% IC vsn: 4.2.19
%% 
%% This file is automatically generated. DO NOT EDIT IT.
%%
%%------------------------------------------------------------

-module('CosTime_UTO').
-ic_compiled("4_2_19").


%% Interface functions
-export(['_get_time'/1, '_get_time'/2, '_get_inaccuracy'/1]).
-export(['_get_inaccuracy'/2, '_get_tdf'/1, '_get_tdf'/2]).
-export(['_get_utc_time'/1, '_get_utc_time'/2, absolute_time/1]).
-export([absolute_time/2, compare_time/3, compare_time/4]).
-export([time_to_interval/2, time_to_interval/3, interval/1]).
-export([interval/2]).

%% Type identification function
-export([typeID/0]).

%% Used to start server
-export([oe_create/0, oe_create_link/0, oe_create/1]).
-export([oe_create_link/1, oe_create/2, oe_create_link/2]).

%% TypeCode Functions and inheritance
-export([oe_tc/1, oe_is_a/1, oe_get_interface/0]).

%% gen server export stuff
-behaviour(gen_server).
-export([init/1, terminate/2, handle_call/3]).
-export([handle_cast/2, handle_info/2, code_change/3]).

-include_lib("orber/include/corba.hrl").


%%------------------------------------------------------------
%%
%% Object interface functions.
%%
%%------------------------------------------------------------



%%%% Operation: '_get_time'
%% 
%%   Returns: RetVal
%%
'_get_time'(OE_THIS) ->
    corba:call(OE_THIS, '_get_time', [], ?MODULE).

'_get_time'(OE_THIS, OE_Options) ->
    corba:call(OE_THIS, '_get_time', [], ?MODULE, OE_Options).

%%%% Operation: '_get_inaccuracy'
%% 
%%   Returns: RetVal
%%
'_get_inaccuracy'(OE_THIS) ->
    corba:call(OE_THIS, '_get_inaccuracy', [], ?MODULE).

'_get_inaccuracy'(OE_THIS, OE_Options) ->
    corba:call(OE_THIS, '_get_inaccuracy', [], ?MODULE, OE_Options).

%%%% Operation: '_get_tdf'
%% 
%%   Returns: RetVal
%%
'_get_tdf'(OE_THIS) ->
    corba:call(OE_THIS, '_get_tdf', [], ?MODULE).

'_get_tdf'(OE_THIS, OE_Options) ->
    corba:call(OE_THIS, '_get_tdf', [], ?MODULE, OE_Options).

%%%% Operation: '_get_utc_time'
%% 
%%   Returns: RetVal
%%
'_get_utc_time'(OE_THIS) ->
    corba:call(OE_THIS, '_get_utc_time', [], ?MODULE).

'_get_utc_time'(OE_THIS, OE_Options) ->
    corba:call(OE_THIS, '_get_utc_time', [], ?MODULE, OE_Options).

%%%% Operation: absolute_time
%% 
%%   Returns: RetVal
%%
absolute_time(OE_THIS) ->
    corba:call(OE_THIS, absolute_time, [], ?MODULE).

absolute_time(OE_THIS, OE_Options) ->
    corba:call(OE_THIS, absolute_time, [], ?MODULE, OE_Options).

%%%% Operation: compare_time
%% 
%%   Returns: RetVal
%%
compare_time(OE_THIS, Comparison_type, Uto) ->
    corba:call(OE_THIS, compare_time, [Comparison_type, Uto], ?MODULE).

compare_time(OE_THIS, OE_Options, Comparison_type, Uto) ->
    corba:call(OE_THIS, compare_time, [Comparison_type, Uto], ?MODULE, OE_Options).

%%%% Operation: time_to_interval
%% 
%%   Returns: RetVal
%%
time_to_interval(OE_THIS, Uto) ->
    corba:call(OE_THIS, time_to_interval, [Uto], ?MODULE).

time_to_interval(OE_THIS, OE_Options, Uto) ->
    corba:call(OE_THIS, time_to_interval, [Uto], ?MODULE, OE_Options).

%%%% Operation: interval
%% 
%%   Returns: RetVal
%%
interval(OE_THIS) ->
    corba:call(OE_THIS, interval, [], ?MODULE).

interval(OE_THIS, OE_Options) ->
    corba:call(OE_THIS, interval, [], ?MODULE, OE_Options).

%%------------------------------------------------------------
%%
%% Inherited Interfaces
%%
%%------------------------------------------------------------
oe_is_a("IDL:omg.org/CosTime/UTO:1.0") -> true;
oe_is_a(_) -> false.

%%------------------------------------------------------------
%%
%% Interface TypeCode
%%
%%------------------------------------------------------------
oe_tc('_get_time') -> 
	{tk_ulonglong,[],[]};
oe_tc('_get_inaccuracy') -> 
	{tk_ulonglong,[],[]};
oe_tc('_get_tdf') -> 
	{tk_short,[],[]};
oe_tc('_get_utc_time') -> 
	{{tk_struct,"IDL:omg.org/TimeBase/UtcT:1.0","UtcT",
                    [{"time",tk_ulonglong},
                     {"inacclo",tk_ulong},
                     {"inacchi",tk_ushort},
                     {"tdf",tk_short}]},
         [],[]};
oe_tc(absolute_time) -> 
	{{tk_objref,"IDL:omg.org/CosTime/UTO:1.0","UTO"},[],[]};
oe_tc(compare_time) -> 
	{{tk_enum,"IDL:omg.org/CosTime/TimeComparison:1.0","TimeComparison",
                  ["TCEqualTo","TCLessThan","TCGreaterThan",
                   "TCIndeterminate"]},
         [{tk_enum,"IDL:omg.org/CosTime/ComparisonType:1.0","ComparisonType",
                   ["IntervalC","MidC"]},
          {tk_objref,"IDL:omg.org/CosTime/UTO:1.0","UTO"}],
         []};
oe_tc(time_to_interval) -> 
	{{tk_objref,"IDL:omg.org/CosTime/TIO:1.0","TIO"},
         [{tk_objref,"IDL:omg.org/CosTime/UTO:1.0","UTO"}],
         []};
oe_tc(interval) -> 
	{{tk_objref,"IDL:omg.org/CosTime/TIO:1.0","TIO"},[],[]};
oe_tc(_) -> undefined.

oe_get_interface() -> 
	[{"interval", oe_tc(interval)},
	{"time_to_interval", oe_tc(time_to_interval)},
	{"compare_time", oe_tc(compare_time)},
	{"absolute_time", oe_tc(absolute_time)},
	{"_get_utc_time", oe_tc('_get_utc_time')},
	{"_get_tdf", oe_tc('_get_tdf')},
	{"_get_inaccuracy", oe_tc('_get_inaccuracy')},
	{"_get_time", oe_tc('_get_time')}].




%%------------------------------------------------------------
%%
%% Object server implementation.
%%
%%------------------------------------------------------------


%%------------------------------------------------------------
%%
%% Function for fetching the interface type ID.
%%
%%------------------------------------------------------------

typeID() ->
    "IDL:omg.org/CosTime/UTO:1.0".


%%------------------------------------------------------------
%%
%% Object creation functions.
%%
%%------------------------------------------------------------

oe_create() ->
    corba:create(?MODULE, "IDL:omg.org/CosTime/UTO:1.0").

oe_create_link() ->
    corba:create_link(?MODULE, "IDL:omg.org/CosTime/UTO:1.0").

oe_create(Env) ->
    corba:create(?MODULE, "IDL:omg.org/CosTime/UTO:1.0", Env).

oe_create_link(Env) ->
    corba:create_link(?MODULE, "IDL:omg.org/CosTime/UTO:1.0", Env).

oe_create(Env, RegName) ->
    corba:create(?MODULE, "IDL:omg.org/CosTime/UTO:1.0", Env, RegName).

oe_create_link(Env, RegName) ->
    corba:create_link(?MODULE, "IDL:omg.org/CosTime/UTO:1.0", Env, RegName).

%%------------------------------------------------------------
%%
%% Init & terminate functions.
%%
%%------------------------------------------------------------

init(Env) ->
%% Call to implementation init
    corba:handle_init('CosTime_UTO_impl', Env).

terminate(Reason, State) ->
    corba:handle_terminate('CosTime_UTO_impl', Reason, State).


%%%% Operation: '_get_time'
%% 
%%   Returns: RetVal
%%
handle_call({OE_THIS, OE_Context, '_get_time', []}, _, OE_State) ->
  corba:handle_call('CosTime_UTO_impl', '_get_time', [], OE_State, OE_Context, OE_THIS, false);

%%%% Operation: '_get_inaccuracy'
%% 
%%   Returns: RetVal
%%
handle_call({OE_THIS, OE_Context, '_get_inaccuracy', []}, _, OE_State) ->
  corba:handle_call('CosTime_UTO_impl', '_get_inaccuracy', [], OE_State, OE_Context, OE_THIS, false);

%%%% Operation: '_get_tdf'
%% 
%%   Returns: RetVal
%%
handle_call({OE_THIS, OE_Context, '_get_tdf', []}, _, OE_State) ->
  corba:handle_call('CosTime_UTO_impl', '_get_tdf', [], OE_State, OE_Context, OE_THIS, false);

%%%% Operation: '_get_utc_time'
%% 
%%   Returns: RetVal
%%
handle_call({OE_THIS, OE_Context, '_get_utc_time', []}, _, OE_State) ->
  corba:handle_call('CosTime_UTO_impl', '_get_utc_time', [], OE_State, OE_Context, OE_THIS, false);

%%%% Operation: absolute_time
%% 
%%   Returns: RetVal
%%
handle_call({OE_THIS, OE_Context, absolute_time, []}, _, OE_State) ->
  corba:handle_call('CosTime_UTO_impl', absolute_time, [], OE_State, OE_Context, OE_THIS, false);

%%%% Operation: compare_time
%% 
%%   Returns: RetVal
%%
handle_call({OE_THIS, OE_Context, compare_time, [Comparison_type, Uto]}, _, OE_State) ->
  corba:handle_call('CosTime_UTO_impl', compare_time, [Comparison_type, Uto], OE_State, OE_Context, OE_THIS, false);

%%%% Operation: time_to_interval
%% 
%%   Returns: RetVal
%%
handle_call({OE_THIS, OE_Context, time_to_interval, [Uto]}, _, OE_State) ->
  corba:handle_call('CosTime_UTO_impl', time_to_interval, [Uto], OE_State, OE_Context, OE_THIS, false);

%%%% Operation: interval
%% 
%%   Returns: RetVal
%%
handle_call({OE_THIS, OE_Context, interval, []}, _, OE_State) ->
  corba:handle_call('CosTime_UTO_impl', interval, [], OE_State, OE_Context, OE_THIS, false);



%%%% Standard gen_server call handle
%%
handle_call(stop, _, State) ->
    {stop, normal, ok, State};

handle_call(_, _, State) ->
    {reply, catch corba:raise(#'BAD_OPERATION'{minor=1163001857, completion_status='COMPLETED_NO'}), State}.


%%%% Standard gen_server cast handle
%%
handle_cast(stop, State) ->
    {stop, normal, State};

handle_cast(_, State) ->
    {noreply, State}.


%%%% Standard gen_server handles
%%
handle_info(Info, State) ->
    corba:handle_info('CosTime_UTO_impl', Info, State).


code_change(OldVsn, State, Extra) ->
    corba:handle_code_change('CosTime_UTO_impl', OldVsn, State, Extra).


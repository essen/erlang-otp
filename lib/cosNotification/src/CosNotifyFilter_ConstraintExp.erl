%%------------------------------------------------------------
%%
%% Implementation stub file
%% 
%% Target: CosNotifyFilter_ConstraintExp
%% Source: /net/shelob/ldisk/daily_build/otp_prebuild_r13b.2009-04-20_20/otp_src_R13B/lib/cosNotification/src/CosNotifyFilter.idl
%% IC vsn: 4.2.20
%% 
%% This file is automatically generated. DO NOT EDIT IT.
%%
%%------------------------------------------------------------

-module('CosNotifyFilter_ConstraintExp').
-ic_compiled("4_2_20").


-include("CosNotifyFilter.hrl").

-export([tc/0,id/0,name/0]).



%% returns type code
tc() -> {tk_struct,"IDL:omg.org/CosNotifyFilter/ConstraintExp:1.0",
            "ConstraintExp",
            [{"event_types",
              {tk_sequence,
                  {tk_struct,"IDL:omg.org/CosNotification/EventType:1.0",
                      "EventType",
                      [{"domain_name",{tk_string,0}},
                       {"type_name",{tk_string,0}}]},
                  0}},
             {"constraint_expr",{tk_string,0}}]}.

%% returns id
id() -> "IDL:omg.org/CosNotifyFilter/ConstraintExp:1.0".

%% returns name
name() -> "CosNotifyFilter_ConstraintExp".




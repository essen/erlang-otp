%%------------------------------------------------------------
%%
%% Implementation stub file
%% 
%% Target: CosNotifyChannelAdmin_AdminLimit
%% Source: /net/shelob/ldisk/daily_build/otp_prebuild_r13b.2009-04-20_20/otp_src_R13B/lib/cosNotification/src/CosNotifyChannelAdmin.idl
%% IC vsn: 4.2.20
%% 
%% This file is automatically generated. DO NOT EDIT IT.
%%
%%------------------------------------------------------------

-module('CosNotifyChannelAdmin_AdminLimit').
-ic_compiled("4_2_20").


-include("CosNotifyChannelAdmin.hrl").

-export([tc/0,id/0,name/0]).



%% returns type code
tc() -> {tk_struct,"IDL:omg.org/CosNotifyChannelAdmin/AdminLimit:1.0",
                   "AdminLimit",
                   [{"name",{tk_string,0}},{"value",tk_any}]}.

%% returns id
id() -> "IDL:omg.org/CosNotifyChannelAdmin/AdminLimit:1.0".

%% returns name
name() -> "CosNotifyChannelAdmin_AdminLimit".




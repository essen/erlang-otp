%%------------------------------------------------------------
%%
%% Implementation stub file
%% 
%% Target: CosNotifyFilter_ConstraintNotFound
%% Source: /net/shelob/ldisk/daily_build/otp_prebuild_r13b.2009-04-20_20/otp_src_R13B/lib/cosNotification/src/CosNotifyFilter.idl
%% IC vsn: 4.2.20
%% 
%% This file is automatically generated. DO NOT EDIT IT.
%%
%%------------------------------------------------------------

-module('CosNotifyFilter_ConstraintNotFound').
-ic_compiled("4_2_20").


-include("CosNotifyFilter.hrl").

-export([tc/0,id/0,name/0]).



%% returns type code
tc() -> {tk_except,"IDL:omg.org/CosNotifyFilter/ConstraintNotFound:1.0",
                   "ConstraintNotFound",
                   [{"id",tk_long}]}.

%% returns id
id() -> "IDL:omg.org/CosNotifyFilter/ConstraintNotFound:1.0".

%% returns name
name() -> "CosNotifyFilter_ConstraintNotFound".




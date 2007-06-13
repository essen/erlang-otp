{application, mnesia_session,
 [{description, "MNESIA_SESSION  CXC 138 12"},
  {vsn, "1.1.6.1"},
  {modules, [
	     mnesia_CheckpointDef,	
	     mnesia_SystemInfo,
	     mnesia_TableDef,
	     mnesia_TableInfo,
	     mnesia_connector,
	     mnesia_connector_impl,
	     mnesia_corba_connector,
	     mnesia_corba_connector_impl,
	     mnesia_corba_session,
	     mnesia_corba_session_impl,
	     mnesia_session,
	     mnesia_session_impl,
	     mnesia_session_lib,
	     mnesia_session_sup,
	     mnesia_session_top_sup,
	     oe_mnesia_corba_session,
	     oe_mnesia_session
            ]},
  {registered, [
		mnesia_corba_connector,
		mnesia_connector
	       ]},
  {applications, [kernel, stdlib]},
  {mod, {mnesia_session_top_sup, []}}]}.

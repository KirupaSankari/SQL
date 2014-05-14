Rem Copyright (c) 2004, 2005, Oracle. All rights reserved.  
Rem
Rem    NAME
Rem      ashrpt.sql
Rem
Rem    DESCRIPTION
Rem      This script defaults the dbid and instance number to that of the
Rem      current instance connected-to, then calls ashrpti.sql to produce
Rem      the ASH report.
Rem
Rem    NOTES
Rem      Run as select_catalog privileges.  
Rem
Rem      If you want to use this script in a non-interactive fashion do
Rem      something like the following:
Rem
Rem      Say for example you want to generate a TEXT ASH Report for the
Rem      past 30 minutes in /tmp/ashrpt.txt, use the following SQL*Plus script:
Rem
Rem        define report_type = 'text'; -- 'html' for HTML
Rem        define begin_time  = '-30';  -- Can specify both absolute and relative 
Rem                                     -- times. Look in ashrpti.sql for syntax.
Rem        define duration    = '';     -- NULL defaults to 'till' current time
Rem        define report_name = '/tmp/ashrpt.txt';
Rem        @?/rdbms/admin/ashrpt
Rem
Rem      If you want to generate a HTML ASH Report using AWR snapshots 
Rem      imported from other databases or AWR snapshots from other instances
Rem      in a cluster, use a SQL*Plus script similar to the following:
Rem
Rem        define dbid        = 1234567890; -- NULL defaults to current database
Rem        define inst_num    = 2;          -- NULL defaults to current instance
Rem        define report_type = 'html';     -- 'text' for TEXT
Rem        define begin_time  = '-30';
Rem        define duration    = '';         -- NULL defaults to 'till current time'
Rem        define report_name = '/tmp/ashrpt.txt';
Rem        define slot_width  = '';
Rem        define target_session_id   = '';
Rem        define target_sql_id       = '';
Rem        define target_wait_class   = '';
Rem        define target_service_hash = '';
Rem        define target_module_name  = '';
Rem        define target_action_name  = '';
Rem        define target_client_id    = '';
Rem        define target_plsql_entry  = '';
Rem        @?/rdbms/admin/ashrpti
Rem
Rem      If you want to generate a HTML ASH Report for times between 9am-5pm today
Rem      in /tmp/sql_ashrpt.txt and want to target the report on a particular
Rem      SQL_ID 'abcdefghij123', use a script similar to the following:
Rem
Rem        define dbid        = '';       -- NULL defaults to current database
Rem        define inst_num    = '';       -- NULL defaults to current instance
Rem        define report_type = 'html';   -- 'text' for TEXT
Rem        define begin_time  = '09:00';
Rem        define duration    = 480;      -- 9-5 == 8 hrs or 480 mins
Rem        define report_name = '/tmp/sql_ashrpt.txt';
Rem        define slot_width  = '';
Rem        define target_session_id   = '';
Rem        define target_sql_id       = 'abcdefghij123';
Rem        define target_wait_class   = '';
Rem        define target_service_hash = '';
Rem        define target_module_name  = '';
Rem        define target_action_name  = '';
Rem        define target_client_id    = '';
Rem        define target_plsql_entry  = '';
Rem        @?/rdbms/admin/ashrpti
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    adagarwa    06/24/05 - added plsql_entry target
Rem    veeve       05/11/05 - add support for slot_width input
Rem    veeve       01/17/05 - add support for report targets
Rem    veeve       06/24/04 - added more NOTES
Rem    veeve       06/10/04 - veeve_ash_report_r2
Rem    veeve       06/04/04 - Created
Rem

--
-- Get the current database/instance information - this will be used 
-- later in the report along with bid, eid to lookup snapshots

set echo off heading on underline on;
column inst_num  heading "Inst Num"  new_value inst_num  format 99999;
column inst_name heading "Instance"  new_value inst_name format a12;
column db_name   heading "DB Name"   new_value db_name   format a12;
column dbid      heading "DB Id"     new_value dbid      format 9999999999 just c;

prompt
prompt Current Instance
prompt ~~~~~~~~~~~~~~~~

select d.dbid            dbid
     , d.name            db_name
     , i.instance_number inst_num
     , i.instance_name   inst_name
  from v$database d,
       v$instance i;

Rem
Rem Define slot width and all report targets to be NULL here, 
Rem so that ashrpti can be used directly if one or more 
Rem report targets need to be specified.
define slot_width = '';
define target_session_id = '';
define target_sql_id = '';
define target_wait_class = '';
define target_service_hash = '';
define target_module_name = '';
define target_action_name = '';
define target_client_id = '';
define target_plsql_entry = '';

Rem ashrpti.sql now
@@ashrpti

-- Undefine all variables declared here
undefine inst_num
undefine inst_name
undefine db_name
undefine dbid
undefine slot_width
undefine target_session_id
undefine target_sql_id
undefine target_wait_class
undefine target_service_hash
undefine target_module_name
undefine target_action_name
undefine target_client_id
undefine target_plsql_entry

--
-- End of file

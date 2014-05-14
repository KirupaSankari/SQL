Rem
Rem $Header: rdbms/admin/awrgdrpt.sql /main/2 2009/04/29 15:54:04 ilistvin Exp $
Rem
Rem awrgdrpt.sql
Rem
Rem Copyright (c) 2007, 2009, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      awrgdrpt.sql - AWR Global Diff Report
Rem
Rem    DESCRIPTION
Rem      This script defaults the dbid to that of the
Rem      current instance connected-to, defaults instance list to all 
Rem      available instances and then calls awrgdrpi.sql to produce
Rem      the Workload Repository RAC Compare Periods report.
Rem
Rem    NOTES
Rem      Run as select_catalog privileges.  
Rem      This report is based on the Statspack report.
Rem
Rem      If you want to use this script in an non-interactive fashion,
Rem      see the 'customer-customizable report settings' section in
Rem      awrgdrpi.sql
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    ilistvin    04/27/09 - add semicolon
Rem    ilistvin    12/17/07 - Created
Rem

--
-- Get the current database/instance information - this will be used 
-- later in the report along with bid, eid to lookup snapshots

set echo off heading on underline on;
column instance_numbers_or_all  new_value instance_numbers_or_all  noprint;
column instance_numbers_or_all2 new_value instance_numbers_or_all2 noprint;
column db_name   heading "DB Name" new_value db_name  format a12;
column dbid      heading "DB Id"   new_value dbid     format 9999999999 just c;
column dbid2     heading "DB Id"   new_value dbid2    format 9999999999 just c;

prompt
prompt Current Instance
prompt ~~~~~~~~~~~~~~~~

select d.dbid            dbid
     , d.dbid            dbid2
     , d.name            db_name
     , 'ALL'             instance_numbers_or_all
     , 'ALL'             instance_numbers_or_all2
  from v$database d;

@@awrgdrpi

undefine num_days;
undefine report_type;
undefine report_name;
undefine begin_snap;
undefine end_snap;
--
-- End of file

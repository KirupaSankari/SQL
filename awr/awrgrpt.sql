Rem
Rem $Header: rdbms/admin/awrgrpt.sql /main/2 2009/04/29 15:54:04 ilistvin Exp $
Rem
Rem awrgrpt.sql
Rem
Rem Copyright (c) 2007, 2009, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      awrgrpt.sql - AWR Global Report 
Rem
Rem    DESCRIPTION
Rem      This script defaults the dbid to that of the
Rem      current instance connected-to, then calls awrgrpti.sql to produce
Rem      the Workload Repository RAC report.
Rem
Rem    NOTES
Rem      Run with select_catalog privileges.  
Rem
Rem      If you want to use this script in an non-interactive fashion,
Rem      see the 'customer-customizable report settings' section in
Rem      awrgrpti.sql
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    ilistvin    04/27/09 - change variable name
Rem    ilistvin    11/26/07 - Created
Rem

--
-- Get the current database information - this will be used 
-- later in the report along with bid, eid to lookup snapshots

set echo off heading on underline on;
column db_name   heading "DB Name" new_value db_name  format a12;
column dbid      heading "DB Id"   new_value dbid     format 9999999999 just c;
column instance_numbers_or_all     new_value instance_numbers_or_all  noprint;

prompt
prompt Current Database
prompt ~~~~~~~~~~~~~~~~

select d.dbid            dbid
     , d.name            db_name
     , 'ALL'             instance_numbers_or_all
  from v$database d;

@@awrgrpti

undefine num_days;
undefine report_type;
undefine report_name;
undefine begin_snap;
undefine end_snap;
--
-- End of script

Rem
Rem $Header: awrblmig.sql 16-nov-2006.14:53:14 rburns Exp $
Rem
Rem awrblmig.sql
Rem
Rem Copyright (c) 2006, Oracle. All rights reserved.  
Rem
Rem    NAME
Rem      awrblmig.sql - AWR Baseline Migrate
Rem
Rem    DESCRIPTION
Rem      This script is used to migrate the AWR Baseline data from
Rem      the renamed BL tables back to the base tables.  This script is
Rem      needed because the way the baselines are stored have been changed
Rem      in 11g.  This script will 
Rem
Rem    NOTES
Rem      Run this script if you have AWR Baselines prior to the 11g release
Rem      and have upgraded to the 11g release.
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    rburns      11/16/06 - modify set statements
Rem    mlfeng      06/18/06 - Script to migrate the AWR Baseline data 
Rem    mlfeng      06/18/06 - Created
Rem

set serveroutput on;
exec dbms_output.enable(100000);

prompt
prompt This script will migrate the Baseline data on a pre-11g database
prompt to the 11g database.
prompt

begin
  dbms_swrf_internal.baseline_migrate(migrate_tables => TRUE, 
                                      drop_tables    => TRUE);
end;
/

set serveroutput off

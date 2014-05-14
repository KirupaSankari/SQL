Rem
Rem $Header: rdbms/admin/awrgdrpi.sql /main/2 2009/05/13 17:08:34 ilistvin Exp $
Rem
Rem awrgdrpi.sql
Rem
Rem Copyright (c) 2007, 2009, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      awrgdrpi.sql - Workload Repository Global Compare Periods Report
Rem
Rem    DESCRIPTION
Rem      RAC Version of Compare Period Report
Rem
Rem      This script propts the user for the dbid and, optional, list of 
Rem      instance numbers to report on, for each snapshot pair.
Rem
Rem
Rem    NOTES
Rem      Run as SYSDBA.  Generally this script should be invoked by awrgdrpt,
Rem      unless you want to pick a database and/or specific instances
Rem      other than the default.
Rem
Rem      If you want to use this script in an non-interactive fashion,
Rem      without executing the script through awrgdrpt, then
Rem      do something similar to the following:
Rem
Rem      define  num_days     = 3;
Rem      define  dbid         = 4;
Rem      define  instance_numbers_or_ALL    = '1,2,3';
Rem      define  begin_snap   = 10;
Rem      define  end_snap     = 11;
Rem      define  dbid2        = 1345;
Rem      define  instance_numbers_or_ALL2    = '9,12,15';
Rem      define  begin_snap2  = 120;
Rem      define  end_snap2    = 121;
Rem      define  report_type  = 'text';
Rem      define  report_name  = /tmp/compreport1.txt
Rem      @@?/rdbms/admin/awrgdrpi
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    ilistvin    05/08/09 - change linesize to 320 for text report
Rem    ilistvin    12/17/07 - Created
Rem

set echo off;

-- ***************************************************
--   Customer-customizable report settings
--   Change these variables to run a report on different statistics
-- ***************************************************
Rem
Rem top n events in the report summary (NULL uses package default, 10)
define top_n_events       = NULL;
Rem
Rem top n segments  (NULL uses package default, 5)
define top_n_segments     = 10;
Rem
Rem top n services (NULL uses package default, 10)
define top_n_services     = NULL;
Rem
Rem top n SQL statements (NULL uses package default, 10)
define top_n_sql          = NULL;
Rem
Rem top n files (NULL uses package default, 10)
define top_n_files        = NULL;

-- The default number of days of snapshots to list when choosing begin
-- and end snapshots
--
-- List all snapshots
-- define num_days = '';
--
-- List no (i.e. 0) snapshots
-- define num_days = 0;
--
-- List past 3 days snapshots
-- define num_days = 3;
--
-- Reports can be printed in text or html, and you must set the report_type
-- in addition to the report_name
--
-- Issue Report in Text Format
-- define report_type='text';
--
-- Issue Report in HTML Format
-- define report_type='html';

-- Optionally, set the snapshots for the report.  If you do not set them,
-- you will be prompted for the values.
-- define begin_snap = 545;
-- define end_snap   = 546;
-- define begin_snap2 = 873;
-- define end_snap2   = 874;

-- Optionally, set the name for the report itself
-- define report_name = 'awrrpt_1_545_546.html'

-- ***************************************************
--   End customer-customizable settings
-- ***************************************************


-- *******************************************************
--  The report_options variable will be the options for
--  the AWR report.
--
--  Currently, only one option is available.
--
--  NO_OPTIONS -
--    No options. Setting this will not show the ADDM
--    specific portions of the report.
--    This is the default setting.
--
--  ENABLE_ADDM -
--    Show the ADDM specific portions of the report.
--    These sections include the Buffer Pool Advice,
--    Shared Pool Advice, PGA Target Advice, and
--    Wait Class sections.
--

set veri off;
set feedback off;

variable rpt_options number;

-- option settings
define NO_OPTIONS   = 0;
define ENABLE_ADDM  = 8;

-- Set the report_options. To see the ADDM-specific sections,
-- set the rpt_options to the ENABLE_ADDM constant.
begin
  :rpt_options := &NO_OPTIONS;
end;
/
variable tn_events   NUMBER;
variable tn_files    NUMBER;
variable tn_segments NUMBER;
variable tn_services NUMBER;
variable tn_sql      NUMBER;
begin
  :tn_events    := &top_n_events;
  :tn_segments  := &top_n_segments;
  :tn_services  := &top_n_services;
  :tn_sql       := &top_n_sql;
  :tn_files     := &top_n_files;
  dbms_workload_repository.awr_set_report_thresholds(:tn_events,
                                                     :tn_files,
                                                     :tn_segments,
                                                     :tn_services,
                                                     :tn_sql,
                                                     NULL,
                                                     NULL,
                                                     NULL,
                                                     NULL);
end;
/

--
-- Find out if we are going to print report to html or to text
prompt
prompt Specify the Report Type
prompt ~~~~~~~~~~~~~~~~~~~~~~~
prompt Would you like an HTML report, or a plain text report?
prompt Enter 'html' for an HTML report, or 'text' for plain text
prompt Defaults to 'html'

column report_type new_value report_type;
set heading off;
select 'Type Specified: ',lower(nvl('&&report_type','html')) report_type from dual;
set heading on;

set termout off;
-- Set the extension based on the report_type
column ext new_value ext;
select '.html' ext from dual where lower('&&report_type') <> 'text';
select '.txt' ext from dual where lower('&&report_type') = 'text';
set termout on;

-- Get the common input!
-- awrinput will set up the bind variables we need to call the PL/SQL procedure
@@awrgdinp.sql 'awrracdiff_' &&ext

set termout off;
-- set report function name and line size
column fn_name new_value fn_name noprint;
select 'awr_global_diff_report_text' fn_name from dual
  where lower('&report_type') = 'text';
select 'awr_global_diff_report_html' fn_name from dual
  where lower('&report_type') <> 'text';

column lnsz new_value lnsz noprint;
select '320' lnsz from dual where lower('&report_type') = 'text';
select '1500' lnsz from dual where lower('&report_type') <> 'text';

set linesize &lnsz;
set termout on;
spool &report_name;
prompt

select output from table(dbms_workload_repository.&fn_name( :dbid,
                                                            :instl,
                                                            :bid, :eid,
                                                            :dbid2,
                                                            :instl2,
                                                            :bid2, :eid2
                                                           ));

spool off;

prompt Report written to &report_name.

set termout off;
clear columns sql;
ttitle off;
btitle off;
repfooter off;
set linesize 78 termout on feedback 6 heading on;
-- Undefine report name (created in awrinput.sql)
undefine report_name

undefine report_type
undefine ext
undefine fn_name
undefine lnsz

undefine NO_OPTIONS
undefine ENABLE_ADDM

undefine top_n_events
undefine num_days
undefine top_n_sql
undefine top_pct_sql
undefine sh_mem_threshold
undefine top_n_segstat

whenever sqlerror continue;
--
--  End of script file;

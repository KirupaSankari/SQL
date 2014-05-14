Rem
Rem $Header: awrgdinp.sql 25-feb-2008.08:19:21 ilistvin Exp $
Rem
Rem awrgdinp.sql
Rem
Rem Copyright (c) 2007, Oracle.  All rights reserved.  
Rem
Rem    NAME
Rem      awrgdinp.sql - AWR Glopal Compare Period Report Input variables
Rem
Rem    DESCRIPTION
Rem      This script gets the dbid,eid,filename,etc from the user
Rem
Rem    NOTES
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    ilistvin    12/17/07 - Created
Rem


-- Script Parameters:
--   First Param (&1) : file prefix e.g. 'awrrpt_'
--   Second Param (&2) : file extension e.g. '.html', '.lst'
--     **** IMPORTANT - the second parameter must be non-null, or else SQL*Plus
--          adds an awkward prompt when we try to use it

-- After executing, this module leaves the substitution variable
-- &report_name defined.  Issue the command spool &report_name to
-- spool your report to a file, and then undefine report_name when you're
-- done with it.

-- The following list of SQL*Plus bind variables will be defined and assigned
--  a value by this SQL*Plus script:
-- First pair of snapshots
--    variable dbid      number   - Database id
--    variable instl     varchar2 - CSV list of instance numbers
--    variable bid       number   - Begin snapshot id 
--    variable eid       number   - End snapshot id
-- Second pair of snapshots
--    variable dbid2     number   - Database id 
--    variable instl2    varchar2 - CSV list of instance numbers
--    variable bid2      number   - Begin snapshot id
--    variable eid2      number   - End snapshot id




clear break compute;
repfooter off;
ttitle off;
btitle off;

set heading on;
set timing off veri off space 1 flush on pause off termout on numwidth 10;
set echo off feedback off pagesize 60 linesize 80 newpage 1 recsep off;
set trimspool on trimout on define "&" concat "." serveroutput on;
set underline on;

--
-- Request the DB Id and Instance Number, if they are not specified

column instt_num  heading "Inst Num"  format 99999;
column instt_name heading "Instance"  format a12;
column dbb_name   heading "DB Name"   format a12;
column dbbid      heading "DB Id"     format a12 just c;
column host       heading "Host"      format a12;

prompt
prompt
prompt Instances in this Workload Repository schema
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
select distinct
       (case when cd.dbid = wr.dbid and 
                  cd.name = wr.db_name and
                  ci.instance_number = wr.instance_number and
                  ci.instance_name   = wr.instance_name
             then '* '
             else '  '
        end) || wr.dbid   dbbid
     , wr.instance_number instt_num
     , wr.db_name         dbb_name
     , wr.instance_name   instt_name
     , wr.host_name       host
  from dba_hist_database_instance wr, v$database cd, v$instance ci;

prompt
prompt Database Id and Instance Number for the First Pair of Snapshots
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
prompt Using &&dbid for Database Id for the first pair of snapshots
prompt Using instances &&instance_numbers_or_ALL for the first pair of snapshots

--
--  Set up the binds for dbid and instance number list
--
variable dbid       number;
variable instl      varchar2(1023);
variable inst_num   varchar2(3);
begin
  :dbid      :=  &dbid;
  :instl     :=  '&instance_numbers_or_ALL';
  if UPPER(:instl) = 'ALL' then
    :instl := '';
  end if;
  :inst_num  := '1st';
end;
/


--
--  Error reporting
--
whenever sqlerror exit;
variable max_snap_time char(10);
declare
  cursor csnapid is
     select to_char(max(end_interval_time),'dd/mm/yyyy')
       from dba_hist_snapshot
      where dbid            = :dbid;
begin
  -- Check Snapshots exist for Database Id/Instance Number
  open csnapid;
  fetch csnapid into :max_snap_time;
  if csnapid%notfound then
    raise_application_error(-20200,
      'No snapshots exist for database '||:dbid);
  end if;
  close csnapid;
end;
/
whenever sqlerror continue;


--
--  Ask how many days of snapshots to display

set termout on;
column instart_fmt noprint;
column db_name     format a12  heading 'DB Name';
column snap_id     format 99999990 heading 'Snap Id';
column snapdat     format a18  heading 'Snap Started' just c;
column lvl         format 99   heading 'Snap|Level';

prompt
prompt
prompt Specify the number of days of snapshots to choose from
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
prompt Entering the number of days (n) will result in the most recent
prompt (n) days of snapshots being listed.  Pressing <return> without
prompt specifying a number lists all completed snapshots.
prompt
prompt

set heading off;
column num_days new_value num_days noprint;
select    'Listing '
       || decode( nvl('&&num_days', 3.14)
                , 0    , 'no snapshots'
                , 3.14 , 'all Completed Snapshots'
                , 1    , 'the last day''s Completed Snapshots'
                , 'the last &num_days days of Completed Snapshots')
     , nvl('&&num_days', 3.14)  num_days
  from sys.dual;
set heading on;


--
-- List available snapshots

break on inst_name on db_name on host on instart_fmt skip 1;

ttitle off;
select  di.db_name                                        db_name
     , s.snap_id                                         snap_id
     , to_char(max(s.end_interval_time),'dd Mon YYYY HH24:mi') snapdat
     , max(s.snap_level)                                      lvl
  from dba_hist_snapshot s
     , dba_hist_database_instance di
 where di.dbid             = :dbid
   and di.dbid             = s.dbid
   and di.instance_number  = s.instance_number
   and di.startup_time     = s.startup_time
   and s.end_interval_time >=
                  decode( &num_days
                        , 0   , to_date('31-JAN-9999','DD-MON-YYYY')
                        , 3.14, s.end_interval_time
                        , to_date(:max_snap_time,'dd/mm/yyyy') - (&num_days-1))
 group by db_name, snap_id
 order by db_name, snap_id;

clear break;
ttitle off;


--
--  Ask for the snapshots Id's which are to be compared

prompt
prompt
prompt Specify the First Pair of Begin and End Snapshot Ids
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
prompt First Begin Snapshot Id specified: &&begin_snap
prompt
prompt First End   Snapshot Id specified: &&end_snap
prompt


--
--  Set up the snapshot-related binds

variable bid        number;
variable eid        number;
begin
  :bid       :=  &begin_snap;
  :eid       :=  &end_snap;
end;
/

prompt


--
--  Error reporting

whenever sqlerror exit;
declare

  cursor cspid(vspid dba_hist_snapshot.snap_id%type) is
     select end_interval_time
          , startup_time
       from dba_hist_snapshot
      where snap_id         = vspid
        and dbid            = :dbid;


  bsnapt  dba_hist_snapshot.end_interval_time%type;
  bstart  dba_hist_snapshot.startup_time%type;
  esnapt  dba_hist_snapshot.end_interval_time%type;
  estart  dba_hist_snapshot.startup_time%type;
  insts   AWRRPT_INSTANCE_LIST_TYPE;

begin

  -- Check Begin Snapshot id is valid, get corresponding instance startup time
  open cspid(:bid);
  fetch cspid into bsnapt, bstart;
  if cspid%notfound then
    raise_application_error(-20200,
      'Begin Snapshot Id '||:bid||' does not exist for this database');
  end if;
  close cspid;

  -- Check End Snapshot id is valid and get corresponding instance startup time
  open cspid(:eid);
  fetch cspid into esnapt, estart;
  if cspid%notfound then
    raise_application_error(-20200,
      'End Snapshot Id '||:eid||' does not exist for this database');
  end if;
  if :eid <= :bid then
    raise_application_error(-20200,
     'End Snapshot Id '||:eid||
     ' must be greater than Begin Snapshot Id '||:bid);
  end if;
  close cspid;

 --
 -- Make sure at least one instance has not been re-started between
 -- begin and end snapshots
 --
 begin
   select b.instance_number
     bulk collect into insts
   from dba_hist_snapshot b, dba_hist_snapshot e
  where b.dbid = :dbid
    and b.snap_id = :bid
    and e.dbid = :dbid
    and e.snap_id = :eid
    and e.startup_time = b.startup_time
    and e.instance_number = b.instance_number;
 exception
  -- Check startup time is same for begin and end snapshot ids
  when no_data_found then
    raise_application_error(-20200,
      'All instances were shutdown between snapshots '||:bid||' and '||:eid);
  when others then raise;
 end;

end;
/
whenever sqlerror continue;



clear break compute;
repfooter off;
ttitle off;
btitle off;

set heading on;
set timing off veri off space 1 flush on pause off termout on numwidth 10;
set echo off feedback off pagesize 60 linesize 80 newpage 1 recsep off;
set trimspool on trimout on define "&" concat "." serveroutput on;
set underline on;

--
-- Request the DB Id and Instance Number, if they are not specified

prompt
prompt
prompt Instances in this Workload Repository schema
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
select distinct
       (case when cd.dbid = wr.dbid and 
                  cd.name = wr.db_name and
                  ci.instance_number = wr.instance_number and
                  ci.instance_name   = wr.instance_name
             then '* '
             else '  '
        end) || wr.dbid   dbbid
     , wr.instance_number instt_num
     , wr.db_name         dbb_name
     , wr.instance_name   instt_name
     , wr.host_name       host
  from dba_hist_database_instance wr, v$database cd, v$instance ci;

--
-- Set up dbid and instance number for the first pair of snapshots
-- as defaults for the second pair of snapshots
--
column dbid1 new_value dbid1 noprint;
column instl1 new_value instnum1 noprint;
select :dbid as dbid1, :instl as instnum1 from dual;

prompt
prompt Database Id and Instance Number for the Second Pair of Snapshots
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
prompt Using &&dbid2 for Database Id for the second pair of snapshots
prompt Using instances &&instance_numbers_or_ALL2 for the second pair of snapshots

--
--  Set up the binds for dbid and instance number list
--
variable dbid2      number;
variable instl2     varchar2(1023);
variable inst_num2  varchar2(4);
begin
  :dbid2     :=  nvl(&dbid2,&dbid1);
  :instl2    :=  '&instance_numbers_or_ALL2';
  if UPPER(:instl2) = 'ALL' then
    :instl2:= '';
  end if;
  :inst_num2 := '2nd';
end;
/


--
--  Error reporting
--
whenever sqlerror exit;
variable max_snap_time char(10);
declare
  cursor csnapid is
     select to_char(max(end_interval_time),'dd/mm/yyyy')
       from dba_hist_snapshot
      where dbid            = :dbid2;
begin
  -- Check Snapshots exist for Database Id/Instance Number
  open csnapid;
  fetch csnapid into :max_snap_time;
  if csnapid%notfound then
    raise_application_error(-20200,
      'No snapshots exist for database '||:dbid2);
  end if;
  close csnapid;
end;
/
whenever sqlerror continue;


--
--  Ask how many days of snapshots to display

set termout on;
column instart_fmt noprint;
column db_name     format a12  heading 'DB Name';
column snap_id     format 99999990 heading 'Snap Id';
column snapdat     format a18  heading 'Snap Started' just c;
column lvl         format 99   heading 'Snap|Level';

prompt
prompt
prompt Specify the number of days of snapshots to choose from
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
prompt Entering the number of days (n) will result in the most recent
prompt (n) days of snapshots being listed.  Pressing <return> without
prompt specifying a number lists all completed snapshots.
prompt
prompt

set heading off;
column num_days2 new_value num_days2 noprint;
select    'Listing '
       || decode( nvl('&&num_days2', 3.14)
                , 0    , 'no snapshots'
                , 3.14 , 'all Completed Snapshots'
                , 1    , 'the last day''s Completed Snapshots'
                , 'the last &num_days days of Completed Snapshots')
     , nvl('&&num_days', 3.14)  num_days2
  from sys.dual;
set heading on;


--
-- List available snapshots

break on inst_name on db_name on host on instart_fmt skip 1;

ttitle off;
select  di.db_name                                        db_name
     , s.snap_id                                         snap_id
     , to_char(max(s.end_interval_time),'dd Mon YYYY HH24:mi') snapdat
     , max(s.snap_level)                                      lvl
  from dba_hist_snapshot s
     , dba_hist_database_instance di
 where di.dbid             = :dbid2
   and di.dbid             = s.dbid
   and di.instance_number  = s.instance_number
   and di.startup_time     = s.startup_time
   and s.end_interval_time >= 
                  decode( &num_days
                        , 0   , to_date('31-JAN-9999','DD-MON-YYYY')
                        , 3.14, s.end_interval_time
                        , to_date(:max_snap_time,'dd/mm/yyyy') - (&num_days-1))
 group by db_name, snap_id
 order by db_name, snap_id;

clear break;
ttitle off;


--
--  Ask for the snapshots Id's which are to be compared

prompt
prompt
prompt Specify the First Pair of Begin and End Snapshot Ids
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
prompt First Begin Snapshot Id specified: &&begin_snap2
prompt
prompt First End   Snapshot Id specified: &&end_snap2
prompt


--
--  Set up the snapshot-related binds

variable bid2       number;
variable eid2       number;
begin
  :bid2      :=  &begin_snap2;
  :eid2      :=  &end_snap2;
end;
/

prompt


--
--  Error reporting

whenever sqlerror exit;
declare

  cursor cspid(vspid dba_hist_snapshot.snap_id%type) is
     select end_interval_time
          , startup_time
       from dba_hist_snapshot
      where snap_id         = vspid
        and dbid            = :dbid2;


  bsnapt  dba_hist_snapshot.end_interval_time%type;
  bstart  dba_hist_snapshot.startup_time%type;
  esnapt  dba_hist_snapshot.end_interval_time%type;
  estart  dba_hist_snapshot.startup_time%type;
  insts   AWRRPT_INSTANCE_LIST_TYPE;

begin

  -- Check Begin Snapshot id is valid, get corresponding instance startup time
  open cspid(:bid2);
  fetch cspid into bsnapt, bstart;
  if cspid%notfound then
    raise_application_error(-20200,
      'Begin Snapshot Id '||:bid2||' does not exist for this database');
  end if;
  close cspid;

  -- Check End Snapshot id is valid and get corresponding instance startup time
  open cspid(:eid2);
  fetch cspid into esnapt, estart;
  if cspid%notfound then
    raise_application_error(-20200,
      'End Snapshot Id '||:eid2||' does not exist for this database');
  end if;
  if :eid <= :bid then
    raise_application_error(-20200,
      'End Snapshot Id '||:eid2||
      ' must be greater than Begin Snapshot Id '||:bid2);
  end if;
  close cspid;

 --
 -- Make sure at least one instance has not been re-started between
 -- begin and end snapshots
 --
 begin
   select b.instance_number
     bulk collect into insts
   from dba_hist_snapshot b, dba_hist_snapshot e
  where b.dbid = :dbid2
    and b.snap_id = :bid2
    and e.dbid = :dbid2
    and e.snap_id = :eid2
    and e.startup_time = b.startup_time
    and e.instance_number = b.instance_number;
 exception
  -- Check startup time is same for begin and end snapshot ids
  when no_data_found then
    raise_application_error(-20200,
      'All instances were shutdown between snapshots '||:bid2||' and '||:eid2);
  when others then raise;
 end;

end;
/
whenever sqlerror continue;



clear break compute;
repfooter off;
ttitle off;
btitle off;



--
-- Use report name if specified, otherwise prompt user for output file
-- name (specify default), then begin spooling
--
set termout off;
column dflt_name new_value dflt_name noprint;
select '&&1'||:inst_num||'_'||:bid||'_'||:inst_num2||'_'||:bid2||'&&2' dflt_name from dual;
set termout on;

prompt
prompt Specify the Report Name
prompt ~~~~~~~~~~~~~~~~~~~~~~~
prompt The default report file name is &dflt_name.  To use this name,
prompt press <return> to continue, otherwise enter an alternative.
prompt

set heading off;
column report_name new_value report_name noprint;
select 'Using the report name ' || nvl('&&report_name','&dflt_name')
     , nvl('&&report_name','&dflt_name') report_name
  from sys.dual;

set heading off;
set pagesize 50000;
set echo off;
set feedback off;

undefine dbid
undefine inst_num
undefine num_days
undefine begin_snap
undefine end_snap

undefine dbid2
undefine inst_num2
undefine num_days2
undefine begin_snap2
undefine end_snap2


undefine dflt_name2

undefine 1
undefine 2
--
-- End of script

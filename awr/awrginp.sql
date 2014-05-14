Rem
Rem $Header: awrginp.sql 21-feb-2008.08:36:05 ilistvin Exp $
Rem
Rem awrginp.sql
Rem
Rem Copyright (c) 2007, Oracle. All rights reserved.  
Rem
Rem    NAME
Rem      awrginp.sql - AWR Global Input
Rem
Rem    DESCRIPTION
Rem      Code used for AWR RAC report.
Rem      This script gets the dbid,eid,filename,etc from the user.
Rem
Rem    NOTES
Rem      
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    ilistvin    11/26/07 - Set up input parameters for AWR RAC Report.
Rem    ilistvin    11/26/07 - Created
Rem


-- The following list of SQL*Plus bind variables will be defined and assigned
-- a value -- by this SQL*Plus script:
--    variable dbid      number     - Database id
--    variable bid       number     - Begin snapshot id
--    variable eid       number     - End snapshot id
--    variable instl     varchar2   - comma-separated list of instance numbers


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

column dbb_name   heading "DB Name"   format a12;
column dbbid      heading "DB Id"     format a12 just c;
column host       heading "Host"      format a12;

prompt
prompt
prompt Instances in this Workload Repository schema
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
select distinct
       (case when cd.dbid = wr.dbid and
                  cd.name = wr.db_name
             then '* '
             else '  '
        end) || wr.dbid   dbbid
     , wr.instance_number instt_num
     , wr.db_name         dbb_name
     , wr.instance_name   instt_name
     , wr.host_name       host
  from dba_hist_database_instance wr, v$database cd;

prompt
prompt Using &&dbid for database Id 
prompt Using instances &&instance_numbers_or_ALL (default 'ALL') 


--
--  Set up the binds for dbid and instance number list

variable dbid       number;
variable instl      varchar2(1023);
variable inst_num   varchar2(3);
begin
  :dbid      :=  &dbid;
  :instl     :=  '&instance_numbers_or_ALL';
  if UPPER(:instl) = 'ALL' then
    :instl := '';
  end if;
  :inst_num  := 'rac';
end;
/

--
--  Error reporting

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
--

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
   and s.end_interval_time >= decode( &num_days
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
prompt Specify the Begin and End Snapshot Ids
prompt ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
prompt Begin Snapshot Id specified: &&begin_snap
prompt
prompt End   Snapshot Id specified: &&end_snap
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
      'End Snapshot Id '||:eid||' must be greater than Begin Snapshot Id '||:bid);
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


-- Undefine substitution variables
undefine dbid
undefine num_days
undefine begin_snap
undefine end_snap
undefine db_name
--
-- End of script file

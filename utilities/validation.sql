/**********************************************
 * Database Validation Script
 * Author	anjul.sahu@accenture.com
 * History
 * 1.0		Initial Version
 * 1.1		Spool file naming method
 * 1.2		added check for parallelism
 * Usage
 * validation [PRE|POST]
 **********************************************/
set feedback off pages 1000 heading off verify off
undefine sname
define event_code="&1"
col spool_name new_value sname
select '&event_code'||'_'||instance_name||'_'||to_char(sysdate,'YYYYMMDD_HH24MI') spool_name from v$instance;
spool &sname

-- get timing
select 'Start Time: '||to_char(sysdate,'DD-MON-YYYY HH24:MI:SS') from dual;

-- database details
select
   'Hostname : ' || host_name
   ,'Instance Name : ' || instance_name
   ,'Started At : ' || to_char(startup_time,'DD-MON-YYYY HH24:MI:SS') stime
   ,'Uptime : ' || floor(sysdate - startup_time) || ' days(s) ' ||
   trunc( 24*((sysdate-startup_time) -
   trunc(sysdate-startup_time))) || ' hour(s) ' ||
   mod(trunc(1440*((sysdate-startup_time) -
   trunc(sysdate-startup_time))), 60) ||' minute(s) ' ||
   mod(trunc(86400*((sysdate-startup_time) -
   trunc(sysdate-startup_time))), 60) ||' seconds' uptime
from
   sys.v_$instance
/
PRO
-- show logged in user
show user
PRO
-- get file status
PRO FILE STATUS, Everything should be OK
PRO ========================================
col status format a120 wrap  heading "Status"
Select status_01||'    | '||status_02 status
  From
       (select distinct
       decode (status
                     , 'ONLINE', '   V$Datafile Status '||Lpad('OK',12)
                     , 'SYSTEM', '   V$Datafile Status '||Lpad('OK',12)
                               , '   V$Datafile Status '||Lpad('Warning:',12)
              ) STATUS_01 from v$datafile)
     , (select distinct
       decode (status
                     , 'ONLINE', '   V$Tempfile Status '||Lpad('OK',14)
                     , 'SYSTEM', '   V$Tempfile Status '||Lpad('OK',14)
                               , '   V$Tempfile Status '||Lpad('Warning:',14)
              ) STATUS_02 from v$tempfile)
Union
Select status_01||'    | '||status_02 status
  From
      (select distinct
       decode (status
                     , 'ONLINE',    '   Dba_Tablespaces Status '||Lpad('OK',7)
                     , 'READ ONLY', '   Dba_Tablespaces Status '||Lpad('OK',7)
                                  , '   Dba_Tablespaces Status '||Lpad('Warning:',7)
              ) STATUS_01 from dba_tablespaces)
     , (select distinct
       decode (status
                     , 'CURRENT',  '   V$Log Status '||Lpad('OK',19)
                     , 'ACTIVE',   '   V$Log Status '||Lpad('OK',19)
                     , 'INACTIVE', '   V$Log Status '||Lpad('OK',19)
                                 , '   V$Log Status '||Lpad('Warning:',19)
              ) STATUS_02 from v$log)
union
Select status_01||'    | '||status_02 status
  From
      (select
       distinct
       decode (count(1)
                       , 0, '   V$Recover_File '||Lpad('OK',15)
                          , '   V$Recover_File '||Lpad('Warning:',15)
              ) STATUS_01 from v$recover_file)
     , (select
       distinct
       decode (count(1)
                       , 0, '   V$Recovery_Log '||Lpad('OK',17)
                          , '   V$Recovery_Log '||Lpad('Warning:',17)
              ) STATUS_02 from v$recovery_log)
;
PRO

-- list of invalid objects
PRO Object Count by Status (this may take some time)
PRO ================================================
col status for a20
select status,count(*) count from dba_objects where owner not like 'SYS%' group by status;
PRO

PRO List of Invalid Objects
PRO =======================
col owner for a16
col object_name for a30 heading 'ObjName'
col object_type for a16
col status for a10
set heading on
select owner,object_name,object_type,status from dba_objects where owner not like 'SYS%' and status<>'VALID';
set heading off
PRO

-- Invalid Index count
PRO INVALID INDEX CHECK (REBUILD INVALID INDEXES)
PRO =============================================
select 'Invalid Index Count: '|| sum(idxcount) from (
select count(1) idxcount from dba_indexes where status not in ('VALID','N/A')
union
select count(1) idxcount from dba_ind_partitions where status='UNUSABLE'
union
select count(1) idxcount from dba_ind_subpartitions where status='UNUSABLE'
);


PRO How many CPU does the system have?
PRO Default degree of parallelism is
PRO Default = parallel_threads_per_cpu * cpu_count
PRO -------------------------------------------------;
select substr(name,1,30) Name , substr(value,1,5) Value
from v$parameter
where  name in  ('parallel_threads_per_cpu' , 'cpu_count' );


PRO  Normally   DOP := degree * Instances
PRO  See the following Note for the excat formula.
PRO  Note:260845.1  Old and new Syntax for setting Degree of Parallelism
PRO  How many tables a user have with different DOP's
PRO  -------------------------------------------------------;
set heading on
select * from (
select  substr(owner,1,15)  Owner  , ltrim(degree) Degree,
        ltrim(instances)  Instances,
        count(*)   "Num Tables"  , 'Parallel'
from all_tables
where ( trim(degree) != '1' and trim(degree) != '0' ) or
      ( trim(instances) != '1' and trim(instances) != '0' )
group by  owner, degree , instances
union
select  substr(owner,1,15) owner  ,  '1' , '1' ,
         count(*)  , 'Serial'
from all_tables
where ( trim(degree) = '1' or trim(degree) != '0' ) and
      ( trim(instances) != '1' or trim(instances) != '0' )
group by  owner
)
order by owner;


PRO  How many indexes a user have with different DOP's
PRO   ---------------------------------------------------;
select * from (
select  substr(owner,1,15) Owner  ,
        substr(trim(degree),1,7) Degree ,
        substr(trim(instances),1,9) Instances ,
        count(*)   "Num Indexes",
        'Parallel'
from all_indexes
where ( trim(degree) != '1' and trim(degree) != '0' ) or
      ( trim(instances) != '1' and trim(instances) != '0' )
group by  owner, degree , instances
union
select  substr(owner,1,15) owner  ,  '1' , '1' ,
         count(*)  , 'Serial'
from all_indexes
where ( trim(degree) = '1' or trim(degree) != '0' ) and
      ( trim(instances) != '1' or trim(instances) != '0' )
group by  owner
)
order by owner;


PRO  Tables that have Indexes with not the same DOP
PRO  !!!!! This command can take some time to execute !!!
PRO  ---------------------------------------------------;
set lines 150
select  substr(t.owner,1,15) Owner  ,
        t.table_name ,
        substr(trim(t.degree),1,7) Degree ,
        substr(trim(t.instances),1,9) Instances,
        i.index_name ,
        substr(trim(i.degree),1,7) Degree ,
        substr(trim(i.instances),1,9) Instances
from all_indexes  i,
     all_tables   t
where  ( trim(i.degree) !=  trim(t.degree)  or
         trim(i.instances) !=  trim(t.instances)  ) and
         i.owner = t.owner  and
         i.table_name = t.table_name;

PRO
--Identify if there are any non SYS owned DISABLED constraints 
PRO Constraints Status (If Disabled, then investigate and re-enable)
PRO ================================================================
select distinct status from dba_constraints
where owner not like 'SYS%';
PRO
--Identify if there are any non SYS owned DISABLED triggers 
PRO Triggers Status (If Disabled, then investigate and re-enable)
PRO ===============================================================
select distinct status from dba_triggers
where owner not like 'SYS%';

set heading on
PRO
PRO TABLESPACE UTILISATION
PRO =======================
set verify off
col "% Used" for a6
col "Used" for a22
set lines 260
select t.tablespace_name, t.mb "TotalMB", t.mb - nvl(f.mb,0) "UsedMB", nvl(f.mb,0) "FreeMB"
       ,lpad(ceil((1-nvl(f.mb,0)/decode(t.mb,0,1,t.mb))*100)||'%', 6) "% Used", t.ext "Ext",
       '|'||rpad(lpad('#',ceil((1-nvl(f.mb,0)/decode(t.mb,0,1,t.mb))*20),'#'),20,' ')||'|' "Used"
from (
  select tablespace_name, trunc(sum(bytes)/1048576) MB
  from dba_free_space
  group by tablespace_name
 union all
  select tablespace_name, trunc(sum(bytes_free)/1048576) MB
  from v$temp_space_header
  group by tablespace_name
) f, (
  select tablespace_name, trunc(sum(bytes)/1048576) MB, max(autoextensible) ext
  from dba_data_files
  group by tablespace_name
 union all
  select tablespace_name, trunc(sum(bytes)/1048576) MB, max(autoextensible) ext
  from dba_temp_files
  group by tablespace_name
) t
where t.tablespace_name = f.tablespace_name (+)
order by t.tablespace_name;
PRO
set heading off
-- end time
select 'End Time: '||to_char(sysdate,'DD-MON-YYYY HH24:MI:SS') from dual;
spool off
clear columns


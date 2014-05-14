set lines 120
set pages 999
clear col

set termout off
set trimout on
set trimspool on


alter session set nls_date_format='dd-Mon-yyyy hh24:mi';

spool undousage.out

prompt
prompt  ############## RUNTIME ############## 
prompt

col rdate head "Run Time"

select sysdate rdate from dual;

prompt 
prompt  ############## IN USE Undo Data ############## 
prompt 

select 
((select (nvl(sum(bytes),0)) 
from dba_undo_extents 
where tablespace_name in (select tablespace_name from dba_tablespaces
   where retention like '%GUARANTEE' )
and status in ('ACTIVE','UNEXPIRED')) *100) / 
(select sum(bytes) 
from dba_data_files 
where tablespace_name in (select tablespace_name from dba_tablespaces
   where retention like '%GUARANTEE' )) "PCT_INUSE" 
from dual; 


select tablespace_name, extent_management, allocation_type,
segment_space_management, retention
from dba_tablespaces where retention like '%GUARANTEE'
/

col c format 999,999,999,999 head "Sum of Free"

select (nvl(sum(bytes),0)) c from dba_free_space
where tablespace_name in
(select tablespace_name from dba_tablespaces where retention like '%GUARANTEE')
/

col d format 999,999,999,999 head "Total Bytes"

select sum(bytes) d from dba_data_files
where tablespace_name in
(select tablespace_name from dba_tablespaces where retention like '%GUARANTEE')
/


PROMPT
PROMPT  ############## UNDO SEGMENTS ############## 
PROMPT

col status head "Status"
col z format 999,999 head "Total Extents"
break on report
compute sum on report of z

select status, count(*) z from dba_undo_extents
group by status
/

col z format 999,999 head "Undo Segments"

select status, count(*) z from dba_rollback_segs
group by status
/

clear break
clear compute

prompt 
prompt  ############## CURRENT STATUS OF SEGMENTS  ############## 
prompt  ##############   SNAPSHOT IN TIME INFO     ##############
prompt  ##############(SHOWS CURRENT UNDO ACTIVITY)##############
prompt 


col segment_name format a30 head "Segment Name"
col "ACT BYTES" format 999,999,999,999 head "Active Bytes"
col "UNEXP BYTES" format 999,999,999,999 head "Unexpired Bytes"
col "EXP BYTES" format 999,999,999,999 head "Expired Bytes"

select segment_name, nvl(sum(act),0) "ACT BYTES", 
  nvl(sum(unexp),0) "UNEXP BYTES",
  nvl(sum(exp),0) "EXP BYTES"
from (select segment_name, nvl(sum(bytes),0) act,00 unexp, 00 exp
   from dba_undo_extents where status='ACTIVE' group by segment_name
union 
select segment_name, 00 act, nvl(sum(bytes),0) unexp, 00 exp
from dba_undo_extents where status='UNEXPIRED' group by segment_name
union
select segment_name, 00 act, 00 unexp, nvl(sum(bytes),0) exp
from dba_undo_extents where status='EXPIRED' group by segment_name)
group by segment_name
order by 1
/

prompt 
prompt  ############## UNDO SPACE USAGE ############## 
prompt 

col usn format 999,999 head "Segment#"
col shrinks format 999,999,999 head "Shrinks"
col aveshrink format 999,999,999 head "Avg Shrink Size"


select usn, shrinks, aveshrink from v$rollstat
/
spool off
set termout on
set trimout off
set trimspool off
clear col

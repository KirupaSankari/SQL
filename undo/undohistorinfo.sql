set lines 120
set pages 999
clear col

set termout off
set trimout on
set trimspool on

alter session set nls_date_format='dd-hh24:mi';

spool undohistoryinfo.out

prompt
prompt  ############## RUNTIME ############## 
prompt

col rdate head "Run Time"

select sysdate rdate from dual;

prompt 
prompt  ############## HISTORICAL DATA ############## 
prompt 

col x format 999,999 head "Max Concurrent|Last 7 Days"
col y format 999,999 head "Max Concurrent|Since Startup"

select max(maxconcurrency) x from v$undostat
/
select max(maxconcurrency) y from sys.wrh$_undostat
/

col i format 999,999 head "1555 Errors"
col j format 999,999 head "Undo Space Errors"

select sum(ssolderrcnt) i from v$undostat
where end_time > sysdate-2
/

select sum(nospaceerrcnt) j from v$undostat
where end_time > sysdate-2
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

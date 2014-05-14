set lines 120
set pages 999
clear col

set termout off
set trimout on
set trimspool on

alter session set nls_date_format='dd-hh24:mi';

spool undopressure.out

prompt
prompt  ############## RUNTIME ############## 
prompt

col rdate head "Run Time"

select sysdate rdate from dual;

prompt 
prompt  ############## WAITS FOR UNDO (Since Startup) ############## 
prompt 

col inst_id head "Instance#"
col eq_type format a3 head "Enq"
col total_req# format 999,999,999,999,999,999 head "Total Requests"
col total_wait# format 999,999 head "Total Waits"
col succ_req# format 999,999,999,999,999,999 head "Successes"
col failed_req# format 999,999,999999 head "Failures"
col cum_wait_time format 999,999,999 head "Cummalitve|Time"

select * from v$enqueue_stat where eq_type='US'
union
select * from v$enqueue_stat where eq_type='HW'
/

prompt 
prompt  ############## LOCKS FOR UNDO ############## 
prompt 

col addr head "ADDR"
col KADDR head "KADDR"
col sid head "Session"
col osuser format a10 head "OS User"
col machine format a15 head "Machine"
col program format a17 head "Program"
col process format a7 head "Process"
col lmode head "Lmode"
col request head "Request"
col ctime format 9,999 head "Time|(Mins)"
col block head "Blocking?"

select /*+ RULE */  a.SID, b.process,
b.OSUSER,  b.MACHINE,  b.PROGRAM, 
addr, kaddr, lmode, request, round(ctime/60/60,0) ctime, block 
from 
v$lock a, 
v$session b 
where 
a.sid=b.sid
and a.type='US'
/

prompt 
prompt  ############## TUNED RETENTION HISTORY (Last 2 Days) ############## 
prompt  ##############        LOWEST AND HIGHEST DATA        ############## 
prompt 

col low format 999,999,999,999 head "Undo Retention|Lowest Tuned Value"
col high format 999,999,999,999 head "Undo Retention|Highest Tuned Value"

select end_time, tuned_undoretention from v$undostat where tuned_undoretention = (
select min(tuned_undoretention) low
from v$undostat
where end_time > sysdate-2)
/

select end_time, tuned_undoretention from v$undostat where tuned_undoretention = (
select max(tuned_undoretention) high
from v$undostat
where end_time > sysdate-2)
/

prompt 
prompt  ############## CURRENT TRANSACTIONS ############## 
prompt 

col sql_text format a40 word_wrapped head "SQL Code"

select a.start_date, a.start_scn, a.status, c.sql_text
from v$transaction a, v$session b, v$sqlarea c
where b.saddr=a.ses_addr and c.address=b.sql_address
and b.sql_hash_value=c.hash_value
/

select current_scn from v$database
/

col a format 999,999 head "UnexStolen"
col b format 999,999 head "ExStolen"
col c format 999,999 head "UnexReuse"
col d format 999,999 head "ExReuse"

prompt 
prompt  ############## WHO'S STEALING WHAT? (Last 2 Days) ############## 
prompt 

select unxpstealcnt a, expstealcnt b,
  unxpblkreucnt c, expblkreucnt d
from v$undostat
where (unxpstealcnt > 0 or expstealcnt > 0)
and end_time > sysdate-2
/

spool off
set termout on
set trimout off
set trimspool off
clear col

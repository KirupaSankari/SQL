set lines 120
set pages 999
clear col

set termout off
set trimout on
set trimspool on


alter session set nls_date_format='dd-hh24:mi';

spool undostatistics.out

prompt
prompt  ############## RUNTIME ############## 
prompt

col rdate head "Run Time"

select sysdate rdate from dual;

col current_scn head "SCN Now"
col start_date head "Trans Started"
col start_scn head "SCN for Trans"
col ses_addr head "ADDR"

prompt 
prompt  ############## Historical V$UNDOSTAT (Last 2 Days) ############## 
prompt 


col end_time format a18 Head "Date/Time"
col maxq format 999,999 head "Query|Maximum|Minutes"
col maxquerysqlid head "SqlID"
col undotsn format 999,999 head "TBS"
col undoblks format 999,999,999 head "Undo|Blocks"
col txncount format 999,999,999 head "# of|Trans"
col unexpiredblks format 999,999,999 head "# of Unexpired"
col expiredblks format 999,999,999 head "# of Expired"
col tuned format 999,999 head "Tuned Retention|(Minutes)"

select end_time, round(maxquerylen/60,0) maxq, maxquerysqlid,
undotsn, undoblks, txncount, unexpiredblks, expiredblks, 
round(tuned_undoretention/60,0) Tuned
from dba_hist_undostat
where end_time > sysdate-2
order by 1
/

prompt 
prompt  ############## RECENT MISSES FOR UNDO (Last 2 Days) ############## 
prompt 

clear col
set lines 500
select * from v$undostat where maxquerylen > tuned_undoretention
and end_time > sysdate-2
order by 2
/

select * from sys.wrh$_undostat where maxquerylen > tuned_undoretention
and end_time > sysdate-2
order by 2
/

prompt 
prompt  ############## AUTO-TUNING TUNE-DOWN DATA    ############## 
prompt  ############## ROLLBACK DATA (Since Startup) ############## 
prompt 

col name format a60 head "Name"
col value format 999,999,999 head "Counters"

select name, value from v$sysstat
where name like '%down retention%' or name like 'une down%'
or name like '%undo segment%' or name like '%rollback%'
or name like '%undo record%'
/

prompt 
prompt  ############## Long Running Query History ############## 
prompt 

col end_time head "Date"
col maxquerysqlid head "SQL ID"
col runawayquerysqlid format a15 head "Runaway SQL ID"
col results format a35 word_wrapped head "Space Issues"
col status head "Status"
col newret head "Tuned Down|Retention"

select end_time, maxquerysqlid, runawayquerysqlid, status,
        decode(status,1,'Slot Active',4,'Reached Best Retention',5,'Reached Best Retention',
                    8, 'Runaway Query',9,'Runaway Query-Active',10,'Space Pressure',
                   11,'Space Pressure Currently',
                   16, 'Tuned Down (to undo_retention) due to Space Pressure', 
                   17,'Tuned Down (to undo_retention) due to Space Pressure-Active',
                   18, 'Tuning Down due to Runaway', 19, 'Tuning Down due to Runaway-Active',
                   28, 'Runaway tuned down to last tune down value',
                   29, 'Runaway tuned down to last tune down value',
                   32, 'Max Tuned Down - Not Auto-Tuning',
                   33, 'Max Tuned Down - Not Auto-Tuning (Active)',
                   37, 'Max Tuned Down - Not Auto-Tuning (Active)', 
                   38, 'Max Tuned Down - Not Auto-Tuning', 
                   39, 'Max Tuned Down - Not Auto-Tuning (Active)', 
                   40, 'Max Tuned Down - Not Auto-Tuning', 
                   41, 'Max Tuned Down - Not Auto-Tuning (Active)', 
                   42, 'Max Tuned Down - Not Auto-Tuning', 
                   44, 'Max Tuned Down - Not Auto-Tuning', 
                   45, 'Max Tuned Down - Not Auto-Tuning (Active)', 
                   'Other ('||status||')') Results, spcprs_retention NewRet
from sys.wrh$_undostat
where status > 1
/



prompt 
prompt  ############## Details on Long Run Queries ############## 
prompt 

col sql_fulltext head "SQL Text"
Col sql_id heading "SQL ID"

select sql_id, sql_fulltext, last_load_time "Last Load", 
round(elapsed_time/60/60/24,0) "Elapsed Days" 
from v$sql where sql_id in 
(select maxquerysqlid from sys.wrh$_undostat 
where status > 1)
/

spool off
set termout on
set trimout off
set trimspool off
clear col

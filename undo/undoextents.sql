
spool UndoExts.out  

ttitle off
set pages 999
set lines 150
set verify off 

set termout off
set trimout on
set trimspool on

REM   
REM ------------------------------------------------------------------------  
  
REM   
REM  -----------------------------------------------------------------  
REM  
  
REM
REM  REPORTING UNDO EXTENTS INFORMATION:  
REM   
REM  -----------------------------------------------------------------  
REM 
REM  Undo Extents breakdown information
REM

ttitle center "Rollback Segments Breakdown" skip 2

col status format a20
col cnt format 999,999,999 head "How Many?"

select status, count(*) cnt from dba_rollback_segs
group by status
/

ttitle center "Undo Extents" skip 2

col segment_name format a30 heading "Name"
col "ACT BYTES" format 999,999,999,999 head "Active|Extents"
col "UNEXP BYTES" format 999,999,999,999 head "Unxpired|Extents"
col "EXP BYTES" format 999,999,999,999 head "Expired|Extents"

select segment_name,
 nvl(sum(act),0) "ACT BYTES",
 nvl(sum(unexp),0) "UNEXP BYTES",
 nvl(sum(exp),0) "EXP BYTES"
 from (
  select segment_name,
         nvl(sum(bytes),0) act,00 unexp, 00 exp
    from DBA_UNDO_EXTENTS
   where status='ACTIVE' group by segment_name
  union
  select segment_name,
         00 act, nvl(sum(bytes),0) unexp, 00 exp
    from DBA_UNDO_EXTENTS
   where status='UNEXPIRED' group by segment_name
  union
  select segment_name,
         00 act, 00 unexp, nvl(sum(bytes),0) exp
    from DBA_UNDO_EXTENTS
   where status='EXPIRED' group by segment_name
) group by segment_name;

ttitle center "Undo Extents Statistics" skip 2

col size format 999,999,999,999 heading "Size"
col "HOW MANY" format 999,999,999 heading "How Many?"
col st heading a12 heading "Status"

select distinct status st, count(*) "HOW MANY", sum(bytes) "SIZE"
from dba_undo_extents
group by status
/

col segment_name format a30 heading "Name"
col TABLESPACE_NAME for a20
col BYTES for 999,999,999,999
col BLOCKS for 999,999,999
col status for a15 heading "Status"
col segment_name heading "Segment"
col extent_id heading "ID"


select SEGMENT_NAME, TABLESPACE_NAME, EXTENT_ID, 
      FILE_ID, BLOCK_ID, BYTES, BLOCKS, STATUS
from dba_undo_extents
order by 1,3,4,5
/


REM
REM  -----------------------------------------------------------------  
REM 
REM  Undo Extents Contention breakdown
REM  Take out column TUNED_UNDORETENTION if customer 
REM   prior to 10.2.x
REM
REM   The time frame can be adjusted with this query
REM   By default using around 4 hour window of time
REM
REM   Ex.
REM   Using sysdate-.04 looking at the last hour
REM   Using sysdate-.16 looking at the last 4 hours
REM   Using sysdate-.32 looking at the last 8 hours
REM   Using sysdate-1 looking at the last 24 hours
REM

set linesize 140

ttitle center "Undo Extents Error Conditions (Default - Last 4 Hours)" skip 2


col UNXPSTEALCNT format 999,999,999  heading "# Unexpired|Stolen"
col EXPSTEALCNT format 999,999,999   heading "# Expired|Reused"
col SSOLDERRCNT format 999,999,999   heading "ORA-1555|Error"
col NOSPACEERRCNT format 999,999,999 heading "Out-Of-space|Error"
col MAXQUERYLEN format 999,999,999   heading "Max Query|Length"
col TUNED_UNDORETENTION format 999,999,999  heading "Auto-Ajusted|Undo Retention"
col hours format 999,999 heading "Tuned|(HRs)"

select inst_id, to_char(begin_time,'MM/DD/YYYY HH24:MI') begin_time, 
     UNXPSTEALCNT, EXPSTEALCNT , SSOLDERRCNT, NOSPACEERRCNT, MAXQUERYLEN,
     TUNED_UNDORETENTION, TUNED_UNDORETENTION/60/60 hours
from gv$undostat
where begin_time between (sysdate-.16) 
                     and sysdate
order by inst_id, begin_time
/

  
spool off 
set termout on
set trimout off
set trimspool off



spool Undohealth.out  

ttitle off
set pages 999
set lines 150
set verify off 
set termout off
set trimout on
set trimspool on

REM   
REM ------------------------------------------------------------------------  
  
col name format a30  
col gets format 9,999,999  
col waits format 9,999,999  
 
PROMPT  ROLLBACK HIT STATISTICS:  
REM   
  
REM  GETS - # of gets on the rollback segment header 
REM  WAITS - # of waits for the rollback segment header  
  
set head on;  
 
select name, waits, gets  
from   v$rollstat, v$rollname  
where  v$rollstat.usn = v$rollname.usn  
/  
 
col pct head "< 2% ideal"
 
select 'The average of waits/gets is '||  
   round((sum(waits) / sum(gets)) * 100,2)||'%' PCT 
From    v$rollstat  
/  
  

  
PROMPT  REDO CONTENTION STATISTICS:

REM   
REM  If the ratio of waits to gets is more than 1% or 2%, consider  
REM  creating more rollback segments  
REM   
REM  Another way to gauge rollback contention is:  
REM   
  
column xn1 format 9999999  
column xv1 new_value xxv1 noprint  
 

 
select class, count  
from   v$waitstat  
where  class in ('system undo header', 'system undo block', 
                 'undo header',        'undo block'          )  
/  

set head off

select 'Total requests = '||sum(count) xn1, sum(count) xv1  
from    v$waitstat  
/  
 
select 'Contention for system undo header = '||  
       (round(count/(&xxv1+0.00000000001),4)) * 100||'%'  
from  v$waitstat  
where   class = 'system undo header'  
/  
 
select 'Contention for system undo block = '||  
       (round(count/(&xxv1+0.00000000001),4)) * 100||'%'  
from    v$waitstat  
where   class = 'system undo block'  
/  
 
select 'Contention for undo header = '||  
       (round(count/(&xxv1+0.00000000001),4)) * 100||'%'  
from    v$waitstat  
where   class = 'undo header'  
/  
 
select 'Contention for undo block = '||  
       (round(count/(&xxv1+0.00000000001),4)) * 100||'%'  
from    v$waitstat  
where   class = 'undo block'  
/  

REM   
REM  NOTE: Not as useful with AUM configured 
REM 
REM  If the percentage for an area is more than 1% or 2%, consider  
REM  creating more rollback segments.  Note:  This value is usually very  
REM  small 
REM  and has been rounded to 4 places.  
REM   
REM ------------------------------------------------------------------------  
  
REM   
REM  The following shows how often user processes had to wait for space in  
REM  the redo log buffer:  
  
select name||' = '||value  
from   v$sysstat  
where  name = 'redo log space requests'  
/  
 
REM   
REM  This value should be near 0.  If this value increments consistently,  
REM  processes have had to wait for space in the redo buffer.  If this  
REM  condition exists over time, increase the size of LOG_BUFFER in the  
REM  init.ora file in increments of 5% until the value nears 0.  
REM  ** NOTE: increasing the LOG_BUFFER value will increase total SGA size.  
REM   
REM  -----------------------------------------------------------------------  
  
  
col name format a15  
col gets format 9999999  
col misses format 9999999  
col immediate_gets heading 'IMMED GETS' format 9999999  
col immediate_misses heading 'IMMED MISS' format 9999999  
col sleeps format 999999  
 
PROMPT  LATCH CONTENTION:  
REM   
REM  GETS - # of successful willing-to-wait requests for a latch  
REM  MISSES - # of times an initial willing-to-wait request was unsuccessful  
REM  IMMEDIATE_GETS - # of successful immediate requests for each latch  
REM  IMMEDIATE_MISSES = # of unsuccessful immediate requests for each latch  
REM  SLEEPS - # of times a process waited and requests a latch after an  
REM           initial willing-to-wait request  
REM   
REM  If the latch requested with a willing-to-wait request is not  
REM  available, the requesting process waits a short time and requests  
REM  again.  
REM  If the latch requested with an immediate request is not available,  
REM  the requesting process does not wait, but continues processing  
REM   

set head on  
select name,          gets,              misses,  
       immediate_gets,  immediate_misses,  sleeps  
from   v$latch  
where  name in ('redo allocation',  'redo copy')  
/  

set head off 

select 'Ratio of MISSES to GETS: '||  
        round((sum(misses)/(sum(gets)+0.00000000001) * 100),2)||'%'  
from    v$latch  
where   name in ('redo allocation',  'redo copy')  
/  
 

select 'Ratio of IMMEDIATE_MISSES to IMMEDIATE_GETS: '||  
        round((sum(immediate_misses)/  
       (sum(immediate_misses+immediate_gets)+0.00000000001) * 100),2)||'%' 
from    v$latch  
where   name in ('redo allocation',  'redo copy')  
/  
 
set head on
REM   
REM  If either ratio exceeds 1%, performance will be affected.  
REM   
REM  Decreasing the size of LOG_SMALL_ENTRY_MAX_SIZE reduces the number of  
REM  processes copying information on the redo allocation latch.  
REM   
REM  Increasing the size of LOG_SIMULTANEOUS_COPIES will reduce contention  
REM  for redo copy latches.  
  
REM   
REM  -----------------------------------------------------------------  
REM  This looks at overall i/o activity against individual  
REM  files within a tablespace  
REM   
REM  Look for a mismatch across disk drives in terms of I/O  
REM   
REM  Also, examine the Blocks per Read Ratio for heavily accessed  
REM  TSs - if this value is significantly above 1 then you may have  
REM  full tablescans occurring (with multi-block I/O)  
REM   
REM  If activity on the files is unbalanced, move files around to balance  
REM  the load.  Should see an approximately even set of numbers across files  
REM   
  
set space 1  

PROMPT  REPORTING I/O STATISTICS:
 
column pbr       format 99999999  heading 'Physical|Blk Read'  
column pbw       format 999999    heading 'Physical|Blks Wrtn'  
column pyr       format 999999    heading 'Physical|Reads'  
column readtim   format 99999999  heading 'Read|Time'  
column name      format a55       heading 'DataFile Name'  
column writetim  format 99999999  heading 'Write|Time'  
 
compute sum of f.phyblkrd, f.phyblkwrt on report  
 
select fs.name name,  f.phyblkrd pbr,  f.phyblkwrt pbw, 
       f.readtim,     f.writetim  
from   v$filestat f, v$datafile fs  
where  f.file#  =  fs.file#  
order  by fs.name  
/  
 
REM   
REM  -----------------------------------------------------------------  
  
PROMPT  GENERATING WAIT STATISTICS:  
REM   
REM  This will show wait stats for certain kernel instances.  This  
REM  may show the need for additional rbs, wait lists, db_buffers  
REM   
 
column class  heading 'Class Type'  
column count  heading 'Times Waited'  format 99,999,999 
column time   heading 'Total Times'   format 99,999,999  
 
select class,  count,  time  
from   v$waitstat  
where  count > 0  
order  by class  
/  
 
REM   
REM  Look at the wait statistics generated above (if any). They will  
REM  tell you where there is contention in the system.  There will  
REM  usually be some contention in any system - but if the ratio of  
REM  waits for a particular operation starts to rise, you may need to  
REM  add additional resource, such as more database buffers, log buffers,  
REM  or rollback segments  
REM   
REM  -----------------------------------------------------------------  
  
PROMPT  ROLLBACK EXTENT STATISTICS:  
REM   


 
column usn        format 999          heading 'Undo #'
column extents    format 999          heading 'Extents'  
column rssize     format 999,999,999  heading 'Size in|Bytes'  
column optsize    format 999,999,999  heading 'Optimal|Size'  
column hwmsize    format 99,999,999   heading 'High Water|Mark'  
column shrinks    format 9,999        heading 'Num of|Shrinks'  
column wraps      format 9,999        heading 'Num of|Wraps'  
column extends    format 999,999      heading 'Num of|Extends'  
column aveactive  format 999,999,999  heading 'Average size|Active Extents'  
column rownum noprint  
 
select usn, extents, rssize,    optsize,  hwmsize,  
       shrinks,   wraps,    extends,  aveactive  
from   v$rollstat  
order  by rownum  
/  



spool off 
set termout on
set trimout off
set trimspool off




spool UndoConfig.out  

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
  
set space 2  

REM  REPORTING TABLESPACE INFORMATION: 
REM   
REM  This looks at Tablespace Sizing - Total bytes and free bytes  
REM   
 
column tablespace_name  format a30            heading 'TS Name'  
column sbytes           format 9,999,999,999  heading 'Total Bytes'  
column fbytes           format 9,999,999,999  heading 'Free Bytes'  
column kount            format 999            heading 'Ext'  
 
compute sum of fbytes on tablespace_name  
compute sum of sbytes on tablespace_name  
compute sum of sbytes on report  
compute sum of fbytes on report  
 
break on tablespace_name skip 2  
 
select a.tablespace_name,    round(a.bytes/1024/1024,0) sbytes,  
       round(sum(b.bytes/1024/1024),0) fbytes,  count(*) kount, autoextensible  
from   dba_data_files a,  dba_free_space b  
where  a.file_id  =  b.file_id  
and a.tablespace_name in (select z.tablespace_name from dba_tablespaces z where retention like '%GUARANTEE')
group  by a.tablespace_name, a.bytes, autoextensible
order  by a.tablespace_name  
/  
 
set linesize 160  
 
 
REM   
REM  If you can significantly reduce physical reads by adding incremental  
REM  data buffers...do it.  To determine whether adding data buffers will  
REM  help, set db_block_lru_statistics = TRUE and  
REM  db_block_lru_extended_statistics = TRUE in the init.ora parameters.  
REM  You can determine how many extra hits you would get from memory as  
REM  opposed to physical I/O from disk.  **NOTE:  Turning these on will  
REM  impact performance.  One shift of statistics gathering should be enough  
REM  to get the required information.  
REM   
  

REM   
REM  -----------------------------------------------------------------  
REM

set lines 160

col tablespace_name format a30 heading "Tablespace"
col tb format a15 heading "TB Status"
col df format a10 heading "DF Status"
col extent_management format a15 heading "Extent|Management"
col allocation_type format a8 heading "Type"
col segment_space_management format a7 heading "Auto|Segment"
col retention format a11 heading "Retention|Level"
col autoextensible format a5 heading "Auto?"
col mx format 999,999,999 heading "Max Allowed"

select t.tablespace_name, t.status tb, d.status df,
extent_management, allocation_type, segment_space_management, retention,
autoextensible, (maxbytes/1024/1024) mx
from dba_tablespaces t, dba_data_files d
where t.tablespace_name = d.tablespace_name
and retention like '%GUARANTEE'
/


col status format a20 head "Status"
col cnt format 999,999,999 head "How Many?"

select status, count(*) cnt
from dba_rollback_segs
group by status
/


  
spool off 

set termout on
set trimout off
set trimspool off


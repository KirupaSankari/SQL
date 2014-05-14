PROMPT ################# Undo Usage By Status and Size #################

col tablespace_name format a20
select tablespace_name, status,round(sum (bytes)/1024/1024,2) "UNDO in (MB)" from DBA_UNDO_EXTENTS group by tablespace_name,status order by status;


PROMPT ################# Undo Usage By Object #################

set feedback off
Set lines 500 pages 999
col "OS_User" format a10
col "DB_User" format a10
col  Schema  format a10
col Object_Name format a25
col type for a10
col Records for a10
col RBS format a15
col TABLESPACE_NAME format a10
select substr(a.os_user_name,1,15)    "OS_User"
, substr(a.oracle_username,1,8) "DB_User"
, substr(b.owner,1,8)  "Schema"
, substr(b.object_name,1,30)    "Object_Name"
, substr(b.object_type,1,10)    "Type"
, substr(c.segment_name,1,15)  "RBS"
,TABLESPACE_NAME
, substr(d.used_urec,1,12)      "Records" ,
e.sid,e.serial#
from gv$locked_object      a
, dba_objects b
, dba_rollback_segs  c
, gv$transaction      d
, gv$session e
where   a.object_id =  b.object_id
and a.xidusn    =  c.segment_id
and a.xidusn    =  d.xidusn
and a.xidslot   =  d.xidslot
and d.addr      =  e.taddr;

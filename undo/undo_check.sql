Set lines 500 pages 999
set feedback off echo off
PROMPT ################# Undo Tablespace status #################
col tablespace_name for a16

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
where t.tablespace_name = f.tablespace_name (+) and t.tablespace_name like'UNDO%'
order by t.tablespace_name;


PROMPT ################# Undo Usage By Status and Size #################

col tablespace_name format a20
select tablespace_name, status,round(sum (bytes)/1024/1024/1024,2) "UNDO in (GB)" from DBA_UNDO_EXTENTS group by tablespace_name,status order by status;


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


PROMPT ################# Undo Usage By Session #################

Col machine format a20
col osuser format a10
select sid, serial#, osuser, to_char(a.logon_time,'dd/mm/yy hh24:mm:ss'), a.status, machine, USED_UBLK,
round(USED_UBLK*8192/1024/1024,2) UNDO_USAGE_MB
from gv$session a, gv$transaction b
where b.addr = a.taddr;

exit;


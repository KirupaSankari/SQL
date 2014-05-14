set lines 160 pages 100
undef event 
col object_name format A32
col object_type format A20
col event format A30
col owner format A20
col cnt format 999999999
set echo on
undef past_mins
with ash_gc as 
(select * from (
select /*+ materialize */ inst_id, event, current_obj#, count(*) cnt 
from gv$active_session_history where event like '%'||lower('&event') ||'%'
and sample_time> sysdate- (&past_mins/24/60)
group by inst_id,event, current_obj#
))
select * from (
select inst_id,event, owner, object_name,object_type, cnt 
from ash_gc a, dba_objects o
where (a.current_obj#=o.data_object_id or a.current_obj#=o.object_id)
and a.current_obj#>=1
union 
select inst_id, event, '','','Undo Header/Undo block' , cnt 
from ash_gc a
where a.current_obj#=0
union
select inst_id, event, '','','Undo Block' , cnt 
from ash_gc a
where a.current_obj#=-1
) order by 5
/
set echo off

set lines 100 pages 100
undef event 
col object_name format A32
col object_type format A20
col owner format A20
col cnt format 999999999
with ash_gc as 
(select * from (
select /*+ materialize */ inst_id, event, current_file#, current_block#, count(*) cnt 
from gv$active_session_history where event like '%'||lower('&event') ||'%'
and sample_time> sysdate- (&past_mins/24/60)
group by inst_id,event, current_file#, current_block#
))
select * from ash_gc  order by cnt desc
/

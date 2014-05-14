 select round(sum(bytes)/1024/1024,2) "size (mb)", segment_name,segment_type,owner,tablespace_name from dba_segments
 where segment_name=upper('&1')
 group by segment_name,segment_type,owner, tablespace_name
/

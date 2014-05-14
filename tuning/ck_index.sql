SET VERIFY OFF
TTITLE "Information about the table &1"
SET LINES 160
SET PAGES 60
COL owner FORMAT a15
COL table_owner FORMAT a15
COL index_name FORMAT a30
COL index_type FORMAT A15
COL column_name FORMAT a30
COL object_name FORMAT a30
COL degree for a7
COL status for a12
col clustering_factor for 99999999999
COL blevel for 999

select owner,object_name,object_type, last_ddl_time, created
from dba_objects
where object_name=upper('&1') and object_type<>'SYNONYM';


select owner,num_rows,partitioned,last_analyzed,degree,avg_row_len,num_rows,tablespace_name
from dba_tables
where table_name=upper('&1');

TTITLE "Information about the indexes of table &1"

select table_owner,index_name,index_type,partitioned,uniqueness,partitioned,blevel,distinct_keys,num_rows,status,last_analyzed,degree,clustering_factor
from dba_indexes
where table_name=upper('&1');

TTITLE OFF

select table_owner,index_name,column_position||'. '||column_name column_name
from dba_ind_columns
where table_name=upper('&1')
order by index_name,column_position;

CLEAR COLUMNS
SET VERIFY ON

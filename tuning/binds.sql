select a.SQL_ID,NAME,VALUE_STRING
FROM V$SQL_BIND_CAPTURE a
where a.sql_id='&sql_id'
/


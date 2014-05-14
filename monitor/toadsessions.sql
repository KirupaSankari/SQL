set line 160
set pages 100
col osuser for a16
col machine for a25
col username for a18
col program for a15 trunc
col status for a5 trunc
select inst_id,sid,serial#, round(last_call_et/60/60,2) "Idle|hrs" , osuser,machine, username, program,sql_hash_value,status  from gv$session where upper(program) in ('SQL DEVELOPER','TOAD.EXE') order by 4 desc
/

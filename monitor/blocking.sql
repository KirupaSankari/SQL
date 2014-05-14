select s1.username || '@' || s1.machine
 || ' ( SID=' || s1.sid || ' )  is blocking '
 || s2.username || '@' || s2.machine || ' ( SID=' || s2.sid || ' ) '||s1.last_call_et||','||s2.last_call_et || ' '|| s1.sql_id ||' '||s1.module     as blocking_status
 from v$lock l1, v$session s1, v$lock l2, v$session s2
 where s1.sid=l1.sid and s2.sid=l2.sid
 and l1.BLOCK=1 and l2.request > 0
 and l1.id1 = l2.id1
 and l2.id2 = l2.id2
order by s1.last_call_et
/

set lines 160 pages 100
break on report
compute sum of degree on report
col username for a12 trunc
select distinct s.inst_id,s.sid,s.serial#,s.osuser,s.username,s.machine,s.module, P.DEGREE, s.logon_time, s.last_call_et from gv$session s,gv$px_session p
where
s.inst_id=p.qcinst_id
and s.sid=p.qcsid
and s.serial#=p.qcserial#
order by degree
/

select start_time, username, r.name,
ubafil, ubablk, t.status, (used_ublk*p.value)/1024 blk, used_urec
from v$transaction t, v$rollname r, v$session s, v$parameter p
where xidusn=usn
and s.saddr=t.ses_addr
and p.name='db_block_size'
order by 1
/

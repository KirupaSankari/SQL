select inst_id, to_char(begin_time,'MM/DD/YYYY HH24:MI') begin_time, UNXPSTEALCNT, EXPSTEALCNT , SSOLDERRCNT, NOSPACEERRCNT, MAXQUERYLEN
from gv$undostat
where begin_time between sysdate-1
                     and sysdate
order by inst_id, begin_time
/

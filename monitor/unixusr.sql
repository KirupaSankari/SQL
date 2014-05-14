rem -----------------------------------------------------------------------
rem Filename:   unixusr.sql
rem Purpose:    Lookup database details for a given Unix process id
rem -----------------------------------------------------------------------

set serveroutput on size 50000
set echo off feed off veri off
accept 1 prompt 'Enter Unix process id: '

DECLARE
  v_sid number;
  s sys.v_$session%ROWTYPE;
  p sys.v_$process%ROWTYPE;
BEGIN
  begin
    select sid into v_sid
    from   sys.v_$process p, sys.v_$session s
    where  p.addr     = s.paddr
      and  (p.spid    = &&1
       or   s.process = '&&1');
  exception
    when no_data_found then
      dbms_output.put_line('Unable to find process id &&1!!!');
      return;
    when others then
      dbms_output.put_line(sqlerrm);
      return;
  end;

  select * into s from sys.v_$session where sid  = v_sid;
  select * into p from sys.v_$process where addr = s.paddr;

  dbms_output.put_line('=====================================================================');
  dbms_output.put_line('SID/Serial  : '|| s.sid||','||s.serial#);
  dbms_output.put_line('Foreground  : '|| 'PID: '||s.process||' - '||s.program);
  dbms_output.put_line('Shadow      : '|| 'PID: '||p.spid||' - '||p.program);
  dbms_output.put_line('Terminal    : '|| s.terminal || '/ ' || p.terminal);
  dbms_output.put_line('OS User     : '|| s.osuser||' on '||s.machine);
  dbms_output.put_line('Ora User    : '|| s.username);
  dbms_output.put_line('Status Flags: '|| s.status||' '||s.server||' '||s.type);
  dbms_output.put_line('Tran Active : '|| nvl(s.taddr, 'NONE'));
  dbms_output.put_line('Login Time  : '|| to_char(s.logon_time, 'Dy HH24:MI:SS'));
  dbms_output.put_line('Last Call   : '|| to_char(sysdate-(s.last_call_et/60/60/24), 'Dy HH24:MI:SS') || ' - ' || to_char(s.last_call_et/60, '990.0') || ' min');
  dbms_output.put_line('Lock/ Latch : '|| nvl(s.lockwait, 'NONE')||'/ '||nvl(p.latchwait, 'NONE'));
  dbms_output.put_line('Latch Spin  : '|| nvl(p.latchspin, 'NONE'));
/*
  dbms_output.put_line('Current SQL statement:');
  for c1 in ( select * from sys.v_$sqltext
              where HASH_VALUE = s.sql_hash_value order by piece) loop
    dbms_output.put_line(chr(9)||c1.sql_text);
  end loop;

  dbms_output.put_line('Previous SQL statement:');
  for c1 in ( select * from sys.v_$sqltext
              where HASH_VALUE = s.prev_hash_value order by piece) loop
    dbms_output.put_line(chr(9)||c1.sql_text);
  end loop;
*/
  dbms_output.put_line('Session Waits:');
  for c1 in ( select * from sys.v_$session_wait where sid = s.sid) loop
    dbms_output.put_line(chr(9)||c1.state||': '||c1.event);
  end loop;

--  dbms_output.put_line('Connect Info:');
--  for c1 in ( select * from sys.v_$session_connect_info where sid = s.sid) loop
--    dbms_output.put_line(chr(9)||': '||c1.network_service_banner);
--  end loop;
/*
  dbms_output.put_line('Locks:');
  for c1 in ( select
          decode(l.type,
          -- Long locks
                      'TM', 'DML/DATA ENQ',   'TX', 'TRANSAC ENQ',
                      'UL', 'PLS USR LOCK',
          -- Short locks
                      'BL', 'BUF HASH TBL',  'CF', 'CONTROL FILE',
                      'CI', 'CROSS INST F',  'DF', 'DATA FILE   ',
                      'CU', 'CURSOR BIND ',
                      'DL', 'DIRECT LOAD ',  'DM', 'MOUNT/STRTUP',
                      'DR', 'RECO LOCK   ',  'DX', 'DISTRIB TRAN',
                      'FS', 'FILE SET    ',  'IN', 'INSTANCE NUM',
                      'FI', 'SGA OPN FILE',
                      'IR', 'INSTCE RECVR',  'IS', 'GET STATE   ',
                      'IV', 'LIBCACHE INV',  'KK', 'LOG SW KICK ',
                      'LS', 'LOG SWITCH  ',
                      'MM', 'MOUNT DEF   ',  'MR', 'MEDIA RECVRY',
                      'PF', 'PWFILE ENQ  ',  'PR', 'PROCESS STRT',
                      'RT', 'REDO THREAD ',  'SC', 'SCN ENQ     ',
                      'RW', 'ROW WAIT    ',
                      'SM', 'SMON LOCK   ',  'SN', 'SEQNO INSTCE',
                      'SQ', 'SEQNO ENQ   ',  'ST', 'SPACE TRANSC',
                      'SV', 'SEQNO VALUE ',  'TA', 'GENERIC ENQ ',
                      'TD', 'DLL ENQ     ',  'TE', 'EXTEND SEG  ',
                      'TS', 'TEMP SEGMENT',  'TT', 'TEMP TABLE  ',
                      'UN', 'USER NAME   ',  'WL', 'WRITE REDO  ',
                      'TYPE='||l.type) type,
       decode(l.lmode, 0, 'NONE', 1, 'NULL', 2, 'RS', 3, 'RX',
                       4, 'S',    5, 'RSX',  6, 'X',
                       to_char(l.lmode) ) lmode,
       decode(l.request, 0, 'NONE', 1, 'NULL', 2, 'RS', 3, 'RX',
                         4, 'S', 5, 'RSX', 6, 'X',
                         to_char(l.request) ) lrequest,
       decode(l.type, 'MR', o.name,
                      'TD', o.name,
                      'TM', o.name,
                      'RW', 'FILE#='||substr(l.id1,1,3)||
                            ' BLOCK#='||substr(l.id1,4,5)||' ROW='||l.id2,
                      'TX', 'RS+SLOT#'||l.id1||' WRP#'||l.id2,
                      'WL', 'REDO LOG FILE#='||l.id1,
                      'RT', 'THREAD='||l.id1,
                      'TS', decode(l.id2, 0, 'ENQUEUE', 'NEW BLOCK ALLOCATION'),
                      'ID1='||l.id1||' ID2='||l.id2) objname
       from  sys.v_$lock l, sys.obj$ o
       where sid   = s.sid
         and l.id1 = o.obj#(+) ) loop
    dbms_output.put_line(chr(9)||c1.type||' H: '||c1.lmode||' R: '||c1.lrequest||' - '||c1.objname);
  end loop;
*/

  dbms_output.put_line('=====================================================================');

END;
/

undef 1

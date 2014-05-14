set line 160 verify off feedback off
col username for a30
col account_status for a15 heading "Status" trunc
select username,account_status,profile,created,default_tablespace,temporary_tablespace from dba_users where username=upper('&1')
/
undefine 1

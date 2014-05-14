set linesize   160
set pagesize  1000
set trimout     on
set trimspool   on
Set Feedback   off
set timing     off
set verify     off


prompt

prompt -- ----------------------------------------------------------------------- ---

prompt --   List of oracle's processes                                            ---

prompt -- ----------------------------------------------------------------------- ---

prompt


column username     heading "Username."           			format A10
column commande     heading "command"        				format A13
column status       heading "stat"            				format A4
column logon        heading "Date|Connect"			  	format A14
column command      heading "C"               				format 99
column sid          heading "Id"            				format 99999
column serial       heading "Serial#"        				format 99999
column spid         heading "Unix"           	 			format A7
column terminal     heading "Terminal"       				format A11
column lockwait     heading "Lockwait"       				format A8
column program      heading "Program"      				format A20   word_wrapped
column nb_sess      heading "Nb. Sess."       				format 99999
column last_call_et heading "Last|Call"		 		      format A9
column event heading "Ev"   format a16 trunc

select 
       s.sid
     , s.serial# serial
     , p.spid
     , substr(s.username,1,8) username
     , s.terminal
     , s.command
     , decode(s.command, 1,'Create table'          , 2,'Insert'
                       , 3,'Select'                , 6,'Update'
                       , 7,'Delete'                , 9,'Create index'
                       ,10,'Drop index'            ,11,'Alter index'
                       ,12,'Drop table'            ,13,'Create seq'
                       ,14,'Alter sequence'        ,15,'Alter table'
                       ,16,'Drop sequ.'            ,17,'Grant'
                       ,19,'Create syn.'           ,20,'Drop syn.'
                       ,21,'Create view'           ,22,'Drop view'
                       ,23,'Validate index'        ,24,'create proced.'
                       ,25,'Alter procedure'       ,26,'Lock table'   
                       ,42,'Alter session'         ,44,'Commit'
                       ,45,'Rollback'              ,46,'Savepoint'
                       ,47,'PL/SQL Exec'           ,48,'Set Transaction'
                       ,60,'Alter trigger'         ,62,'Analyse Table'
                       ,63,'Analyse index'         ,71,'Create Snapshot Log'
                       ,72,'Alter Snapshot Log'    ,73,'Drop Snapshot Log'
                       ,74,'Create Snapshot'       ,75,'Alter Snapshot'
                       ,76,'drop Snapshot'         ,85,'Truncate table'
                       , 0,'No command', '? : '||s.command) commande
       , to_char(s.logon_time,'DD-MM-YY HH24:MI') logon
       , substr(s.status,1,4) status
       , floor(s.last_call_et/3600)||':'||
         floor(mod(s.last_call_et,3600)/60)||':'||
         mod(mod(s.last_call_et,3600),60)  			last_call_et
       , s.lockwait
	 , Substr(s.program,1,20) program, sw.event , s.sql_id 
  from 
       v$session s
     , v$process p
     , v$session_wait sw 
 where  
       s.paddr  =  p.addr
and    sw.sid  = s.sid
and	s.username is not null
and s.status like upper('&1%')
 order 
     by s.status desc
      , s.last_call_et desc
	, P.spid
;


Prompt

prompt

prompt -- ----------------------------------------------------------------------- ---

prompt --   Active / Inactive Sessions                                            ---

prompt -- ----------------------------------------------------------------------- ---


Set Heading  Off 

Column Status   heading "Status"         format A50

Select 
       '--  Time : '||Time||' - Process : '||Proc||' - Session '||Sess			Status
 From
       ( Select To_Char(Sysdate, 'HH24:MI') 	Time
         From Dual
       ) 
     , ( Select Count(*)				Proc
         From V$Process
       )
     , ( Select Count(*) 				Sess
         From V$Session
        )
;


Set Heading On

Prompt

column status     heading "Status"            format A10


Select 
	 Initcap(S.Status)	status
     , Count(*)			nb_sess
  From
       V$Session S
 Group 
    By Initcap(S.Status)
;



Prompt

prompt

prompt -- ----------------------------------------------------------------------- ---

prompt --   Active / Sessions In Progress ...                                     ---

prompt -- ----------------------------------------------------------------------- ---



column pct       heading "Pro.|(%)"       	format 9999
column username  heading "UserNm"        	format A8
column machine   heading "Machine"        	format A12
column program   heading "Program"        	format A12
column modu      heading "Module"         	format A15
column sql       heading "Sql"            	format A60 word_wrapped
column Sta_Time  heading "Start|Time"           format A18
column LUTime    heading "Last|Update|Time"     format A18
column Time_Left heading "Time|Left"         	format A10

Select 
       sn.sid
     , substr(sn.username,1,8) 		username
     , Trunc(sl.sofar/sl.totalwork * 100) pct
     , sn.machine					machine
     , sn.program 				program			
     , sn.module					modu
     , to_char(start_time,'DD-MON-YY HH:MI:SS') 	Sta_Time
     , to_char(last_update_time,'DD-MON-YY HH:MI:SS') LUTime
     , To_Char(To_Date(TIME_REMAINING,'SSSSS'),'HH24:MI:SS') Time_Left
  From
       v$session_longops sl
     , v$session sn
 where
       sn.status = 'ACTIVE'
   and 
       sl.sid = sn.sid
   and 
       sl.sofar       != sl.totalwork
;



-- Select 
--        substr(sn.username,1,8) 		username
--      , Trunc(sl.sofar/sl.totalwork * 100) pct
--      , sn.machine					machine
--      , sn.program 				program			
--      , sn.module					modu
--      , sa.sql_text 				sql
--   From
--        v$session_longops sl
--      , v$session sn
--      , v$sqlarea sa
--  where
--        sn.status = 'ACTIVE'
--    and 
--        sl.sid = sn.sid
--    and 
--        sn.sql_address = sa.address (+)
--    and 
--        sl.sofar       != sl.totalwork
-- ;


Prompt

Prompt


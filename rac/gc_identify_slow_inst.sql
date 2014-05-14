set serveroutput on size 100000
REM --------------------------------------------------------------------------------------------------
REM Author: Riyaj Shamsudeen @OraInternals, LLC
REM         www.orainternals.com
REM
REM Functionality: This script is to print GC processing timing for the past N seconds or so
REM **************
REM   
REM Source  : gv$sysstat
REM
REM Note : 1. Keep window 160 columns for better visibility.
REM
REM Exectution type: Execute from sqlplus or any other tool.  Modify sleep as needed. Default is 60 seconds
REM
REM Parameters: 
REM No implied or explicit warranty
REM
REM Please send me an email to rshamsud@orainternals.com for any question..
REM  NOTE   1. Querying gv$ tables when there is a GC performance issue is not exactly nice. So, don't run this too often.
REM         2. Until 11g, gv statistics did not include PQ traffic.
REM         3. Of course, this does not tell any thing about root cause :-)
REM @copyright : OraInternals, LLC. www.orainternals.com
REM Version	Change
REM ----------	--------------------
REM --------------------------------------------------------------------------------------------------
PROMPT
PROMPT
PROMPT  gc_instance_cache.sql v1.10 by Riyaj Shamsudeen @orainternals.com
PROMPT
PROMPT  ...Prints various timing related information for the past N seconds
PROMPT  ...Default collection period is 60 seconds.... Please wait for at least 60 seconds...
PROMPT
PROMPT Column name key:
PROMPT   Inst -> Inst class :  source and target instance and class of the block transfer
PROMPT   CR blk TX  :  CR blocks transmitted
PROMPT   CR blk tm  :  CR blocks time taken
PROMPT   CR blk av  :  Average time taken for CR block
PROMPT   CR bsy     :  Count of blocks suffered from "busy" events
PROMPT   CR bsy tm  :  Amount of time taken due to "busy" waits
PROMPT   CR bsy %   :  Percentage of CR busy time to CR time
PROMPT   CR congest :  Count of blocks suffered from "congestion" events
PROMPT   CR cngsttm :  Amount of time taken due to "congestion" waits
PROMPT   CR cng %   :  Percentage of CR congestion time to CR time
undef sleep
set lines 170 pages 100
set verify off

declare
	type number_table   is table of number       index by varchar2(32);
	type varchar2_table   is table of varchar2(32)       index by varchar2(32);

        key_table varchar2_table;

	b_inst_id  number_table;
	b_instance number_table;
	b_class varchar2_table;
	b_lost number_table;
	b_lost_time number_table;
	b_CR_BLOCK                                                                   number_table;
	b_CR_BLOCK_TIME                                                              number_table;
	b_CR_2HOP                                                                    number_table;
	b_CR_2HOP_TIME                                                               number_table;
	b_CR_3HOP                                                                    number_table;
	b_CR_3HOP_TIME                                                               number_table;
	b_CR_BUSY                                                                    number_table;
	b_CR_BUSY_TIME                                                               number_table;
	b_CR_CONGESTED                                                               number_table;
	b_CR_CONGESTED_TIME                                                          number_table;
	b_CURRENT_BLOCK                                                              number_table;
	b_CURRENT_BLOCK_TIME                                                         number_table;
	b_CURRENT_2HOP                                                               number_table;
	b_CURRENT_2HOP_TIME                                                          number_table;
	b_CURRENT_3HOP                                                               number_table;
	b_CURRENT_3HOP_TIME                                                          number_table;
	b_CURRENT_BUSY                                                               number_table;
	b_CURRENT_BUSY_TIME                                                          number_table;
	b_CURRENT_CONGESTED                                                          number_table;
	b_CURRENT_CONGESTED_TIME                                                     number_table;

	e_inst_id  number_table;
	e_instance number_table;
	e_class varchar2_table;
	e_lost number_table;
	e_lost_time number_table;
	e_CR_BLOCK                                                                   number_table;
	e_CR_BLOCK_TIME                                                              number_table;
	e_CR_2HOP                                                                    number_table;
	e_CR_2HOP_TIME                                                               number_table;
	e_CR_3HOP                                                                    number_table;
	e_CR_3HOP_TIME                                                               number_table;
	e_CR_BUSY                                                                    number_table;
	e_CR_BUSY_TIME                                                               number_table;
	e_CR_CONGESTED                                                               number_table;
	e_CR_CONGESTED_TIME                                                          number_table;
	e_CURRENT_BLOCK                                                              number_table;
	e_CURRENT_BLOCK_TIME                                                         number_table;
	e_CURRENT_2HOP                                                               number_table;
	e_CURRENT_2HOP_TIME                                                          number_table;
	e_CURRENT_3HOP                                                               number_table;
	e_CURRENT_3HOP_TIME                                                          number_table;
	e_CURRENT_BUSY                                                               number_table;
	e_CURRENT_BUSY_TIME                                                          number_table;
	e_CURRENT_CONGESTED                                                          number_table;
	e_CURRENT_CONGESTED_TIME                                                     number_table;

	v_ver number;
	l_sleep number:=60;
	l_cr_blks_served number :=0;
	l_cur_blks_served number :=0;
	
	i number:=1;
	ind varchar2(32);
begin
	for c1 in ( select instance ||','|| inst_id || ',' || class indx, ic.* from  gv$instance_cache_transfer ic where cr_block >0)
        loop
		key_table(i):= c1.indx;
		b_inst_id (c1.indx) := c1.inst_id;
		b_instance (c1.indx) := c1.instance;
		b_class (c1.indx) := c1.class;
		b_lost (c1.indx) := c1.lost;
		b_lost_time (c1.indx) := c1.lost_time;
		b_CR_BLOCK  (c1.indx) := c1.cr_block;
		b_CR_BLOCK_TIME (c1.indx) := c1.cr_block_time;
		b_CR_2HOP   (c1.indx) := c1.cr_2hop;
		b_CR_2HOP_TIME (c1.indx) := c1.cr_2hop_time;
		b_CR_3HOP  (c1.indx) := c1.cr_3hop;  
		b_CR_3HOP_TIME (c1.indx) := c1.cr_3hop_time;
		b_CR_BUSY  (c1.indx) := c1.cr_busy;
		b_CR_BUSY_TIME  (c1.indx) := c1.cr_busy_time;
		b_CR_CONGESTED  (c1.indx) := c1.cr_congested;
		b_CR_CONGESTED_TIME (c1.indx) := c1.cr_congested_time;
		b_CURRENT_BLOCK    (c1.indx) := c1.current_block;
		b_CURRENT_BLOCK_TIME (c1.indx) := c1.current_block_time;
		b_CURRENT_2HOP     (c1.indx) := c1.current_2hop;
		b_CURRENT_2HOP_TIME (c1.indx) := c1.current_2hop_time;
		b_CURRENT_3HOP  (c1.indx) := c1.current_3hop;
		b_CURRENT_3HOP_TIME  (c1.indx) := c1.current_3hop_time;
		b_CURRENT_BUSY     (c1.indx) := c1.current_busy; 
		b_CURRENT_BUSY_TIME (c1.indx) := c1.current_busy_time;
		b_CURRENT_CONGESTED (c1.indx) := c1.current_congested;
		b_CURRENT_CONGESTED_TIME (c1.indx) := c1.current_congested_time;
		i := i+1;
	end loop;
 
          select upper(nvl('&sleep',60)) into l_sleep from dual;
	  dbms_lock.sleep(l_sleep);

	for c1 in ( select instance ||','|| inst_id || ',' || class indx, ic.* from  gv$instance_cache_transfer ic where cr_block >0)
        loop
		e_inst_id (c1.indx) := c1.inst_id;
		e_instance (c1.indx) := c1.instance;
		e_class (c1.indx) := c1.class;
		e_lost (c1.indx) := c1.lost;
		e_lost_time (c1.indx) := c1.lost_time;
		e_CR_BLOCK  (c1.indx) := c1.cr_block;
		e_CR_BLOCK_TIME (c1.indx) := c1.cr_block_time;
		e_CR_2HOP   (c1.indx) := c1.cr_2hop;
		e_CR_2HOP_TIME (c1.indx) := c1.cr_2hop_time;
		e_CR_3HOP  (c1.indx) := c1.cr_3hop;  
		e_CR_3HOP_TIME (c1.indx) := c1.cr_3hop_time;
		e_CR_BUSY  (c1.indx) := c1.cr_busy;
		e_CR_BUSY_TIME  (c1.indx) := c1.cr_busy_time;
		e_CR_CONGESTED  (c1.indx) := c1.cr_congested;
		e_CR_CONGESTED_TIME (c1.indx) := c1.cr_congested_time;
		e_CURRENT_BLOCK    (c1.indx) := c1.current_block;
		e_CURRENT_BLOCK_TIME (c1.indx) := c1.current_block_time;
		e_CURRENT_2HOP     (c1.indx) := c1.current_2hop;
		e_CURRENT_2HOP_TIME (c1.indx) := c1.current_2hop_time;
		e_CURRENT_3HOP  (c1.indx) := c1.current_3hop;
		e_CURRENT_3HOP_TIME  (c1.indx) := c1.current_3hop_time;
		e_CURRENT_BUSY     (c1.indx) := c1.current_busy; 
		e_CURRENT_BUSY_TIME (c1.indx) := c1.current_busy_time;
		e_CURRENT_CONGESTED (c1.indx) := c1.current_congested;
		e_CURRENT_CONGESTED_TIME (c1.indx) := c1.current_congested_time;
	end loop;
	dbms_output.put_line ( '----------------------|-----------|-----------|-----------|-----------|-----------|-----------|-----------|-----------|-----------|');
	dbms_output.put_line ( 'Inst->Inst class      | CR blk Tx |CR blk tm  | CR blk av | CR 2hop   | CR2hop tm | CR 2hop   | CR 3hop   |CR 3hop  tm|CR 3hop av |');
	dbms_output.put_line ( '----------------------|-----------|-----------|-----------|-----------|-----------|-----------|-----------|-----------|-----------|');
	for i in key_table.first .. key_table.last
         loop
	  ind :=  key_table (i);
	  if ( e_cr_block (ind) - b_cr_block(ind) >0) then
	  dbms_output.put_line ( rpad( e_instance(ind) ||'->'|| e_inst_id(ind)||' '||e_class (ind), 22 )  || '|' ||
				 lpad(to_char(e_cr_block (ind) - b_cr_block(ind)),11)  || '|'||
				 lpad(to_char(e_cr_block_time (ind) - b_cr_block_time(ind)),11)  || '|'||
				 lpad(to_char(case when e_cr_block(ind) - b_cr_block(ind)=0 then 0
						else trunc ((e_cr_block_time (ind) - b_cr_block_time(ind))/(e_cr_block(ind) - b_cr_block(ind))/1000,2)
						end
					      ),11)   ||'|'||
				 lpad(to_char(e_cr_2hop (ind) - b_cr_2hop(ind)),11)  || '|'||
				 lpad(to_char(e_cr_2hop_time (ind) - b_cr_2hop_time(ind)),11)  || '|'||
				 lpad(to_char(case when e_cr_2hop(ind) - b_cr_2hop(ind)=0 then 0
						else trunc ((e_cr_2hop_time (ind) - b_cr_2hop_time(ind))/(e_cr_2hop(ind) - b_cr_2hop(ind))/1000,2)
						end
					      ),11)   ||'|'||
				 lpad(to_char(e_current_3hop (ind) - b_current_3hop(ind)),11)  || '|'||
				 lpad(to_char(e_current_3hop_time (ind) - b_current_3hop_time(ind)),11)  || '|'||
				 lpad(to_char(case when e_current_3hop(ind) - b_current_3hop(ind)=0 then 0
						else trunc ((e_current_3hop_time (ind) - b_current_3hop_time(ind))/(e_current_3hop(ind) - b_current_3hop(ind))/1000,2)
						end
					      ),11)   
                                );
	 end if;
	 end loop;
	 dbms_output.put_line ( '---------------------------------------------------------------------------------------------------------------------------------');
	 dbms_output.put_line ( ' ');
	dbms_output.put_line ( '----------------------|-----------|-----------|-----------|-----------|-----------|-----------|-----------|-----------|-----------|');
	dbms_output.put_line ( 'Inst->Inst class      | CUR blk Tx|CUR blk tm | CUR blk av| CUR 2hop  | CUR2hop tm| CUR 2hop  | CUR 3hop  |CUR 3hop tm|CUR 3hop av|');
	dbms_output.put_line ( '----------------------|-----------|-----------|-----------|-----------|-----------|-----------|-----------|-----------|-----------|');
	for i in key_table.first .. key_table.last
         loop
	  ind :=  key_table (i);
	  if ( e_current_block (ind) - b_current_block(ind) >0) then
	  dbms_output.put_line ( rpad( e_instance(ind) ||'->'|| e_inst_id(ind)||' '||e_class (ind), 22 )  || '|' ||
				 lpad(to_char(e_current_block (ind) - b_current_block(ind)),11)  || '|'||
				 lpad(to_char(e_current_block_time (ind) - b_current_block_time(ind)),11)  || '|'||
				 lpad(to_char(case when e_current_block(ind) - b_current_block(ind)=0 then 0
						else trunc ((e_current_block_time (ind) - b_current_block_time(ind))/(e_current_block(ind) - b_current_block(ind))/1000,2)
						end
					      ),11)   ||'|'||
				 lpad(to_char(e_current_2hop (ind) - b_current_2hop(ind)),11)  || '|'||
				 lpad(to_char(e_current_2hop_time (ind) - b_current_2hop_time(ind)),11)  || '|'||
				 lpad(to_char(case when e_current_2hop(ind) - b_current_2hop(ind)=0 then 0
						else trunc ((e_current_2hop_time (ind) - b_current_2hop_time(ind))/(e_current_2hop(ind) - b_current_2hop(ind))/1000,2)
						end
					      ),11)   ||'|'||
				 lpad(to_char(e_current_3hop (ind) - b_current_3hop(ind)),11)  || '|'||
				 lpad(to_char(e_current_3hop_time (ind) - b_current_3hop_time(ind)),11)  || '|'||
				 lpad(to_char(case when e_current_3hop(ind) - b_current_3hop(ind)=0 then 0
						else trunc ((e_current_3hop_time (ind) - b_current_3hop_time(ind))/(e_current_3hop(ind) - b_current_3hop(ind))/1000,2)
						end
					      ),11)   
                                );
	 end if;
	 end loop;
	 dbms_output.put_line ( '---------------------------------------------------------------------------------------------------------------------------------');
	dbms_output.put_line ( '----------------------|-----------|-----------|-----------|-----------|-----------|-----------|');
	dbms_output.put_line ( 'Inst->Inst class      |  CRbsy    |  CRbsy tm |  CRbsy %  |  CRcongest| CRcngst tm| CRcng %   |');
	dbms_output.put_line ( '----------------------|-----------|-----------|-----------|-----------|-----------|-----------|');
	for i in key_table.first .. key_table.last
         loop
	  ind :=  key_table (i);
	  if ( e_cr_block (ind) - b_cr_block(ind) >0) then
	  dbms_output.put_line ( rpad( e_instance(ind) ||'->'|| e_inst_id(ind)||' '||e_class (ind), 22 )  || '|' ||
				 lpad(to_char(e_cr_busy (ind) - b_cr_busy(ind)),11)  || '|' ||
				 lpad(to_char(e_cr_busy_time (ind) - b_cr_busy_time(ind)),11)  ||'|'||
				 lpad(to_char(case when e_cr_block_time (ind) - b_cr_block_time(ind)=0 then 0
						else trunc (100*(e_cr_busy_time (ind) - b_cr_busy_time(ind))/(e_cr_block_time (ind) - b_cr_block_time(ind)),2)
						end
					      ),11)   ||'|'||
				 lpad(to_char(e_cr_congested (ind) - b_cr_congested(ind)),11)  || '|' ||
				 lpad(to_char(e_cr_congested_time (ind) - b_cr_congested_time(ind)),11)  ||'|'||
				 lpad(to_char(case when e_cr_block_time (ind) - b_cr_block_time(ind)=0 then 0
						else trunc (100*(e_cr_congested_time (ind) - b_cr_congested_time(ind))/(e_cr_block_time (ind) - b_cr_block_time(ind)),2)
						end
					      ),11) || '|'  
                                );
	 end if;
	 end loop;
	dbms_output.put_line ( '----------------------|-----------|-----------|-----------|-----------|-----------|-----------|');
	dbms_output.put_line ( '----------------------------------------------------------------------------------------------|');
	dbms_output.put_line ( 'Inst->Inst class      | CURbsy    | CURbsy tm | CURbsy %  | CURcongest|CURcngst tm|CURcng %   |');
	dbms_output.put_line ( '----------------------|-----------|-----------|-----------|-----------|-----------|-----------|');
	for i in key_table.first .. key_table.last
         loop
	  ind :=  key_table (i);
	  if ( e_current_block (ind) - b_current_block(ind) >0) then
	  dbms_output.put_line ( rpad( e_instance(ind) ||'->'|| e_inst_id(ind)||' '||e_class (ind), 22 )  || '|' ||
				 lpad(to_char(e_current_busy (ind) - b_current_busy(ind)),11)  || '|' ||
				 lpad(to_char(e_current_busy_time (ind) - b_current_busy_time(ind)),11)  ||'|'||
				 lpad(to_char(case when e_current_block_time (ind) - b_current_block_time(ind)=0 then 0
						else trunc (100*(e_current_busy_time (ind) - b_current_busy_time(ind))/(e_current_block_time (ind) - b_current_block_time(ind)),2)
						end
					      ),11)   ||'|'||
				 lpad(to_char(e_current_congested (ind) - b_current_congested(ind)),11)  || '|' ||
				 lpad(to_char(e_current_congested_time (ind) - b_current_congested_time(ind)),11)  ||'|'||
				 lpad(to_char(case when e_current_block_time (ind) - b_current_block_time(ind)=0 then 0
						else trunc (100*(e_current_congested_time (ind) - b_current_congested_time(ind))/(e_current_block_time (ind) - b_current_block_time(ind)),2)
						end
					      ),11) || '|'  
                                );
	 end if;
	 end loop;
	dbms_output.put_line ( '----------------------------------------------------------------------------------------------|');
end;
/
set verify on 


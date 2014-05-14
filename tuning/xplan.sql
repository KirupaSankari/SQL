set lines 130
set head off   
alter session set cursor_sharing=EXACT;
select plan_table_output from table(dbms_xplan.display('PLAN_TABLE',null,'ALL'));


set long 1000000
set longchunksize 1000000
set linesize 100
set pages 100
accept sql_tune_task_id prompt 'Sql ID: '
set serverout on

DECLARE
  l_sql_tune_task_id VARCHAR2(30);
BEGIN
  l_sql_tune_task_id := DBMS_SQLTUNE.CREATE_TUNING_TASK(
                           sql_id => '&sql_tune_task_id',
                           plan_hash_value=>NULL,
                           SCOPE => DBMS_SQLTUNE.scope_comprehensive,
                           time_limit => 600,
                           task_name => 'sql_tuning_task_&sql_tune_task_id',
                           description => 'to tune query sql id &sql_tune_task_id');
END;
/

exec dbms_sqltune.Execute_tuning_task (task_name => 'sql_tuning_task_&sql_tune_task_id');

select dbms_sqltune.report_tuning_task('sql_tuning_task_&sql_tune_task_id') from dual;

--execute dbms_sqltune.drop_tuning_task(task_name=>'sql_tuning_task_&sql_tune_task_id'); 



DECLARE
TYPE t_hash_values IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
list_hash_values t_hash_values;
v_hash_value NUMBER := NULL;
v_kcu001p NUMBER := NULL;
v_kcu002p NUMBER := NULL;
v_kcu003p NUMBER := NULL;
v_kcu004p NUMBER := NULL;
v_kcu005p NUMBER := NULL;
v_kcu006p NUMBER := NULL;
v_kcu007p NUMBER := NULL;
v_kcu008p NUMBER := NULL;
v_kcu009p NUMBER := NULL;
v_kcu010p NUMBER := NULL;
v_kcu011p NUMBER := NULL;
v_kcu012p NUMBER := NULL;
v_kcu013p NUMBER := NULL;
v_kcu014p NUMBER := NULL;
v_kcu015p NUMBER := NULL;
v_kcu016p NUMBER := NULL;
v_kcu017p NUMBER := NULL;
v_kcu018p NUMBER := NULL;
v_kcu019p NUMBER := NULL;
v_kcu020p NUMBER := NULL;
v_kcu021p NUMBER := NULL;
v_kcu022p NUMBER := NULL;

CURSOR c_hash
IS
select distinct sql_hash_value from v$session@kcu001p where username in ('ARBORBP1','TELSTRA_CUSTOM') and status='ACTIVE' and last_call_et > 300 union all
select distinct sql_hash_value from v$session@kcu002p where username in ('ARBORBP1','TELSTRA_CUSTOM') and status='ACTIVE' and last_call_et > 300 union all
select distinct sql_hash_value from v$session@kcu003p where username in ('ARBORBP1','TELSTRA_CUSTOM') and status='ACTIVE' and last_call_et > 300 union all
select distinct sql_hash_value from v$session@kcu004p where username in ('ARBORBP1','TELSTRA_CUSTOM') and status='ACTIVE' and last_call_et > 300 union all
select distinct sql_hash_value from v$session@kcu005p where username in ('ARBORBP1','TELSTRA_CUSTOM') and status='ACTIVE' and last_call_et > 300 union all
select distinct sql_hash_value from v$session@kcu006p where username in ('ARBORBP1','TELSTRA_CUSTOM') and status='ACTIVE' and last_call_et > 300 union all
select distinct sql_hash_value from v$session@kcu007p where username in ('ARBORBP1','TELSTRA_CUSTOM') and status='ACTIVE' and last_call_et > 300 union all
select distinct sql_hash_value from v$session@kcu008p where username in ('ARBORBP1','TELSTRA_CUSTOM') and status='ACTIVE' and last_call_et > 300 union all
select distinct sql_hash_value from v$session@kcu009p where username in ('ARBORBP1','TELSTRA_CUSTOM') and status='ACTIVE' and last_call_et > 300 union all
select distinct sql_hash_value from v$session@kcu010p where username in ('ARBORBP1','TELSTRA_CUSTOM') and status='ACTIVE' and last_call_et > 300 union all
select distinct sql_hash_value from v$session@kcu011p where username in ('ARBORBP1','TELSTRA_CUSTOM') and status='ACTIVE' and last_call_et > 300 union all
select distinct sql_hash_value from v$session@kcu012p where username in ('ARBORBP1','TELSTRA_CUSTOM') and status='ACTIVE' and last_call_et > 300 union all
select distinct sql_hash_value from v$session@kcu013p where username in ('ARBORBP1','TELSTRA_CUSTOM') and status='ACTIVE' and last_call_et > 300 union all
select distinct sql_hash_value from v$session@kcu014p where username in ('ARBORBP1','TELSTRA_CUSTOM') and status='ACTIVE' and last_call_et > 300 union all
select distinct sql_hash_value from v$session@kcu015p where username in ('ARBORBP1','TELSTRA_CUSTOM') and status='ACTIVE' and last_call_et > 300 union all
select distinct sql_hash_value from v$session@kcu016p where username in ('ARBORBP1','TELSTRA_CUSTOM') and status='ACTIVE' and last_call_et > 300 union all
select distinct sql_hash_value from v$session@kcu017p where username in ('ARBORBP1','TELSTRA_CUSTOM') and status='ACTIVE' and last_call_et > 300 union all
select distinct sql_hash_value from v$session@kcu018p where username in ('ARBORBP1','TELSTRA_CUSTOM') and status='ACTIVE' and last_call_et > 300 union all
select distinct sql_hash_value from v$session@kcu019p where username in ('ARBORBP1','TELSTRA_CUSTOM') and status='ACTIVE' and last_call_et > 300 union all
select distinct sql_hash_value from v$session@kcu020p where username in ('ARBORBP1','TELSTRA_CUSTOM') and status='ACTIVE' and last_call_et > 300 union all
select distinct sql_hash_value from v$session@kcu021p where username in ('ARBORBP1','TELSTRA_CUSTOM') and status='ACTIVE' and last_call_et > 300 union all
select distinct sql_hash_value from v$session@kcu022p where username in ('ARBORBP1','TELSTRA_CUSTOM') and status='ACTIVE' and last_call_et > 300;


CURSOR c_plan (p_which_hash_value IN NUMBER)
IS
SELECT p_which_hash_value, 
(SELECT SUM(DBMS_UTILITY.GET_HASH_VALUE(OPERATION||OPTIONS||ID||PARENT_ID, 1,POWER(2,16)-1)) PLAN_ID FROM V$SQL_PLAN@KCU001P WHERE HASH_VALUE = p_which_hash_value GROUP BY HASH_VALUE) "KCU001P",
(SELECT SUM(DBMS_UTILITY.GET_HASH_VALUE(OPERATION||OPTIONS||ID||PARENT_ID, 1,POWER(2,16)-1)) PLAN_ID FROM V$SQL_PLAN@KCU002P WHERE HASH_VALUE = p_which_hash_value GROUP BY HASH_VALUE) "KCU002P",
(SELECT SUM(DBMS_UTILITY.GET_HASH_VALUE(OPERATION||OPTIONS||ID||PARENT_ID, 1,POWER(2,16)-1)) PLAN_ID FROM V$SQL_PLAN@KCU003P WHERE HASH_VALUE = p_which_hash_value GROUP BY HASH_VALUE) "KCU003P",
(SELECT SUM(DBMS_UTILITY.GET_HASH_VALUE(OPERATION||OPTIONS||ID||PARENT_ID, 1,POWER(2,16)-1)) PLAN_ID FROM V$SQL_PLAN@KCU004P WHERE HASH_VALUE = p_which_hash_value GROUP BY HASH_VALUE) "KCU004P",
(SELECT SUM(DBMS_UTILITY.GET_HASH_VALUE(OPERATION||OPTIONS||ID||PARENT_ID, 1,POWER(2,16)-1)) PLAN_ID FROM V$SQL_PLAN@KCU005P WHERE HASH_VALUE = p_which_hash_value GROUP BY HASH_VALUE) "KCU005P",
(SELECT SUM(DBMS_UTILITY.GET_HASH_VALUE(OPERATION||OPTIONS||ID||PARENT_ID, 1,POWER(2,16)-1)) PLAN_ID FROM V$SQL_PLAN@KCU006P WHERE HASH_VALUE = p_which_hash_value GROUP BY HASH_VALUE) "KCU006P",
(SELECT SUM(DBMS_UTILITY.GET_HASH_VALUE(OPERATION||OPTIONS||ID||PARENT_ID, 1,POWER(2,16)-1)) PLAN_ID FROM V$SQL_PLAN@KCU007P WHERE HASH_VALUE = p_which_hash_value GROUP BY HASH_VALUE) "KCU007P",
(SELECT SUM(DBMS_UTILITY.GET_HASH_VALUE(OPERATION||OPTIONS||ID||PARENT_ID, 1,POWER(2,16)-1)) PLAN_ID FROM V$SQL_PLAN@KCU008P WHERE HASH_VALUE = p_which_hash_value GROUP BY HASH_VALUE) "KCU008P",
(SELECT SUM(DBMS_UTILITY.GET_HASH_VALUE(OPERATION||OPTIONS||ID||PARENT_ID, 1,POWER(2,16)-1)) PLAN_ID FROM V$SQL_PLAN@KCU009P WHERE HASH_VALUE = p_which_hash_value GROUP BY HASH_VALUE) "KCU009P",
(SELECT SUM(DBMS_UTILITY.GET_HASH_VALUE(OPERATION||OPTIONS||ID||PARENT_ID, 1,POWER(2,16)-1)) PLAN_ID FROM V$SQL_PLAN@KCU010P WHERE HASH_VALUE = p_which_hash_value GROUP BY HASH_VALUE) "KCU010P",
(SELECT SUM(DBMS_UTILITY.GET_HASH_VALUE(OPERATION||OPTIONS||ID||PARENT_ID, 1,POWER(2,16)-1)) PLAN_ID FROM V$SQL_PLAN@KCU011P WHERE HASH_VALUE = p_which_hash_value GROUP BY HASH_VALUE) "KCU011P",
(SELECT SUM(DBMS_UTILITY.GET_HASH_VALUE(OPERATION||OPTIONS||ID||PARENT_ID, 1,POWER(2,16)-1)) PLAN_ID FROM V$SQL_PLAN@KCU012P WHERE HASH_VALUE = p_which_hash_value GROUP BY HASH_VALUE) "KCU012P",
(SELECT SUM(DBMS_UTILITY.GET_HASH_VALUE(OPERATION||OPTIONS||ID||PARENT_ID, 1,POWER(2,16)-1)) PLAN_ID FROM V$SQL_PLAN@KCU013P WHERE HASH_VALUE = p_which_hash_value GROUP BY HASH_VALUE) "KCU013P",
(SELECT SUM(DBMS_UTILITY.GET_HASH_VALUE(OPERATION||OPTIONS||ID||PARENT_ID, 1,POWER(2,16)-1)) PLAN_ID FROM V$SQL_PLAN@KCU014P WHERE HASH_VALUE = p_which_hash_value GROUP BY HASH_VALUE) "KCU014P",
(SELECT SUM(DBMS_UTILITY.GET_HASH_VALUE(OPERATION||OPTIONS||ID||PARENT_ID, 1,POWER(2,16)-1)) PLAN_ID FROM V$SQL_PLAN@KCU015P WHERE HASH_VALUE = p_which_hash_value GROUP BY HASH_VALUE) "KCU015P",
(SELECT SUM(DBMS_UTILITY.GET_HASH_VALUE(OPERATION||OPTIONS||ID||PARENT_ID, 1,POWER(2,16)-1)) PLAN_ID FROM V$SQL_PLAN@KCU016P WHERE HASH_VALUE = p_which_hash_value GROUP BY HASH_VALUE) "KCU016P",
(SELECT SUM(DBMS_UTILITY.GET_HASH_VALUE(OPERATION||OPTIONS||ID||PARENT_ID, 1,POWER(2,16)-1)) PLAN_ID FROM V$SQL_PLAN@KCU017P WHERE HASH_VALUE = p_which_hash_value GROUP BY HASH_VALUE) "KCU017P",
(SELECT SUM(DBMS_UTILITY.GET_HASH_VALUE(OPERATION||OPTIONS||ID||PARENT_ID, 1,POWER(2,16)-1)) PLAN_ID FROM V$SQL_PLAN@KCU018P WHERE HASH_VALUE = p_which_hash_value GROUP BY HASH_VALUE) "KCU018P",
(SELECT SUM(DBMS_UTILITY.GET_HASH_VALUE(OPERATION||OPTIONS||ID||PARENT_ID, 1,POWER(2,16)-1)) PLAN_ID FROM V$SQL_PLAN@KCU019P WHERE HASH_VALUE = p_which_hash_value GROUP BY HASH_VALUE) "KCU019P",
(SELECT SUM(DBMS_UTILITY.GET_HASH_VALUE(OPERATION||OPTIONS||ID||PARENT_ID, 1,POWER(2,16)-1)) PLAN_ID FROM V$SQL_PLAN@KCU020P WHERE HASH_VALUE = p_which_hash_value GROUP BY HASH_VALUE) "KCU020P",
(SELECT SUM(DBMS_UTILITY.GET_HASH_VALUE(OPERATION||OPTIONS||ID||PARENT_ID, 1,POWER(2,16)-1)) PLAN_ID FROM V$SQL_PLAN@KCU021P WHERE HASH_VALUE = p_which_hash_value GROUP BY HASH_VALUE) "KCU021P",
(select SUM(DBMS_UTILITY.GET_HASH_VALUE(OPERATION||OPTIONS||id||PARENT_ID, 1,power(2,16)-1)) plan_id from V$SQL_PLAN@KCU022P where HASH_VALUE = p_which_hash_value group by HASH_VALUE) "KCU022P" 
from dual;

BEGIN

-- create header
DBMS_OUTPUT.PUT_LINE('<html> <head> </head> <body>'
		|| ' <table> <tr>'
		|| ' <th> KCU001P </th> '
		|| ' <th> KCU002P </th> '
		|| ' <th> KCU003P </th> '
		|| ' <th> KCU004P </th> '
		|| ' <th> KCU005P </th> '
		|| ' <th> KCU006P </th> '
		|| ' <th> KCU007P </th> '
		|| ' <th> KCU008P </th> '
		|| ' <th> KCU009P </th> '
		|| ' <th> KCU010P </th> '
		|| ' <th> KCU011P </th> '
		|| ' <th> KCU012P </th> '
		|| ' <th> KCU013P </th> '
		|| ' <th> KCU014P </th> '
		|| ' <th> KCU015P </th> '
		|| ' <th> KCU016P </th> '
		|| ' <th> KCU017P </th> '
		|| ' <th> KCU018P </th> '
		|| ' <th> KCU019P </th> '
		|| ' <th> KCU020P </th> '
		|| ' <th> KCU021P </th> '
		|| ' <th> KCU022P </th> '
		|| ' </tr> '
		); 
-- fetch the candidate hash values from all customers
OPEN c_hash;

LOOP
	FETCH c_hash
	BULK COLLECT 
	INTO list_hash_values;
	
		FORALL hv IN list_hash_values.FIRST .. list_hash_values.LAST
			OPEN c_plan(list_hash_values(hv));
			
			FETCH c_plan 
			INTO v_hash_value, 
	v_kcu001p, v_kcu002p,v_kcu003p,v_kcu004p,v_kcu005p,v_kcu006p,v_kcu007p,v_kcu008p,v_kcu009p,v_kcu010p,v_kcu011p,
	v_kcu012p, v_kcu013p,v_kcu014p,v_kcu015p,v_kcu016p,v_kcu017p,v_kcu018p,v_kcu019p,v_kcu020p,v_kcu021p,v_kcu022p;
	
	
			DBMS_OUTPUT.PUT_LINE(  '<tr>' 
						|| '<td>'	|| v_hash_value || '</td>'
						|| '<td>' 	|| v_kcu001p || '</td>'
						|| '<td>' 	|| v_kcu002p || '</td>'
						|| '<td>' 	|| v_kcu003p || '</td>'
						|| '<td>' 	|| v_kcu004p || '</td>'
						|| '<td>' 	|| v_kcu005p || '</td>'
						|| '<td>' 	|| v_kcu006p || '</td>'
						|| '<td>' 	|| v_kcu007p || '</td>'
						|| '<td>' 	|| v_kcu008p || '</td>'
						|| '<td>' 	|| v_kcu009p || '</td>'
						|| '<td>' 	|| v_kcu010p || '</td>'
						|| '<td>' 	|| v_kcu011p || '</td>'
						|| '<td>' 	|| v_kcu012p || '</td>'
						|| '<td>' 	|| v_kcu013p || '</td>'
						|| '<td>' 	|| v_kcu014p || '</td>'
						|| '<td>' 	|| v_kcu015p || '</td>'
						|| '<td>' 	|| v_kcu016p || '</td>'
						|| '<td>' 	|| v_kcu017p || '</td>'
						|| '<td>' 	|| v_kcu018p || '</td>'
						|| '<td>' 	|| v_kcu019p || '</td>'
						|| '<td>' 	|| v_kcu020p || '</td>'
						|| '<td>' 	|| v_kcu021p || '</td>'
						|| '<td>' 	|| v_kcu022p || '</td>'
						|| '</tr>'
						);
			EXIT WHEN c_plan%NOTFOUND;
	
			CLOSE c_plan;
END LOOP;

CLOSE c_hash; 

-- footer 
DBMS_OUTPUT.PUT_LINE( ' </table> </body> </html> ');

END;
/




